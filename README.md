How to run:
==========

1. Build the image

`docker build -t backups . --build-arg HOUR_OF_DAY=23`

2. Run the image

```
docker run -idt backups --env MYSQL_USERNAME=<> --env MYSQL_PASSWORD=<> --env SERVER=<> --env DB_NAME=<> --env BUCKET=<abc.bucket.com> --env AWS_ACCESS_KEY_ID=<> --env AWS_SECRET_ACCESS_KEY=<>
```

3. Connect to the network of your DB container (Only when DB is in another container)

`docker network connect <network_name> <backup_container>`

4. Verify backups manually

`docker exec -it <backup_container> bash script.sh`


How to run (docker-compose):
==========================

Add the below section to your docker compose:

```
  backups:
    build:
      context: ./backups
    depends_on:
      - <"db">
    networks:
      - <db>
    environment:
      - BUCKET_NAME=<abc.bucket.com>
      # Only when backing up MYSQL / MariaDB
      - MYSQL_USERNAME=
      - MYSQL_PASSWORD=
      - SERVER=
      - DB_NAME=
      # Only when backing up MongoDB
      - MONGODB_URI=
      - MONGO_DATABASES=
      # Specify backup hour of day, defaults to 23 (DEPRECATED: Use FULL_BACKUP_CRON instead)
      - HOUR_OF_DAY=      
      # Specify full backup cron schedule (supports both mysqldump and Percona full backups)
      - FULL_BACKUP_CRON=0 23 * * 0
      # Specify incremental backup cron schedule (Percona incremental backups only)
      - INCREMENTAL_BACKUP_CRON=0 2 * * 1-6
      # Specify AWS credentials or skip if using AWS IAM roles 
      - AWS_ACCESS_KEY_ID=
      - AWS_SECRET_ACCESS_KEY=   
      # Specify only if you want the backups stored in a specific folder
      - S3_PREFIX=
      # Specify only when backups need to be disabled
      - BACKUPS_DISABLED=TRUE
    restart: always
```

### Backup Types and Schedules

This container now supports two types of backup schedules for MySQL/MariaDB:

1. **Full Backups** (`FULL_BACKUP_CRON`): Performs both mysqldump and Percona XtraBackup full backups
   - Example: `FULL_BACKUP_CRON=0 23 * * 0` (weekly on Sunday at 23:00)
   
2. **Incremental Backups** (`INCREMENTAL_BACKUP_CRON`): Performs Percona XtraBackup incremental backups
   - Example: `INCREMENTAL_BACKUP_CRON=0 2 * * 1-6` (daily Mon-Sat at 02:00)

**Cron Schedule Format**: `minute hour day-of-month month day-of-week`

**Example Use Case**: 
- Full backups weekly on Sundays: `FULL_BACKUP_CRON=0 23 * * 0`
- Incremental backups daily Monday through Saturday: `INCREMENTAL_BACKUP_CRON=0 2 * * 1-6`

**Backward Compatibility**: The `HOUR_OF_DAY` environment variable is still supported for existing deployments, but using `FULL_BACKUP_CRON` and `INCREMENTAL_BACKUP_CRON` is recommended.

### NOTE

Backups are always enabled by default. If you wish to disable backups, you can set the BACKUPS_DISABLED environment variable as `TRUE` or `true`.

Using [Dockerhub](https://hub.docker.com/r/fundwave/s3-db-backup-cron)? Replace `build:` with `image: fundwave/s3-db-backup-cron:latest`
