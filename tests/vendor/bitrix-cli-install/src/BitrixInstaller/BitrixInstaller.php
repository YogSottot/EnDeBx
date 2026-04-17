<?php declare(strict_types=1);

namespace Maximaster\BitrixCliInstall\BitrixInstaller;

use Exception;
use Guzzle\Parser\Cookie\CookieParser;
use Guzzle\Parser\Message\MessageParser;
use GuzzleHttp\Client;
use GuzzleHttp\Cookie\CookieJar;
use GuzzleHttp\RequestOptions;
use Symfony\Component\DomCrawler\Crawler;
use Symfony\Component\EventDispatcher\EventDispatcher;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\BitrixDistributiveReady;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\InstallationConfigurationPrepared;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\InstallationFailed;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\InstallationFinished;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\InstallationStepFinished;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\InstallationStepPayloadPrepared;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\InstallationStepPrepared;
use Maximaster\BitrixCliInstall\BitrixInstaller\Event\WizardClientPrepared;
use Maximaster\BitrixCliInstall\BitrixInstaller\Exception\InstallationStepException;
use Maximaster\BitrixCliInstall\BitrixInstaller\WizardConfig\Parser\WizardConfigBuilder;
use Maximaster\BitrixCliInstall\BitrixInstaller\WizardConfig\WizardConfigFactory;
use Maximaster\BitrixCliInstall\BitrixInstaller\WizardConfig\WizardConfigStep;
use Maximaster\BitrixCliInstall\ResourceProcessor\ResourceProcessorInterface;
use Maximaster\CliEnt\CliEntHandler;
use Maximaster\CliEnt\GlobalsParser;

class BitrixInstaller
{
    /** @var WizardConfigFactory */
    private $wizardConfigFactory;

    /** @var ResourceProcessorInterface */
    private $distributivePackageProcessor;

    /** @var EventDispatcher|null */
    private $eventDispatcher;

    /** @var string|null */
    private $debugDir;

    public function __construct(
        WizardConfigFactory $wizardConfigFactory,
        ResourceProcessorInterface $distributivePackageProcessor,
        ?EventDispatcher $eventDispatcher = null
    ) {
        $this->wizardConfigFactory = $wizardConfigFactory;
        $this->distributivePackageProcessor = $distributivePackageProcessor;
        $this->eventDispatcher = $eventDispatcher;
    }

    /**
     * @param BitrixInstallConfig $installConfig
     *
     * @throws Exception
     */
    public function install(BitrixInstallConfig $installConfig): void
    {
        $documentRoot = $installConfig->documentRoot();
        $this->debugDir = $this->prepareDebugDirectory();
        $wizardConfig = $this->wizardConfigFactory->createFromPath(
            $installConfig->wizardConfig(),
            [getcwd(), $documentRoot->getPathname()]
        );

        $this->eventDispatcher && $this->eventDispatcher->dispatch(
            new InstallationConfigurationPrepared($installConfig, $wizardConfig)
        );

        if (!$this->shouldSkipDistributivePreparation()) {
            if (!$this->distributivePackageProcessor->supports($installConfig->distributivePackageUri())) {
                throw new Exception('Формат ссылки на дистрибутив не поддерживается');
            }

            $this->distributivePackageProcessor->process(
                $installConfig->distributivePackageUri(),
                $installConfig->documentRoot()->getPathname()
            );
        }

        $this->eventDispatcher && $this->eventDispatcher->dispatch(new BitrixDistributiveReady($installConfig));

        $hoardedPayload = [];
        $client = $this->client($documentRoot->getPathname());
        $this->authenticateClient($client);

        $this->eventDispatcher && $this->eventDispatcher->dispatch(
            new WizardClientPrepared($installConfig, $wizardConfig, $client)
        );

        /** @var WizardConfigStep|null $previousStep */
        $previousStep = null;
        foreach ($wizardConfig->steps() as $idx => $step) {
            $this->eventDispatcher && $this->eventDispatcher->dispatch(
                new InstallationStepPrepared($installConfig, $wizardConfig, $step)
            );

            unset($hoardedPayload['PreviousStepID'], $hoardedPayload['NextStepID']);

            $defaultPayload = [WizardConfigBuilder::ID_KEY => $step->id()];

            if ($previousStep) {
                $defaultPayload['PreviousStepID'] = $previousStep->id();
            }

            $nextStep = $wizardConfig->step($idx + 1);
            if ($nextStep) {
                $defaultPayload['NextStepID'] = $nextStep->id();
            }

            $hoardedPayload = $step->payload() + $hoardedPayload + $defaultPayload;

            $this->eventDispatcher && $this->eventDispatcher->dispatch(
                new InstallationStepPayloadPrepared($installConfig, $wizardConfig, $step, $hoardedPayload)
            );

            try {
                $this->runStep($client, $hoardedPayload, $installConfig->repeat(), 1, $idx + 1);
            } catch (Exception $e) {
                $this->eventDispatcher && $this->eventDispatcher->dispatch(
                    new InstallationFailed($installConfig, $wizardConfig, $step, $e)
                );
                return;
            }

            $this->eventDispatcher && $this->eventDispatcher->dispatch(
                new InstallationStepFinished($installConfig, $wizardConfig, $step)
            );

            $previousStep = $step;
        }

        $this->eventDispatcher && $this->eventDispatcher->dispatch(
            new InstallationFinished($installConfig, $wizardConfig)
        );
    }

