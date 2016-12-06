#!/usr/bin/env bash

set -e

export SHOP="/data/shop"
export SETUP=spryker
export TERM=xterm 
export VERBOSITY='-v'
export CONSOLE=vendor/bin/console

source /data/bin/functions.sh

cd $SHOP


function generate_configurations {
  if [ -n "$ETCD_NODE" ]; then
      confd -backend etcd -node ${ETCD_NODE} -prefix ${ETCD_PREFIX} -onetime
  else
      confd -backend env -onetime
  fi
}


function install_dependencies {
    labelText "Resolving dependencies ..."

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
    labelText "Generating artifacts (transfer objects, propel, etc.) ..."

    infoText "Working on Transfer Objects"
    $CONSOLE transfer:generate
    writeErrorMessage "Generating Transfer Objects failed"

    infoText "Preparing Propel Configuration"
    
    # This seems to be the equivalent to the commands below
    $CONSOLE setup:deploy:prepare-propel

    ## copy and merge all the schema files distributed across the bundle
    #$CONSOLE propel:schema:copy
    ## generate the SQL code of your schema
    #$CONSOLE propel:sql:build
    ## generate model files which are just classes to interact easily with your different tables 
    #$CONSOLE propel:model:build
    ## build the PHP version of the propel runtime configuration for performance reasons
    #$CONSOLE propel:config:convert
}


function build_yves {
    labelText "Building and optimizing assets of Yves"
    antelope build yves
}


function build_zed {
    labelText "Building and optimizing assets of Zed"
    antelope build zed
}


function init_yves {
    labelText "Initialize data stores of Yves"
}


function init_zed {
    labelText "Initialize data stores of Zed"
}


generate_configurations
case $1 in 
    run)
        /usr/bin/monit -d 10 -Ic /etc/monit/monitrc
        ;;
    build)
        # target during build time of child docker image executed by ONBUILD
        # build trigger of base image
        [ -e "$SHOP/build.conf" ] && source $SHOP/build.conf
        install_dependencies
        build_shared
        build_yves
        build_zed
        ;;
    init)
        # wait for depending services and then initialize redis, elasticsearch and postgres
        ;;
    *)
        bash -c "$*"
        ;;
esac
