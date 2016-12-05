#!/usr/bin/env bash

set -e

export SHOP="/data/shop"
export SETUP=spryker
export TERM=xterm 
export VERBOSITY='-v'
export CONSOLE=vendor/bin/console

source /data/bin/functions.sh

function generate_configurations {
  if [ -n "$ETCD_NODE" ]; then
      confd -backend etcd -node ${ETCD_NODE} -prefix ${ETCD_PREFIX} -onetime
  else
      confd -backend env -onetime
  fi
}


# target during build time of child docker image executed by ONBUILD
# build trigger of base image
function install_dependencies {

    if [ -n "$PHP_EXTENSIONS" ]; then
      export DEBIAN_FRONTEND=noninteractive
      exts=$(echo "$PHP_EXTENSIONS" | awk  'BEGIN {RS=" "} { if (length($1) != 0) { printf "php-%s ", $1 }}' )
      infoText "Installing required PHP extensions: $exts"
      apt-get -y update
      apt-get -y install $exts
    fi

    if [ "${SPRYKER_APP_ENV}x" != "developmentx" ]; then 
      infoText "Installing required NPM dependencies..."
      npm install --only=production
      infoText "Installing required PHP dependencies..."
      php /data/bin/composer.phar install --prefer-dist --no-dev
    else
      infoText "Installing required NPM dependencies (including dev) ..."
      npm install
      infoText "Installing required PHP dependencies (including PHP) ..."
      php /data/bin/composer.phar install --prefer-dist
    fi
    php /data/bin/composer.phar clear-cache

    antelope install
}

function build_shared {
  labelText "Generating Transfer Objects"
  $CONSOLE transfer:generate
  writeErrorMessage "Generating Transfer Objects failed"

  labelText "Preparing Propel "
  $CONSOLE propel:model:build
  $CONSOLE propel:sql:build
  $CONSOLE propel:config:convert
}

function build_yves {
  antelopeInstallYves
}

function build_zed {
  antelopeInstallZed
}


case $1 in 
    init)
        # wait for depending services and then initialize redis, elasticsearch and postgres
        generate_configurations
        ;;
    run)
        generate_configurations
        /usr/bin/monit -d 10 -Ic /etc/monit/monitrc
        ;;
    build)
        cd $SHOP
        [ -e "$SHOP/build.conf" ] && source $SHOP/build.conf
        install_dependencies
        build_shared
        build_yves
        build_zed
        ;;
    init)
        ;;
    *)
        generate_configurations
        bash -c "$*"
        ;;
esac