    /**
     * @param Client $client
     * @param array $payload
     * @param int $repeat
     * @param int $attempt
     * @param int $stepNumber
     *
     * @throws InstallationStepException
     */
    private function runStep(
        Client $client,
        array $payload,
        int $repeat = 5,
        int $attempt = 1,
        int $stepNumber = 1
    ): void
    {
        $debugPrefix = $this->debugFilePrefix($stepNumber, $payload, $attempt);
        $this->writeDebugRequest($debugPrefix, $payload);

        $response = $client->post('/index.php', [ RequestOptions::FORM_PARAMS => $payload ]);

        $body = $response->getBody()->getContents();
        $responseCode = $response->getStatusCode();
        $this->writeDebugResponse($debugPrefix, $responseCode, $response->getHeaders(), $body);

        if ($responseCode !== 200) {
            if ($repeat) {
                $this->runStep($client, $payload, $repeat - 1, $attempt + 1, $stepNumber);
                return;
            }

            $exception = new InstallationStepException(
                sprintf('Неожиданный код ответа: %d', $responseCode),
                $payload,
                $body
            );
            $this->writeDebugException($debugPrefix, $exception);
            throw $exception;
        }

        $body = $this->submitAuthFormIfPresent($client, $body, $debugPrefix);

        try {
            $this->validateResponse($payload, $body);
        } catch (InstallationStepException $exception) {
            $this->writeDebugException($debugPrefix, $exception);
            throw $exception;
        }
    }

    /**
     * @param array $payload
     * @param string $response
     *
     * @throws InstallationStepException
     */
    private function validateResponse(array $payload, string $response): void
    {
        try {
            if (strpos($response, '<!DOCTYPE html>') === 0) {
                $this->validateHtmlResponse($payload, $response);
            } else {
                $this->validateAjaxResponse($response);
            }
        } catch (Exception $e) {
            throw new InstallationStepException(
                sprintf('На шаге "%s" возникла проблема: "%s"', $payload[WizardConfigBuilder::ID_KEY], $e->getMessage()),
                $payload,
                $response,
                $e
            );
        }
    }

    /**
     * @param array $payload
     * @param string $response
     *
     * @throws Exception
     */
    private function validateHtmlResponse(array $payload, string $response): void
    {
        $crawler = new Crawler($response);

        $formCrawler = $crawler->filter('#__wizard_form');
        if ($formCrawler->count() === 0) {
            throw new Exception('Не удалось найти форму установки');
        }

        foreach ($formCrawler->filter('.inst-note-block-red') as $errorBlock) {
            // Такой блок есть на страницах с AJAX'ом и показывается он когда возникает ошибка на AJAX'е
            if ($errorBlock->parentNode->attributes->getNamedItem('id')->nodeValue === 'error_notice') {
                continue;
            }

            $errorCrawler = (new Crawler($errorBlock))->filter('.inst-note-block-text');
            if ($errorCrawler->count() && trim($errorCrawler->text())) {
                throw new Exception(sprintf('%s (ошибка на форме установки)', $errorCrawler->text()));
            }
        }

        $stepNode = $formCrawler->filter('input[name="CurrentStepID"]')->getNode(0);
        if (!$stepNode) {
            throw new Exception('Не удалось найти на форме данные о имени текущего шага');
        }

        $actualStepId = $stepNode->getAttribute('value');

        if (!empty($payload['NextStepID']) && $payload['NextStepID'] !== $actualStepId) {
            throw new Exception(sprintf('В ответе ожидался шаг %s, на форме указан %s', $payload['NextStepID'], $actualStepId));
        }
    }

