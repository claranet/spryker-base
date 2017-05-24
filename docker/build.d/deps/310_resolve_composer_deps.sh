#!/bin/sh

sectionText "Composer install"
composer.phar install --prefer-dist $COMPOSER_ARGUMENTS
composer.phar clear-cache # Clears composer's internal package cache
