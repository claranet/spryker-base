#!/bin/sh

cd $WORKDIR

infoText "Installing required PHP dependencies..."

if [ "${APPLICATION_ENV}x" != "developmentx" ]; then
  COMPOSER_ARGUMENTS="--no-dev"
fi

composer.phar install --prefer-dist $COMPOSER_ARGUMENTS
composer.phar clear-cache # Clears composer's internal package cache