    /**
     * @param string $response
     *
     * @throws Exception
     */
    private function validateAjaxResponse(string $response): void
    {
        if ($response && strpos($response, 'window.ajaxForm.Post') === false) {
            throw new Exception(sprintf('Неожиданный AJAX-ответ: %s', $response));
        }
    }

    /**
     * Было бы хорошо передавать клиент в конструкторе, но его построение зависит от documentRoot, который нам известен
     * только на момент конкретного вызова
     *
     * @param string $documentRoot
     *
     * @return Client
     *
     * @throws Exception
     */
    private function client(string $documentRoot): Client
    {
        $baseUri = getenv('BITRIX_INSTALL_BASE_URI');
        if ($baseUri !== false && $baseUri !== '') {
            return new Client([
                'base_uri' => rtrim($baseUri, '/') . '/',
                'cookie' => new CookieJar(),
                'http_errors' => false,
                'verify' => filter_var(getenv('BITRIX_INSTALL_VERIFY_TLS') ?: '1', FILTER_VALIDATE_BOOLEAN),
            ]);
        }

        return new Client([
            'base_uri' => 'http://localhost',
            'handler' => new CliEntHandler(
                new GlobalsParser(new CookieParser()),
                new MessageParser(),
                $documentRoot,
                function (array &$globals) use ($documentRoot) {
                    $globals['_SERVER'] += [
                        'DOCUMENT_ROOT' =>  $documentRoot,
                    ];
                }
            ),
            'cookie' => new CookieJar(),
        ]);
    }

    /**
     * @throws Exception
     */
    private function prepareDebugDirectory(): ?string
    {
        $debugDir = getenv('BITRIX_INSTALL_DEBUG_DIR');
        if ($debugDir === false || $debugDir === '') {
            return null;
        }

        if (!is_dir($debugDir) && !mkdir($debugDir, 0777, true) && !is_dir($debugDir)) {
            throw new Exception(sprintf('Не удалось создать каталог отладки: %s', $debugDir));
        }

        return realpath($debugDir) ?: $debugDir;
    }

    private function debugFilePrefix(int $stepNumber, array $payload, int $attempt): ?string
    {
        if ($this->debugDir === null) {
            return null;
        }

        $parts = [
            sprintf('%03d', $stepNumber),
            $this->sanitizeDebugValue((string) ($payload[WizardConfigBuilder::ID_KEY] ?? 'unknown')),
        ];

        foreach (['__wiz_nextStep', '__wiz_nextStepStage'] as $key) {
            if (!empty($payload[$key])) {
                $parts[] = $this->sanitizeDebugValue((string) $payload[$key]);
            }
        }

        $parts[] = sprintf('attempt-%02d', $attempt);

        return $this->debugDir . DIRECTORY_SEPARATOR . implode('__', $parts);
    }

    private function writeDebugRequest(?string $debugPrefix, array $payload): void
    {
        if ($debugPrefix === null) {
            return;
        }

        $lines = [];
        foreach ($payload as $name => $value) {
            $lines[] = sprintf('%s=%s', $name, (string) $value);
        }

        file_put_contents($debugPrefix . '.request.txt', implode(PHP_EOL, $lines) . PHP_EOL);
    }

    private function writeDebugResponse(?string $debugPrefix, int $responseCode, array $headers, string $body): void
    {
        if ($debugPrefix === null) {
            return;
        }

        $meta = ['status_code=' . $responseCode];
        foreach ($headers as $name => $values) {
            $meta[] = sprintf('%s: %s', $name, implode(', ', $values));
        }

        file_put_contents($debugPrefix . '.response.meta.txt', implode(PHP_EOL, $meta) . PHP_EOL);
        file_put_contents($debugPrefix . '.response.body.html', $body);
    }

    private function writeDebugException(?string $debugPrefix, Exception $exception): void
    {
        if ($debugPrefix === null) {
            return;
        }

        $lines = [
            'message=' . $exception->getMessage(),
            'class=' . get_class($exception),
        ];

        if ($exception instanceof InstallationStepException) {
            $lines[] = 'payload=' . http_build_query($exception->payload());
        }

        file_put_contents($debugPrefix . '.exception.txt', implode(PHP_EOL, $lines) . PHP_EOL);
    }

