#!/bin/sh

sectionText "Composer install"
composer.phar install --prefer-dist $COMPOSER_ARGUMENTS >>$BUILD_LOG 2>&1
sectionText "Composer clear cache"
composer.phar clear-cache >>$BUILD_LOG 2>&1
