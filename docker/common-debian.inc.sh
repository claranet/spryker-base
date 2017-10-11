#!/bin/bash

is_debian || return 0

install_packages() {
  local APT_CACHE_REFRESHED="/var/tmp/apt-cache-refreshed"
  local INSTALL_FLAGS="-qq -y -o Dpkg::Options::=--force-confdef"
  if [ ! -e "$APT_CACHE_REFRESHED" ]; then
    sectionText "Refreshing apt cache initially"
    #apt-get update >> $BUILD_LOG
    apt-get update
    touch $APT_CACHE_REFRESHED
  fi
  if [ "$1" = "--build" ]; then
    shift
    echo "$*" | tr ' ' '\n' >> /var/tmp/build-deps.list
  fi
  local PKG_LIST="$*"
  if [ -n "$PKG_LIST" ]; then
    sectionText "Installing package(s): $PKG_LIST"
    #DEBIAN_FRONTEND=noninteractive apt-get install $INSTALL_FLAGS $PKG_LIST >> $BUILD_LOG
    DEBIAN_FRONTEND=noninteractive apt-get install $INSTALL_FLAGS $PKG_LIST
  fi
}

cleanup() {
  if [ -e /var/tmp/build-deps.list ]; then
    sectionText "Removing build depedencies"
    cat /var/tmp/build-deps.list | xargs apt-get remove --purge -y || true >> $BUILD_LOG
    rm -f /var/tmp/build-deps.list
    apt-get autoremove -y
  fi
}

# see https://pecl.php.net/package/imagick
php_install_imagick() {
  install_packages --build libmagickwand-dev
  [ -z "$(php -m | grep imagick)" ] && pecl install imagick-$PHP_EXTENSION_IMAGICK
  docker-php-ext-enable imagick
}

# see https://pecl.php.net/package/redis
php_install_redis() {
  [ -z "$(php -m | grep redis)" ] && pecl install redis-$PHP_EXTENSION_REDIS
  docker-php-ext-enable redis
}

php_install_gd() {
  install_packages --build libfreetype6-dev\
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev
  
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
  docker-php-ext-install -j$COMPILE_JOBS gd
  
  install_packages libpng12-0 libjpeg62-turbo libfreetype6
}

php_install_xdebug() {
  pecl list | grep -qi xdebug || pecl install xdebug-$PHP_EXTENSION_XDEBUG
}

php_install_opcache() {
  php_ext_install opcache
}

php_install_bz2() {
  install_packages bzip2
  php_ext_install $ext "libbz2-dev"
}

php_install_curl() {
  php_ext_install $ext "libcurl4-openssl-dev"
}

php_install_mcrypt() {
  php_ext_install $ext "libmcrypt-dev"
  install_packages libmcrypt-dev
}

php_install_gmp() {
  php_ext_install $ext "libgmp-dev"
}

php_install_intl() {
  php_ext_install $ext "libicu-dev"
}

php_install_pgsql() {
  php_ext_install $ext "libpq-dev"
  install_packages libpq5
}

php_install_pdo_pgsql() {
  install_packages libpq5
  php_ext_install $ext "libpq-dev"
}

php_install_readline() {
  php_ext_install $ext "readline-dev libedit-dev"
}

php_install_dom() {
  php_ext_install $ext "libxml2-dev"
}

php_install_xml() {
  php_ext_install $ext "libxml2-dev"
}

php_install_zip() {
  install_packages libzip2
  php_ext_install $ext "libzip-dev"
}

