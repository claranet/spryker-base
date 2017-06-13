#!/bin/sh

#
# This script installs the PHP extensions and is able to install PECL extensions as well
#




#
#  Install PHP extensions
#

# helper to deduplicate common code
# installs special php extension dependencies before "install" is called
# removes those dependencies after "install" finishes
# arg1: extension name; arg2: list of dependencies
php_install_simple_extension() {
  EXTENSION=$1
  docker-php-ext-install -j$COMPILE_JOBS $EXTENSION
}

#
#  3rd party PHP extensions
#

# see https://pecl.php.net/package/imagick
php_install_imagick() {
  install_packages --build imagemagick-dev libtool
  install_packages imagemagick

  pecl install imagick-$PHP_EXTENSION_IMAGICK
  docker-php-ext-enable imagick
}

# see https://pecl.php.net/package/redis
php_install_redis() {
  pecl install redis-$PHP_EXTENSION_REDIS
  docker-php-ext-enable redis
}

#
#  Core PHP extensions
#


php_install_gd() {
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
  docker-php-ext-install -j$COMPILE_JOBS gd
}

php_install_bz2() {
  php_install_simple_extension $ext
}

php_install_curl() {
  php_install_simple_extension $ext
}

php_install_mcrypt() {
  php_install_simple_extension $ext
}

php_install_gmp() {
  php_install_simple_extension $ext
}

php_install_intl() {
  php_install_simple_extension $ext
}

php_install_pgsql() {
  php_install_simple_extension $ext
}

php_install_pdo_pgsql() {
  php_install_simple_extension $ext
}

php_install_readline() {
  php_install_simple_extension $ext
}

php_install_dom() {
  php_install_simple_extension $ext
}

php_install_xml() {
  php_install_simple_extension $ext
}

php_install_zip() {
  php_install_simple_extension $ext
}


# installs PHP extensions listed in $COMMON_PHP_EXTENSIONS and $PHP_EXTENSIONS
php_install_extensions() {
  docker-php-source extract
  
  # get a uniq list of extensions
  local UNIQ_PHP_EXTENSION_LIST=`echo "$COMMON_PHP_EXTENSIONS $PHP_EXTENSIONS" | tr "[[:space:]]" "\n" | sort | uniq`
  local PHP_EXTENSIONS_COUNT=`echo $UNIQ_PHP_EXTENSION_LIST | wc -w`
  local PHP_EXTENSIONS_COUNTER="1"
  
  for ext in $UNIQ_PHP_EXTENSION_LIST; do
    sectionNote "installing PHP extension ($PHP_EXTENSIONS_COUNTER of $PHP_EXTENSIONS_COUNT) $ext"
    if type php_install_$ext; then
      php_install_$ext
    else
      # try to install unknown extensions as it is possible, that they are part of the core
      # TODO: check, if the ext is part of the core
      docker-php-ext-install -j$COMPILE_JOBS $ext
    fi >> $BUILD_LOG 2>&1
    
    let 'PHP_EXTENSIONS_COUNTER += 1'
  done
  
  docker-php-source delete
}


php_install_composer() {
  #
  #   Composer
  #

  sectionNote "download and verify download of PHP composer"
  curl -sS -o /tmp/composer-setup.php https://getcomposer.org/installer
  curl -sS -o /tmp/composer-setup.sig https://composer.github.io/installer.sig
  php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"


  sectionNote "install PHP composer to /usr/bin/"
  php /tmp/composer-setup.php --install-dir=/usr/bin/


  # make the installation process of `composer install` faster by parallel downloads
  composer.phar global require hirak/prestissimo
  
  #
  #  Clean up
  #

  sectionNote "clean up PHP and composer installation"
  rm -rf /tmp/composer-setup*

  # remove php-fpm configs as they are adding a "www" pool, which does not exist
  rm /usr/local/etc/php-fpm.d/*
  
  touch /tmp/php_install_composer.task.finished
}


add_stage_step one php_install_extensions
add_stage_step one php_install_composer
