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
  labelText "Create configuration by templates ..."

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

    if [ "${APPLICATION_ENV}x" != "developmentx" ]; then
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


function build_assets_for_yves {
    labelText "Building and optimizing assets of Yves"
    antelope build yves
}


function build_assets_for_zed {
    labelText "Building and optimizing assets of Zed"
    antelope build zed
}


function init_shared {
    labelText "Initializing setup"

    infoText "Cleaning up ..."
    $CONSOLE cache:delete-all

    infoText "Generate transfer objects ..."
    $CONSOLE transfer:generate

    infoText "Create Search Index and Mapping Types; Generate Mapping Code."
    $CONSOLE setup:search

    exec_hooks "$SHOP/docker/init.d/Shared"
}


function init_yves {
    labelText "Initializing Yves ..."

    exec_hooks "$SHOP/docker/init.d/Yves"
}


function init_zed {

   labelText "Initializing Zed ..."

    infoText "Config convert ..."
    $CONSOLE propel:config:convert

    infoText "PG Compatibility ..."
    $CONSOLE propel:pg-sql-compat

    infoText "Create database ..."
    $CONSOLE propel:database:create

    infoText "Removing old pending propel migration plans ..."
    rm -f $SHOP/src/Orm/Propel/*/Migration_pgsql/*

    infoText "Create schema diff ..."
    $CONSOLE propel:diff

    infoText "Model Build ..."
    $CONSOLE propel:model:build

    infoText "Migrate Schema ..."
    $CONSOLE propel:migrate

    infoText "Initialize database ..."
    $CONSOLE setup:init-db

    exec_hooks "$SHOP/docker/init.d/Zed"
}


function exec_hooks {
    hook_d=$1
    if [ -e "$hook_d" -a -n "`ls -1 $hook_d/`" ]; then
      max=$(ls -1 $hook_d/|wc -l)
      i=1
      labelText "Running custom registered hooks ..."
      for hook in `find $hook_d -type f ! -name '\.*' -a -name '*.sh'`; do
        hook="${hook%\\n}"
        infoText "Executing $i/$max hook script: $hook ..."
        bash $hook
        let "i += 1"
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

        exec_hooks "$SHOP/docker/build.d"

        successText "Image Build has been successfully FINISHED"
        ;;

    init_setup)
        # wait for depending services and then initialize redis, elasticsearch and postgres
        # Run once per setup 
        mkdir -p /data/shop/assets/{Yves,Zed}

        build_assets_for_yves
        build_assets_for_zed

        # FIXME Poor mans waiting-for-depending-services-to-be-online needs to be fixed
        sleep 5

        # The different init stages has been already prepared to be split up in future
        init_shared
        init_yves
        init_zed

        successText "Setup Initialization has been successfully FINISHED"
        ;;
    *)
        bash -c "$*"
        ;;
esac
