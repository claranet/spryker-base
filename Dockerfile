
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
    JENKINS_PORT="8080" \
    JENKINS_BASEURL="http://$JENKINS_HOST:$JENKINS_PORT/"

ENV PATH="/data/bin/:$PATH"
ENV GOSU_VERSION 1.10
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /data/logs /data/bin /data/etc

# make this step cacheable
RUN apt-get update

# add add-apt-repository tool
RUN apt-get install -y software-properties-common

# this process seems to failsometimes while importing the keyring
RUN add-apt-repository ppa:ondrej/php || true

# now update the apt sources caches to make use of the new php
RUN apt-get update

RUN apt-get install -y  --no-install-recommends apt-transport-https ca-certificates curl \
		&& echo "deb https://deb.nodesource.com/node_6.x xenial main" > /etc/apt/sources.list.d/nodesource.list \
    && curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    \
    && arch="$(dpkg --print-architecture)" \
    && curl -sS -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$arch" \
    && curl -sS -L -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$arch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && chmod 755 /usr/local/bin/gosu \
    \
    && apt-get update \
    && apt-get install -y --allow-unauthenticated --no-install-recommends \
      nginx \
      nginx-extras \
      php7.0-fpm \
      php7.0-cli \
      monit \
      nodejs \
      git \
      netcat \
      net-tools \
      redis-tools \
      postgresql-client \
      mysql-client \
    \
    && npm -g install antelope \
    \
    && curl -sS -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -sS -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --install-dir=/data/bin/ \
    \
    && rm -rf /tmp/composer-setup* \
    && rm -f /etc/php/*/fpm/pool.d/www.conf \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* 

ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/bin/confd
COPY etc/ /etc/
COPY shop/ /data/shop/
COPY entrypoint.sh functions.sh /data/bin/

# fix wrong permissions of monitrc, else monit will refuse to run
RUN chmod 0700 /etc/monit/monitrc

RUN chown www-data: -R /data/ \
    && chmod 755 /usr/bin/confd \
    && rm /etc/nginx/sites-enabled/default \
    && ln -fs /data/bin/entrypoint.sh / \
    && ln -fs /data/etc/config_local.php /data/shop/config/Shared/config_local.php

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
ONBUILD COPY ./docker /data/shop/docker
ONBUILD COPY ./package.json ./composer.json /data/shop/
ONBUILD RUN  ln -fs /data/etc/config_local.php /data/shop/config/Shared/config_local.php
ONBUILD RUN  /entrypoint.sh build_image && chown -R www-data: /data/shop/
