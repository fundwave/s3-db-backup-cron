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
      # Specify backup hour of day, defaults to 23
      - HOUR_OF_DAY=      
      # Specify AWS credentials or skip if using AWS IAM roles 
      - AWS_ACCESS_KEY_ID=
      - AWS_SECRET_ACCESS_KEY=   
      # Specify only if you want the backups stored in a specific folder
      - S3_PREFIX=
      # Specify only if you want the backup objects tagged. Value may be left empty
      - S3_TAG_KEY=
      - S3_TAG_VALUE=
      # Specify only when backups need to be disabled
      - BACKUPS_DISABLED=TRUE
    restart: always
```

### NOTE

Backups are always enabled by default. If you wish to disable backups, you can set the BACKUPS_DISABLED environment variable as `TRUE` or `true`.

Setting `S3_TAG_KEY` tags every uploaded backup object (MySQL and MongoDB) with `S3_TAG_KEY=S3_TAG_VALUE`. `S3_TAG_VALUE` is optional, the tag is then created with an empty value. Tagging requires the `s3:PutObjectTagging` permission on the bucket.

Using [Dockerhub](https://hub.docker.com/r/fundwave/s3-db-backup-cron)? Replace `build:` with `image: fundwave/s3-db-backup-cron:latest`
