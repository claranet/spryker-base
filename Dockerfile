
FROM php:7.0.21-fpm-alpine

# see http://label-schema.org/rc1/
LABEL org.label-schema.name="spryker-base" \
      org.label-schema.version="1.0" \
      org.label-schema.description="Providing base infrastructure of a containerized Spryker Commerce Framework based Shop" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://github.com/claranet/spryker-base" \
      author1="Fabian Dörk <fabian.doerk@de.clara.net>" \
      author2="Tony Fahrion <tony.fahrion@de.clara.net>" \
      author3="Felipe Santos <felipe.santos@de.clara.net>"

ENV WORKDIR=/data/shop \
    CONFIG_DIR=/mnt/configs \
    PHP_INI_SCAN_DIR=/usr/local/etc/php/conf.d:/etc/php/ini \
    PHP_EXTENSION_REDIS=3.1.2 \
    PHP_EXTENSION_XDEBUG=2.5.4 \
    SKIP_CLEANUP=false

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
# Upgrade alpine version
RUN sed -i -e 's/3\.4/3.5/g' /etc/apk/repositories \
    && apk update \
    && apk upgrade --clean-protected

# Install important OS dependencies
RUN apk add --virtual .build_deps \
        ccache autoconf file g++ gcc libc-dev make pkgconf re2c freetype-dev libjpeg-turbo-dev libmcrypt-dev \
        libpng-dev bzip2-dev gmp-dev icu-dev libmcrypt-dev postgresql-dev zlib-dev
RUN apk add --no-cache perl bash graphviz \
    && mkdir -p /data/logs \
    && ln -vfs /bin/bash /bin/sh \
    && ln -vfs $WORKDIR/docker/entrypoint.sh /entrypoint.sh

# Install programs
RUN apk add --no-cache git nginx nginx-mod-http-headers-more postgresql-client nodejs redis

# nginx config
RUN rm /etc/nginx/conf.d/default.conf \
    && mkdir /run/nginx

# Configure git to use https instead of git+ssh for github.com sources
RUN git config --global url."https://github.com/".insteadOf "git@github.com:" \
    && git config --global url.https://.insteadOf git://

# Install libs
RUN apk add --no-cache bzip2 libpng libjpeg-turbo freetype gmp libintl icu-libs libmcrypt libpq

# Install PHP modules
RUN docker-php-source extract \
    && docker-php-ext-install -j$((`getconf _NPROCESSORS_ONLN`*2)) \
        bcmath bz2 gmp intl mcrypt opcache pdo_pgsql pgsql zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$((`getconf _NPROCESSORS_ONLN`*2)) gd \
    && [ -z "$(php -m | grep redis)" ] && pecl install redis-$PHP_EXTENSION_REDIS
RUN docker-php-ext-enable redis \
    && [ -z "$(php -m | grep xdebug)" ] && pecl install xdebug-$PHP_EXTENSION_XDEBUG
RUN docker-php-source delete \
    && rm /usr/local/etc/php-fpm.d/*

# Install composer
RUN curl -sS -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -sS -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== \
trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); \
echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --install-dir=/usr/bin/ \
    && composer.phar global require hirak/prestissimo

# Clean up
RUN [ $SKIP_CLEANUP == false ] \
    && apk del .build_deps || true \
    && rm -rf /tmp/* \
    && find /var/cache/apk  -type f -exec rm {} \;

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
