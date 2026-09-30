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
      # Comma separated. Each replaces any database already in MONGODB_URI; its options are kept
      - MONGO_DATABASES=
      # Optional: limit a database in MONGO_DATABASES to one collection, with an optional query
      # Quote the whole entry for YAML, and write $ as $$ so compose does not interpolate it
      - 'MONGO_FILTERS={"db2": {"collection": "users", "query": {"status": "active"}}}'
      # Specify backup hour of day, defaults to 23
      - HOUR_OF_DAY=      
      # Specify AWS credentials or skip if using AWS IAM roles 
      - AWS_ACCESS_KEY_ID=
      - AWS_SECRET_ACCESS_KEY=   
      # Specify only if you want the backups stored in a specific folder
      - S3_PREFIX=
      # Specify only when backups need to be disabled
      - BACKUPS_DISABLED=TRUE
    restart: always
```

### NOTE

Backups are always enabled by default. If you wish to disable backups, you can set the BACKUPS_DISABLED environment variable as `TRUE` or `true`.

Using [Dockerhub](https://hub.docker.com/r/fundwave/s3-db-backup-cron)? Replace `build:` with `image: fundwave/s3-db-backup-cron:latest`
