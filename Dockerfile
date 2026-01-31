FROM alpine:3.18.3
LABEL maintainer="mohit@getfundwave.com"

RUN apk update && apk add --no-cache python3 py3-pip \
    && pip3 install --upgrade pip \
    && apk add mongodb-tools \
    && pip3 install awscli \
    && apk add mysql-client bash openssl coreutils curl \
    && apk add percona-xtrabackup --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    && mkdir -p /opt/backup /opt/backup/percona
ARG HOUR_OF_DAY
#ENV CRON_HOUR=${HOUR_OF_DAY:-23}

WORKDIR /opt/backup
COPY crontab.txt crontab.txt
COPY entry.sh entry.sh
COPY script.sh script.sh
COPY script-full.sh script-full.sh
COPY script-incremental.sh script-incremental.sh

COPY mysql/mysql-backup.sh mysql/mysql-backup.sh
COPY mysql/backup.sh mysql/backup.sh
COPY mysql/clean.sh mysql/clean.sh
COPY mysql/percona-full-backup.sh mysql/percona-full-backup.sh
COPY mysql/percona-incremental-backup.sh mysql/percona-incremental-backup.sh
COPY mysql/percona-s3-upload.sh mysql/percona-s3-upload.sh
COPY mysql/percona-clean.sh mysql/percona-clean.sh

COPY mongodb/mongo-backup.sh mongodb/mongo-backup.sh
COPY mongodb/s3.sh mongodb/s3.sh
COPY mongodb/clean.sh mongodb/clean.sh

RUN chmod 750 entry.sh script.sh script-full.sh script-incremental.sh
RUN chmod 750 mysql/mysql-backup.sh mysql/backup.sh mysql/clean.sh
RUN chmod 750 mysql/percona-full-backup.sh mysql/percona-incremental-backup.sh mysql/percona-s3-upload.sh mysql/percona-clean.sh
RUN chmod 750 mongodb/mongo-backup.sh mongodb/s3.sh mongodb/clean.sh

#RUN if [[ -n "$HOUR_OF_DAY" ]] ; then echo $HOUR_OF_DAY && sed -i "s/23/$HOUR_OF_DAY/g" crontab.txt && cat crontab.txt ; else echo "Defaulting to cron hour 23" ; fi
#RUN /usr/bin/crontab crontab.txt

CMD ["/opt/backup/entry.sh"]
