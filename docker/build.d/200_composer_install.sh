#!/bin/sh


if [ "${APPLICATION_ENV}x" != "developmentx" ]; then
  sectionNote "do composer install without dev dependencies"
  COMPOSER_ARGUMENTS="--no-dev"
fi

composer.phar install --prefer-dist $COMPOSER_ARGUMENTS
composer.phar clear-cache # Clears composer's internal package cache
