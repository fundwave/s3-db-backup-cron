#!/bin/bash

# Clear existing crontab
true > crontab.txt

# Support for backward compatibility with HOUR_OF_DAY (uses original script.sh)
if [ -n "${HOUR_OF_DAY}" ]; then
  echo "0 ${HOUR_OF_DAY} * * 1-6 /opt/backup/script.sh /opt/backup > /dev/stdout" >> crontab.txt
  echo "Configured legacy backup schedule at hour ${HOUR_OF_DAY}"
fi

# Support for full backup cron schedule
if [ -n "${FULL_BACKUP_CRON}" ]; then
  echo "${FULL_BACKUP_CRON} /opt/backup/script-full.sh /opt/backup > /dev/stdout" >> crontab.txt
  echo "Configured full backup schedule: ${FULL_BACKUP_CRON}"
fi

# Support for incremental backup cron schedule
if [ -n "${INCREMENTAL_BACKUP_CRON}" ]; then
  echo "${INCREMENTAL_BACKUP_CRON} /opt/backup/script-incremental.sh /opt/backup > /dev/stdout" >> crontab.txt
  echo "Configured incremental backup schedule: ${INCREMENTAL_BACKUP_CRON}"
fi

# If no cron schedule is configured, use default
if [ ! -s crontab.txt ]; then
  echo "0 23 * * 1-6 /opt/backup/script.sh /opt/backup > /dev/stdout" >> crontab.txt
  echo "No cron schedule configured. Using default: daily at 23:00 (Mon-Sat) with script.sh"
fi

cat crontab.txt
/usr/bin/crontab crontab.txt

/usr/sbin/crond -f -l 8