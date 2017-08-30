
FROM php:7.0.21-fpm-alpine

# see http://label-schema.org/rc1/
LABEL org.label-schema.name="spryker-base" \
      org.label-schema.version="0.9" \
      org.label-schema.description="Providing base infrastructure of a containerized Spryker Commerce Framework based Shop" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://github.com/claranet/spryker-base" \
      author1="Fabian Dörk <fabian.doerk@de.clara.net>" \
      author2="Tony Fahrion <tony.fahrion@de.clara.net>" \
      author3="Felipe Santos <felipe.santos@de.clara.net>"

ENV WORKDIR=/data/shop \
    CONFIG_DIR=/mnt/configs \
    PHP_INI_SCAN_DIR=/usr/local/etc/php/conf.d:/etc/php/ini

# Reference of spryker config related ENV vars
ENV APPLICATION_ENV="production" \
    SPRYKER_SHOP_CC="DE" \
    ZED_HOST="zed" \
    YVES_HOST="yves" \
    ES_HOST="elasticsearch" \
    ES_PROTOCOL="http" \
    ES_PORT="9200" \
    REDIS_STORAGE_PROTOCOL="tcp" \
    REDIS_STORAGE_HOST="redis" \
    REDIS_STORAGE_PORT="6379" \
    REDIS_STORAGE_PASSWORD="" \
    REDIS_SESSION_PROTOCOL="tcp" \
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
    RABBITMQ_HOST="rabbitmq" \
    RABBITMQ_PORT="5672" \
    RABBITMQ_USER="spryker" \
    RABBITMQ_PASSWORD="" \
    YVES_SSL_ENABLED="false" \
    YVES_COMPLETE_SSL_ENABLED="false" \
    ZED_SSL_ENABLED="false" \
    ZED_API_SSL_ENABLED="false"

COPY etc/ /etc/
COPY docker $WORKDIR/docker
RUN apk add --no-cache \
        perl \
        bash \
    && mkdir -p /data/logs \
    && ln -vfs /bin/bash /bin/sh \
    && ln -vfs $WORKDIR/docker/entrypoint.sh /entrypoint.sh

# Install spryker's core requirements in the base image to reduce the build time
# of a specific shop.
# This makes the image slightly larger.
RUN /entrypoint.sh build-base

EXPOSE 80

WORKDIR $WORKDIR
ENTRYPOINT [ "/entrypoint.sh" ]

CMD  [ "run-yves-and-zed" ]

ONBUILD ARG NETRC

ONBUILD COPY docker/ $WORKDIR/docker/

ONBUILD COPY .* $WORKDIR/
ONBUILD COPY assets/ $WORKDIR/assets
ONBUILD COPY package.* composer.* yarn.* $WORKDIR/
ONBUILD RUN /entrypoint.sh build-deps

ONBUILD COPY src/Pyz $WORKDIR/src/Pyz
ONBUILD COPY config $WORKDIR/config
ONBUILD COPY public $WORKDIR/public
ONBUILD RUN /entrypoint.sh build-shop

ONBUILD COPY codeception* $WORKDIR/
ONBUILD COPY tests $WORKDIR/tests

ONBUILD RUN /entrypoint.sh build-end
