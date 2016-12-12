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
      apt-get -y --no-install-recommends install $exts
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


function generate_code {
    labelText "Generating code artifacts (transfer objects, propel, etc.) ..."

    infoText "Generating Transfer Objects"
    $CONSOLE transfer:generate
    writeErrorMessage "Generation of Transfer Objects failed"

    # This seems to be the equivalent to the commands below
    infoText "Preparing Propel Configuration"
    $CONSOLE setup:deploy:prepare-propel

    ## Cleaning prior runs
    #$CONSOLE setup:remove-generated-directory
    ## copy and merge all the schema files distributed across the bundle
    #$CONSOLE propel:schema:copy
    ## generate the SQL code of your schema
    #$CONSOLE propel:sql:build
    ## generate model files which are just classes to interact easily with your different tables 
    #$CONSOLE propel:model:build
    ## build the PHP version of the propel runtime configuration for performance reasons
    #$CONSOLE propel:config:convert
}


function build_assets_for_yves {
    labelText "Building and optimizing assets of Yves"
    antelope build yves
}


function build_assets_for_zed {
    labelText "Building and optimizing assets of Zed"
    antelope build zed
}


function init {
    labelText "Initializing setup"

    infoText "Create Search Index and Mapping Types; Generate Mapping Code."
    $CONSOLE setup:search
}


function init_yves {
    labelText "Initializing Yves ..."
}


function init_zed {
    labelText "Initializing Zed ..."

    infoText "Setup DB ..."
    $CONSOLE setup:init-db
}


function exec_hooks {
    hook_d=$1
    if [ -e "$hook_d" -a -n "`ls -1 $hook_d/*`" ]; then
      labelText "Running custom registered hooks ..."
      for hook in $hook_d/*; do
        infoText "Executing hook script: $hook ..."
        bash $hook
      done
    fi
}


generate_configurations
case $1 in 
    run)
        /usr/bin/monit -d 10 -Ic /etc/monit/monitrc
        ;;

    build_image)
        # target during build time of child docker image executed by ONBUILD
        # build trigger of base image
        [ -e "$SHOP/docker/build.conf" ] && source $SHOP/docker/build.conf
        install_dependencies
        generate_code

        exec_hooks "$SHOP/docker/build.d"
        ;;

    init_setup)
        # wait for depending services and then initialize redis, elasticsearch and postgres
        # Run once per setup 
        mkdir -p /data/shop/assets/{Yves,Zed}
        build_assets_for_yves
        build_assets_for_zed

        # FIXME Poor mans waiting-for-depending-services-to-be-online needs to be fixed
        sleep 5

        init 
        init_yves
        init_zed

        exec_hooks "$SHOP/docker/init.d"
        ;;
    *)
        bash -c "$*"
        ;;
esac
