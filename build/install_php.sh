#!/bin/bash

# Author: Tony Fahrion <tony.fahrion@de.clara.net>

#
# This script installs the PHP core packages and specified PHP extensions
# It requires that the ENV var PHP_VERSION is set!
#

SUPPORTED_PHP_VERSIONS='5.6 7.0'


export SHOP="/data/shop"
export SETUP=spryker
export TERM=xterm 
export VERBOSITY='-v'


# include helper functions
source ./build_library.sh
source ./functions.sh

# abort on error
set -e

#
#  Prepare
#

infoText "check if we support the requested PHP_VERSION"
if is_not_in_list "$PHP_VERSION" "$SUPPORTED_PHP_VERSIONS"; then
  errorText "Requested PHP_VERSION '$PHP_VERSION' is not supported. Abort!"
  infoText  "Supported PHP version is one of: $SUPPORTED_PHP_VERSIONS"
  exit 1
fi
successText "YES! Support is available for $PHP_VERSION"


infoText "set up PHP ppa to support even newer versions of PHP"
infoText "as this seems to fail sometimes (but works), ignore possible errors"
add-apt-repository ppa:ondrej/php || true


infoText "update apt cache to make use of the new PPA repo"
apt-get update


#
#  Install PHP core
#

infoText "install requested PHP core packages"
apt-get install $APT_GET_BASIC_ARGS --allow-unauthenticated \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli

infoText "generalize init.d script file name for monit"
ln -fs /etc/init.d/php${PHP_VERSION}-fpm /etc/init.d/php-fpm


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
