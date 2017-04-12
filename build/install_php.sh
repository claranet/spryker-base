#!/bin/bash

# Author: Tony Fahrion <tony.fahrion@de.clara.net>

#
# This script installs the PHP extensions and is able to install PECL extensions as well
#



# include helper functions
source ./build_library.sh
source ./functions.sh

# abort on error
set -e


#
#  Install PHP extensions
#

PHP_DEPENDENCIES="$PHP_EXTENSION_DEPENDENCIES \
  libfreetype6 \
  libjpeg62-turbo \
  libmcrypt \
  libpng12"

apk install --no-cache $PHP_DEPENDENCIES

# install base PHP extensions
docker-php-ext-install -j$(nproc) iconv mcrypt
docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-install -j$(nproc) gd

# FIXME: install extensions, some of them need a special install way
# write functions to install special extensions
# same goes for pecl


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
