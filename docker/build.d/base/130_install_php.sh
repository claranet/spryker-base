#!/bin/sh

#
# This script installs the PHP and PECL extensions 
#

#get amount of available prozessors * 2 for faster compiling of sources
COMPILE_JOBS=$((`getconf _NPROCESSORS_ONLN`*2))

# arg1: extension name; arg2: list of dependencies
php_ext_install() {
  EXTENSION=$1
  DEPS="$2"
  
  [ -n "$DEPS" ] && install_packages --build $DEPS
  retry 3 docker-php-ext-install -j$COMPILE_JOBS $EXTENSION
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


#
#  Core PHP extensions
#
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
  [ -z "$(php -m | grep xdebug)" ] && pecl install xdebug-$PHP_EXTENSION_XDEBUG
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

# filters all modules in extensions list by checking, if those extensions are already build
# you can use this function to read from stdin (e.g. in a pipe) or give it an argument
# it will stdout all not prebuild modules
php_filter_prebuild_extensions() {
  # get a list of already compiled modules
  local PHP_PREBUILD_MODULES=`php -m | egrep '^([A-Za-z_]+)$' | tr '[:upper:]' '[:lower:]'`
  
  while read line; do
    if ! echo "$PHP_PREBUILD_MODULES" | egrep "^($line)$"; then
      echo "$line"
    fi
  done < ${1:-/dev/stdin}
}


# installs PHP extensions listed in $COMMON_PHP_EXTENSIONS and $PHP_EXTENSIONS
php_install_all_extensions() {
  docker-php-source extract
  install_packages --build re2c
  
  # get a uniq list of extensions and filter already build extensions
  local UNIQ_PHP_EXTENSION_LIST=`echo "$COMMON_PHP_EXTENSIONS $PHP_EXTENSIONS" | tr "[[:space:]]" "\n" | sort | uniq | php_filter_prebuild_extensions`
  local PHP_EXTENSIONS_COUNT=`echo $UNIQ_PHP_EXTENSION_LIST | wc -w`
  local PHP_EXTENSIONS_COUNTER="1"
  
  for ext in $UNIQ_PHP_EXTENSION_LIST; do
    sectionText "Installing PHP extension ($PHP_EXTENSIONS_COUNTER/$PHP_EXTENSIONS_COUNT) $ext"
    if type php_install_$ext; then
      php_install_$ext
    else
      # try to install unknown extensions as it is possible, that they are part of the core
      # TODO: check, if the ext is part of the core
      php_ext_install $ext
    fi >> $BUILD_LOG 2>&1
    
    let 'PHP_EXTENSIONS_COUNTER += 1'
  done
  
  docker-php-source delete
}

php_install_all_extensions

# remove php-fpm configs as they are adding a "www" pool, which does not exist
rm /usr/local/etc/php-fpm.d/*
