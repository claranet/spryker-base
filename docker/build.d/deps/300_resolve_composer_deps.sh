#!/bin/sh


COMPOSER_ARGUMENTS=""
if [ "${APPLICATION_ENV}x" != "developmentx" ]; then
    sectionText "Composer install (no dev)"
  COMPOSER_ARGUMENTS="--no-dev"
fi

composer.phar install --prefer-dist $COMPOSER_ARGUMENTS
composer.phar clear-cache # Clears composer's internal package cache