    private function sanitizeDebugValue(string $value): string
    {
        $sanitized = preg_replace('/[^a-zA-Z0-9._-]+/', '-', $value);
        return trim((string) $sanitized, '-');
    }

    /**
     * @throws Exception
     */
    private function submitAuthFormIfPresent(Client $client, string $response, ?string $debugPrefix): string
    {
        $login = getenv('BITRIX_INSTALL_AUTH_LOGIN');
        $password = getenv('BITRIX_INSTALL_AUTH_PASSWORD');

        if ($login === false || $login === '' || $password === false || $password === '') {
            return $response;
        }

        $crawler = new Crawler($response);
        $authForm = $crawler->filter('form[name="form_auth"]');
        if ($authForm->count() === 0) {
            return $response;
        }

        $payload = [];
        foreach ($authForm->filter('input[name]') as $input) {
            $name = $input->getAttribute('name');
            $type = strtolower($input->getAttribute('type'));

            if ($type === 'text' || $type === 'password') {
                continue;
            }

            if ($type === 'checkbox' && !$input->hasAttribute('checked')) {
                continue;
            }

            $payload[$name] = $input->getAttribute('value');
        }

        $payload['USER_LOGIN'] = $login;
        $payload['USER_PASSWORD'] = $password;
        $payload['USER_REMEMBER'] = 'Y';
        $payload['Login'] = $payload['Login'] ?? 'Y';

        $action = $authForm->attr('action') ?: '/?login=yes';
        $authResponse = $client->post($action, [RequestOptions::FORM_PARAMS => $payload]);
        $authBody = $authResponse->getBody()->getContents();

        if ($debugPrefix !== null) {
            $this->writeDebugResponse(
                $debugPrefix . '.auth',
                $authResponse->getStatusCode(),
                $authResponse->getHeaders(),
                $authBody
            );
        }

        if ($authResponse->getStatusCode() !== 200) {
            throw new Exception(sprintf(
                'Не удалось авторизоваться, код ответа: %d',
                $authResponse->getStatusCode()
            ));
        }

        if (strpos($authBody, 'name="form_auth"') !== false) {
            throw new Exception('Не удалось авторизоваться перед продолжением установки');
        }

        return $authBody;
    }

    private function shouldSkipDistributivePreparation(): bool
    {
        return filter_var(
            getenv('BITRIX_INSTALL_SKIP_DISTRIBUTIVE_PREPARATION') ?: '0',
            FILTER_VALIDATE_BOOLEAN
        );
    }

    /**
     * @throws Exception
     */
    private function authenticateClient(Client $client): void
    {
        $login = getenv('BITRIX_INSTALL_AUTH_LOGIN');
        $password = getenv('BITRIX_INSTALL_AUTH_PASSWORD');

        if ($login === false || $login === '' || $password === false || $password === '') {
            return;
        }

        $response = $client->get('/?login=yes');
        $body = $response->getBody()->getContents();
        $crawler = new Crawler($body);
        $authForm = $crawler->filter('form[name="form_auth"]');
        if ($authForm->count() === 0) {
            return;
        }

        $payload = [];
        foreach ($authForm->filter('input[name]') as $input) {
            $name = $input->getAttribute('name');
            $type = strtolower($input->getAttribute('type'));

            if ($type === 'text' || $type === 'password') {
                continue;
            }

            if ($type === 'checkbox' && !$input->hasAttribute('checked')) {
                continue;
            }

            $payload[$name] = $input->getAttribute('value');
        }

        $payload['USER_LOGIN'] = $login;
        $payload['USER_PASSWORD'] = $password;
        $payload['USER_REMEMBER'] = 'Y';
        $payload['Login'] = $payload['Login'] ?? 'Y';

        $action = $authForm->attr('action') ?: '/?login=yes';
        $response = $client->post($action, [RequestOptions::FORM_PARAMS => $payload]);
        $body = $response->getBody()->getContents();

        if ($response->getStatusCode() !== 200) {
            throw new Exception(sprintf('Не удалось авторизоваться, код ответа: %d', $response->getStatusCode()));
        }

        if (strpos($body, 'name="form_auth"') !== false) {
            throw new Exception('Не удалось авторизоваться перед продолжением установки');
        }
    }
}
