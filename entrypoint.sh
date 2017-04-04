#!/usr/bin/env bash

set -e

export SHOP="/data/shop"
export SETUP=spryker
export TERM=xterm 
export VERBOSITY='-v'
export CONSOLE=vendor/bin/console

# NOTE: requires $PHP_VERSION to be set from outside!
ENABLED_SERVICES=""


source /data/bin/functions.sh

cd $SHOP


function generate_configurations {
  labelText "Create runtime configuration ..."

  infoText "Applying confd templates ..."
  if [ -n "$ETCD_NODE" ]; then
      confd -backend etcd -node ${ETCD_NODE} -prefix ${ETCD_PREFIX} -onetime
  else
      confd -backend env -onetime
  fi

  if [ -e $CONSOLE ]; then
    infoText "Propel - Converting configuration ..."
    $CONSOLE propel:config:convert
  fi 
}


function install_dependencies {
    labelText "Resolving dependencies ..."

    if [ -n "$PHP_EXTENSIONS" ]; then
      export DEBIAN_FRONTEND=noninteractive
      
      for i in $PHP_EXTENSIONS; do
        exts="php${PHP_VERSION}-${i} $exts"
      done
      
      infoText "Installing required PHP extensions: $exts"
      apt-get -y update
      apt-get -y --allow-unauthenticated --no-install-recommends install $exts
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


function generate_shared_code {
    labelText "Generate code for both Yves and Zed ..."

    infoText "Generate transfer objects ..."
    $CONSOLE transfer:generate
}


function generate_zed_code {
    labelText "Generate code for Zed ..."

    infoText "Propel - Copy schema files ..."
    $CONSOLE propel:schema:copy

    infoText "Propel - Build models ..."
    $CONSOLE propel:model:build

    infoText "Propel - Removing old migration plans ..."
    rm -f $SHOP/src/Orm/Propel/*/Migration_pgsql/*
    
    infoText "Zed - generate navigation cache files"
    $CONSOLE navigation:build-cache
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

    infoText "Propel - Converting configuration ..."
    $CONSOLE propel:config:convert

    # FIXME Does this task makes sense during init stage? Since it works on
    # ./data which is not a shared volume? 
    infoText "Cleaning cache ..."
    $CONSOLE cache:delete-all

    infoText "Create Search Index and Mapping Types; Generate Mapping Code."
    $CONSOLE setup:search

    infoText "Build Zeds Navigation Cache ..."
    $CONSOLE application:build-navigation-cache

    exec_hooks "$SHOP/docker/init.d/Shared"
}


function init_yves {
    labelText "Initializing Yves ..."

    exec_hooks "$SHOP/docker/init.d/Yves"
}


function init_zed {
    labelText "Initializing Zed ..."

    infoText "Propel - Create database ..."
    $CONSOLE propel:database:create

    infoText "Propel - Insert PG compatibility ..."
    $CONSOLE propel:pg-sql-compat

    infoText "Propel - Create schema diff ..."
    $CONSOLE propel:diff

    infoText "Propel - Migrate Schema ..."
    $CONSOLE propel:migrate

    infoText "Propel - Initialize database ..."
    $CONSOLE setup:init-db

    exec_hooks "$SHOP/docker/init.d/Zed"

    infoText "Jenkins - Register setup wide cronjobs ..."
    # FIXME [bug01] until the code of the following cronsole command completely
    # relies on API calls, we need to workaround the issue with missing local
    # jenkins job definitions.
    mkdir -p /tmp/jenkins/jobs
    $CONSOLE setup:jenkins:generate
}


# force setting a symlink from sites-available to sites-enabled if vhost file exists
function enable_nginx_vhost {
  NGINX_SITES_AVAILABLE='/etc/nginx/sites-available'
  NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
  VHOST=$1
  if [ ! -e $NGINX_SITES_AVAILABLE/$VHOST ]; then
    errorText "\t nginx vhost '$VHOST' not found! Can't enable vhost!"
    return
  fi
  
  ln -fs $NGINX_SITES_AVAILABLE/$VHOST $NGINX_SITES_ENABLED/$VHOST
}


# force setting a symlink from php-fpm/apps-available to php-fpm/pool.d if app file exists
function enable_phpfpm_app {
  FPM_APPS_AVAILABLE="/etc/php/$PHP_VERSION/fpm/apps-available"
  FPM_APPS_ENABLED="/etc/php/$PHP_VERSION/fpm/pool.d"
  APP="${1}.conf"
  if [ ! -e $FPM_APPS_AVAILABLE/$APP ]; then
    errorText "\t php-fpm app '$APP' not found! Can't enable app!"
    return
  fi
  
  ln -fs $FPM_APPS_AVAILABLE/$APP $FPM_APPS_ENABLED/$APP
}


function enable_services {
  for SERVICE in $ENABLED_SERVICES; do
    labelText "Enable ${SERVICE} vHost and PHP-FPM app..."
    
    infoText "Enbable ${SERVICE} - Link nginx vHost to sites-enabled/..."
    enable_nginx_vhost ${SERVICE}
    
    infoText "Enable ${SERVICE} - Link php-fpm pool app config to pool.d/..."
    enable_phpfpm_app ${SERVICE}
  done
}


function start_services {
  labelText "Starting enabled services $ENABLED_SERVICES"
  
  generate_configurations
  /usr/bin/monit -d 10 -Ic /etc/monit/monitrc
  chown -R www-data: /data/shop/data
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


case $1 in 
    run_yves)
      ENABLED_SERVICES="yves"
      enable_services
      start_services
      ;;

    run_zed)
      ENABLED_SERVICES="zed"
      enable_services
      start_services
      ;;

    run_both)
      ENABLED_SERVICES="yves zed"
      enable_services
      start_services
      ;;

    build_image)
        # target during build time of child docker image executed by ONBUILD
        # build trigger of base image
        [ -e "$SHOP/docker/build.conf" ] && source $SHOP/docker/build.conf
        install_dependencies
        generate_configurations
        generate_shared_code
        generate_zed_code

        exec_hooks "$SHOP/docker/build.d"

        successText "Image Build has been successfully FINISHED"
        ;;

    init_setup)
        generate_configurations
        # wait for depending services and then initialize redis, elasticsearch and postgres
        # Run once per setup 
        mkdir -p /data/shop/assets/{Yves,Zed}

        build_assets_for_yves
        build_assets_for_zed

        # FIXME the following line is workaround:
        #   (1) setup:search must be run at runtime 
        #   (2) therefore ./src/Generated needs to be a shared volume
        #   (3) thats why the transfer objects generated during build time are not available anymore
        #   (4) but we need them there, because propel generation relies on these transfer objects
        #   (5) and thats why we need to regenerate them here 
        # If search:setup task has been split up into a build and init time part, we are able to clean this up
        generate_shared_code

        # FIXME Poor mans waiting-for-depending-services-to-be-online needs to be fixed
        sleep 5

        # The different init stages has been already prepared to be split up in future
        init_shared
        init_yves
        init_zed

        successText "Setup Initialization has been successfully FINISHED"
        ;;
    *)
        generate_configurations
        bash -c "$*"
        ;;
esac
