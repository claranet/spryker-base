#!/bin/bash

# Author: Tony Fahrion <tony.fahrion@de.clara.net>

#
# This script installs the PHP extensions and is able to install PECL extensions as well
#



# include helper functions
source ./functions.sh

# include custom build config on demand
if [[ -e "$WORKDIR/docker/build.conf" ]]; then
  source "$WORKDIR/docker/build.conf"
fi

# abort on error
set -e


#
#  Install PHP extensions
#


# FIXME: install extensions, some of them need a special install way
# write functions to install special extensions
# same goes for pecl

function install_imagick() {
  apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS imagemagick-dev libtool
  pecl install imagick-3.4.3
  docker-php-ext-enable imagick
  apk add --no-cache --virtual .imagick-runtime-deps imagemagick
  apk del .phpize-deps
}

function install_gd() {
  apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev
  
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
  docker-php-ext-install -j$(nproc) gd
  apk del .phpize-deps
}

function install_xcache() {
  curl -fsSL 'https://xcache.lighttpd.net/pub/Releases/3.2.0/xcache-3.2.0.tar.gz' -o xcache.tar.gz \
    && mkdir -p /tmp/xcache \
    && tar -xf xcache.tar.gz -C /tmp/xcache --strip-components=1 \
    && rm xcache.tar.gz \
    && docker-php-ext-configure /tmp/xcache --enable-xcache \
    && docker-php-ext-install -j$(nproc) /tmp/xcache \
    && rm -r /tmp/xcache
}

function install_redis() {
  apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS redis
  
  pecl install redis
  docker-php-ext-enable redis
  apk del .phpize-deps
}

docker-php-source extract

for ext in $PHP_EXTENSIONS; do
  
  case $ext in
    imagick|gd|xcache|redis)
      install_$ext
      ;;
    *)
      # try to install unknown extensions as it is possible, that they are part of the core
      # TODO: check, if the ext is part of the core
      docker-php-ext-install -j$(nproc) $ext
  esac
  
done

docker-php-source delete


#
#   Composer
#

infoText "download and verify download of PHP composer"
curl -sS -o /tmp/composer-setup.php https://getcomposer.org/installer
curl -sS -o /tmp/composer-setup.sig https://composer.github.io/installer.sig
php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"


infoText "install PHP composer to /data/bin/"
php /tmp/composer-setup.php --install-dir=/data/bin/


#
#  Clean up
#

infoText "clean up PHP and composer installation"
rm -rf /tmp/composer-setup*
rm -f /etc/php/*/fpm/pool.d/www.conf
