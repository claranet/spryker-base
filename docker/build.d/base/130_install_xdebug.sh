#!/bin/sh

! is_true $ENABLE_XDEBUG && return 0

sectionText "Installing xdebug ..."

[ -z "$(php -m | grep xdebug)" ] && pecl install xdebug
docker-php-ext-enable xdebug
echo 'xdebug.profiler_enable=1' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
echo 'xdebug.profiler_output_dir=/tmp/xdebug' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
mkdir -pv /tmp/xdebug
chmod -v 7777 /tmp/xdebug
