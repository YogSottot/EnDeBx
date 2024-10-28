## Example Playbook

    - hosts: all
      tasks:
        - import_role:
            name: mmcnl.rkhunter
          vars:
            rkhunter_notification_email: admin@example.com
            rkhunter_additional_config:
              - ALLOWHIDDENDIR=/etc/.git
              - ALLOWHIDDENFILE=/etc/.gitignore
              - ALLOWHIDDENFILE=/etc/.etckeeper
              - ALLOWDEVFILE=/dev/shm/PostgreSQL.*

## License

MIT

