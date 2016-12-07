
FROM ubuntu:xenial

MAINTAINER Fabian Dörk <fabian.doerk@de.clara.net>


ENV SPRYKER_SHOP_CC="DE" \
    APPLICATION_ENV="production" \
		ZED_HOST="" \
		ZED_HOST_PROTOCOL="" \
		YVES_HOST="" \
		YVES_HOST_PROTOCOL="" \
    ES_HOST="elasticsearch" \
    ES_PROTOCOL="http" \
    ES_PORT="9200" \
    REDIS_STORAGE_HOST="redis" \
    REDIS_STORAGE_PORT="6379" \
    REDIS_STORAGE_PASSWORD="" \
    REDIS_SESSION_HOST="redis" \
    REDIS_SESSION_PORT="6379" \
    REDIS_SESSION_PASSWORD="" \
    ZED_DB_USERNAME="postgres" \
    ZED_DB_PASSWORD="" \
    ZED_DB_DATABASE="spryker" \
    ZED_DB_HOST="database" \
    ZED_DB_PORT="5432" \
    JENKINS_HOST="jenkins" \
    JENKINS_PORT="10007" \
    JENKINS_BASEURL="http://$JENKINS_HOST:$JENKINS_PORT/jenkins"

ENV PATH="/data/bin/:$PATH"

RUN mkdir -p /data/logs /data/bin /data/etc 

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y apt-transport-https curl && \
		echo "deb https://deb.nodesource.com/node_6.x xenial main" > /etc/apt/sources.list.d/nodesource.list && \
    curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    apt-get update && \
    apt-get install -y nginx nginx-extras php-fpm php-cli monit nodejs git netcat net-tools && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/nginx/sites-enabled/default && \
    npm -g install antelope  && \
    curl -sS -o /tmp/composer-setup.php https://getcomposer.org/installer && \
    curl -sS -o /tmp/composer-setup.sig https://composer.github.io/installer.sig && \
    php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php /tmp/composer-setup.php --install-dir=/data/bin/ && \
    rm -rf /tmp/composer-setup*

ADD etc/ /etc/
ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/bin/confd
COPY shop/ /data/shop/
COPY entrypoint.sh functions.sh /data/bin/

RUN chown www-data: -R /data/ && \
    chmod 755 /usr/bin/confd && \
    ln -fs /data/bin/entrypoint.sh / && \
    ln -fs /data/etc/config_local.php /data/shop/config/Shared/config_local.php

COPY entrypoint.sh /
COPY functions.sh /data/bin/

EXPOSE 80 8080

WORKDIR /data/shop/
ENTRYPOINT [ "/entrypoint.sh" ]
CMD  [ "run" ]

LABEL org.label-schema.name="spryker-base" \
      org.label-schema.version="1.0" \
      org.label-schema.description="Providing base infrastructure for a containerized spryker e-commerce application" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://git.eu.clara.net/de-docker-images/spryker.git"


ONBUILD COPY ./src /data/shop/src
ONBUILD COPY ./config /data/shop/config
ONBUILD COPY ./public /data/shop/public
ONBUILD COPY ./package.json ./composer.json build.conf /data/shop/
ONBUILD RUN  ln -fs /data/etc/config_local.php /data/shop/config/Shared/config_local.php && chown -R www-data: /data/shop/
ONBUILD RUN  /entrypoint.sh build
