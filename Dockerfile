
FROM ubuntu:trusty

MAINTAINER Fabian Dörk <fabian.doerk@de.clara.net>


ENV SPRYKER_SHOP_CC="DE" \
    SPRYKER_APP_ENV="development" \
		ZED_HOST="" \
		ZED_HOST_PROTOCOL="" \
		YVES_HOST="" \
		YVES_HOST_PROTOCOL="" \
    ES_HOST="elasticsearch" \
    ES_PROTOCOL="http" \
    ES_PORT="10000" \
    REDIS_STORAGE_HOST="redis" \
    REDIS_STORAGE_PORT="6379" \
    REDIS_STORAGE_PASSWORD="" \
    REDIS_SESSION_HOST="redis" \
    REDIS_SESSION_PORT="6379" \
    REDIS_SESSION_PASSWORD="" \
    ZED_DB_USERNAME="postgres" \
    ZED_DB_PASSWORD="" \
    ZED_DB_DATABASE="spryker" \
    ZED_DB_HOST="db" \
    ZED_DB_PORT="5432" \
    JENKINS_BASEURL="http://jenkins:10007/jenkins"


RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y apt-transport-https curl && \
		echo "deb https://deb.nodesource.com/node_6.x trusty main" > /etc/apt/sources.list.d/nodesource.list && \
    curl --silent https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add - && \
    apt-get update && \
    apt-get install -y nginx nginx-extras php5-fpm monit nodejs && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/nginx/sites-enabled/default && \
    mkdir -p /data/logs

ADD etc/ /etc/
ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/bin/confd
COPY shop/ /data/shop/
COPY entrypoint.sh /

RUN chown www-data: -R /data/ && \
    chmod 755 /usr/bin/confd

EXPOSE 80 8080

WORKDIR /data/shop/
ENTRYPOINT [ "/entrypoint.sh" ]
CMD  [ "run" ]

LABEL org.label-schema.name="spryker-base" \
      org.label-schema.description="Providing base infrastructure for a containerized spryker e-commerce application" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://git.eu.clara.net/de-docker-images/spryker.git"
