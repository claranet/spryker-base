#!/bin/bash

is_alpine || return 0

install_packages() {
  local INSTALL_FLAGS=""
  if [ -z "${APK_CACHE_REFRESHED}" ]; then
    sectionText "Refreshing apk cache initially"
    apk update >> $BUILD_LOG
    export APK_CACHE_REFRESHED=yes
  fi
  if [ "$1" = "--build" ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS --virtual .build_deps"
    shift
  fi

  local PKG_LIST="$*"
  if [ -n "$PKG_LIST" ]; then
    sectionText "Installing package(s): $PKG_LIST"
    apk add $INSTALL_FLAGS $PKG_LIST >> $BUILD_LOG
  fi
}

cleanup() {
  sectionText "Removing build depedencies"
  apk del .build_deps || true >> $BUILD_LOG

  sectionText "Cleaning up /tmp folder"
  rm -rf /tmp/*

  sectionText "Removing apk package index files"
  find /var/cache/apk  -type f -exec rm {} \;
}

# see https://pecl.php.net/package/imagick
php_install_imagick() {
  install_packages --build imagemagick-dev libtool
  install_packages imagemagick

  [ -z "$(php -m | grep imagick)" ] && pecl install imagick-$PHP_EXTENSION_IMAGICK
  docker-php-ext-enable imagick
}

# see https://pecl.php.net/package/redis
php_install_redis() {
  install_packages --build redis
  
  [ -z "$(php -m | grep redis)" ] && pecl install redis-$PHP_EXTENSION_REDIS
  docker-php-ext-enable redis
}

php_install_gd() {
  install_packages --build freetype-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev
  
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
  docker-php-ext-install -j$COMPILE_JOBS gd
  
  install_packages libpng libjpeg-turbo freetype
}

php_install_xdebug() {
  pecl list | grep -qi xdebug || pecl install xdebug-$PHP_EXTENSION_XDEBUG
}

php_install_opcache() {
  php_ext_install opcache
}

php_install_bz2() {
  php_ext_install $ext "bzip2-dev"
  install_packages bzip2
}

php_install_curl() {
  php_ext_install $ext "curl-dev"
  install_packages libcurl
}

php_install_mcrypt() {
  php_ext_install $ext "libmcrypt-dev"
  install_packages libmcrypt
}

php_install_gmp() {
  php_ext_install $ext "gmp-dev"
  install_packages gmp
}

php_install_intl() {
  install_packages libintl icu-libs
  php_ext_install $ext "icu-dev"
}

php_install_pgsql() {
  php_ext_install $ext "postgresql-dev"
  install_packages libpq
}

php_install_pdo_pgsql() {
  php_ext_install $ext "postgresql-dev"
  install_packages libpq
}

php_install_readline() {
  php_ext_install $ext "readline-dev libedit-dev"
  install_packages readline libedit
}

php_install_dom() {
  php_ext_install $ext "libxml2-dev"
  install_packages libxml2
}

php_install_xml() {
  php_ext_install $ext "libxml2-dev"
  install_packages libxml2
}

php_install_zip() {
  php_ext_install $ext "zlib-dev"
}
