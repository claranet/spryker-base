#!/bin/sh

cd $WORKDIR

infoText "Installing required PHP dependencies..."

if [ "${APPLICATION_ENV}x" != "developmentx" ]; then
  COMPOSER_ARGUMENTS="--no-dev"
fi

php /data/bin/composer.phar install --prefer-dist $COMPOSER_ARGUMENTS
php /data/bin/composer.phar clear-cache # Clears composer's internal package cache
