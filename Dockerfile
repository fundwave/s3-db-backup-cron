FROM alpine:3.23.3
LABEL maintainer="mohit@getfundwave.com"

RUN apk update && apk add --no-cache \
    python3 \
    py3-pip \
    mongodb-tools \
    mysql-client \
    bash \
    openssl \
    coreutils \
    curl \
    && pip3 install --upgrade pip --break-system-packages \
    && pip3 install awscli --break-system-packages \
    && mkdir -p /opt/backup

ARG HOUR_OF_DAY

WORKDIR /opt/backup

COPY crontab.txt entry.sh script.sh ./
COPY mysql/ ./mysql/
COPY mongodb/ ./mongodb/

RUN chmod 750 entry.sh script.sh \
    && chmod 750 mysql/*.sh \
    && chmod 750 mongodb/*.sh

CMD ["/opt/backup/entry.sh"]
