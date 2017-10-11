#!/bin/sh

php_install_all_extensions

# remove php-fpm configs as they are adding a "www" pool, which does not exist
find /usr/local/etc/php-fpm.d/ -type f -delete
