#!/bin/sh

CONSOLE="execute_console_command"

# services activated for this docker container instance will be added to this string
ENABLED_SERVICES=""


source /data/bin/functions.sh
[ -e "$SHOP/docker/build.conf" ] && source $SHOP/docker/build.conf

cd $SHOP


# force setting a symlink from sites-available to sites-enabled if vhost file exists
enable_nginx_vhost() {
  NGINX_SITES_AVAILABLE='/etc/nginx/sites-available'
  NGINX_SITES_ENABLED='/etc/nginx/conf.d'
  VHOST=$1
  
  if [ ! -e $NGINX_SITES_AVAILABLE/$VHOST ]; then
    errorText "\t nginx vhost '$VHOST' not found! Can't enable vhost!"
    return
  fi
  
  ln -fs $NGINX_SITES_AVAILABLE/$VHOST $NGINX_SITES_ENABLED/${VHOST}.conf
}


# force setting a symlink from php-fpm/apps-available to php-fpm/pool.d if app file exists
enable_phpfpm_app() {
  FPM_APPS_AVAILABLE="/etc/php/apps"
  FPM_APPS_ENABLED="/usr/local/etc/php-fpm.d"
  
  APP="${1}.conf"
  if [ ! -e $FPM_APPS_AVAILABLE/$APP ]; then
    errorText "\t php-fpm app '$APP' not found! Can't enable app!"
    return
  fi
  
  # enable php-fpm pool config
  ln -fs $FPM_APPS_AVAILABLE/$APP $FPM_APPS_ENABLED/$APP
}


enable_services() {
  for SERVICE in $ENABLED_SERVICES; do
    labelText "Enable ${SERVICE} vHost and PHP-FPM app..."
    
    infoText "Enbable ${SERVICE} - Link nginx vHost to sites-enabled/..."
    enable_nginx_vhost ${SERVICE}
    
    infoText "Enable ${SERVICE} - Link php-fpm pool app config to pool.d/..."
    enable_phpfpm_app ${SERVICE}
    
    # if we are the ZED instance, init ENV
    if [ "${SERVICE}" = "zed" ]; then
      infoText "init external services (DBMS, ES)"
      /data/bin/entrypoint.sh init_setup
    fi
    
  done
}


start_services() {
  labelText "Starting enabled services $ENABLED_SERVICES"
  
  # fix error with missing event log dir
  mkdir -p /data/shop/data/$SPRYKER_SHOP_CC/logs/
  
  # TODO: increase security by making this more granular
  chown -R www-data: /data/logs /data/shop
  
  # starts nginx daemonized, to start php-fpm in background
  # check if nginx failed...
  nginx && php-fpm --nodaemonize
}

execute_console_command() {
  infoText "execute 'console $@'"
  vendor/bin/console $@
}


exec_hooks() {
    hook_d=$1
    if [ -d "$hook_d" ]; then
      for f in `find $hook_d -type f -name '*.sh'`; do
        infoText "Executing hook script: $f"
        source $f
      done
    fi
}

wait_for_service() {
  until nc -z $1 $2; do
    echo "waiting for $1 to come up..."
    sleep 1
  done
  
  echo "$1 seems to be up, port is open"
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

    run_yves_and_zed)
      ENABLED_SERVICES="yves zed"
      enable_services
      start_services
      ;;
    
    build_image)
    
        # rule of thumb:
        # zed is able to work without yves, so generate zed data first!
        
        
        # ============= install dependencies PHP/NodeJS ===============
        
        
        infoText "Installing required PHP dependencies..."
        
        if [ "${APPLICATION_ENV}x" != "developmentx" ]; then
          COMPOSER_ARGUMENTS="--no-dev"
        fi
        
        php /data/bin/composer.phar install --prefer-dist $COMPOSER_ARGUMENTS
        php /data/bin/composer.phar clear-cache # Clears composer's internal package cache
        
        
        # install dependencies for building asset
        # --with-dev is required to install spryker/oryx (works behind npm run x)
        infoText "Installing required NPM dependencies..."
        $NPM install --with-dev
        
        # as we are collecting assets from various vendor/ composer modules
        # we also need to install possible assets-build dependencies from those
        # modules
        for i in `find vendor/ -name 'package.json' | egrep 'assets/(Zed|Yves)/package.json'`; do
          cd `dirname $i`
          $NPM install
          cd $WORKDIR
        done
        
        # ============= build assets ===============
        
        infoText "Build assets for Yves/Zed"
        
        # TODO: add zed:prod and yves:prod possibility
        $NPM run zed
        $NPM run yves
    
        # ============= ORM code / schema generation ===============
        
        infoText "Propel - Copy schema files ..."
        # Copy schema files from packages to generated folder
        $CONSOLE propel:schema:copy
        
        
        # ============= generate_shared_code ===============
        
        # zed <-> yves transfer objects
        # Generates transfer objects from transfer XML definition files
        # time: any, static code generator
        $CONSOLE transfer:generate
        
        infoText "Create Search Index and Mapping Types; Generate Mapping Code."
        # Generate elasticsarch code classes to access indexes
        $CONSOLE setup:search:index-map
    
        # FIXME //TRANSLIT isn't supported with musl-libc (used by alpine linux), by intension!
        # see https://github.com/akrennmair/newsbeuter/issues/364#issuecomment-250208235
        # and http://wiki.musl-libc.org/wiki/Functional_differences_from_glibc#iconv
        sed -i 's#//TRANSLIT##g'  /data/shop/vendor/spryker/util-text/src/Spryker/Service/UtilText/Model/Slug.php
        
        
        infoText "Build Zeds Navigation Cache ..."
        $CONSOLE navigation:build-cache
        
        ;;
    
    init_setup)
        
        # ElasticSearch init
        
        wait_for_service $ES_HOST $ES_PORT
        $CONSOLE setup:search

        # SQL Database
        
        wait_for_service $ZED_DB_HOST $ZED_DB_PORT
        
        infoText "Propel - Insert PG compatibility ..."
        # Adjust Propel-XML schema files to work with PostgreSQL
        $CONSOLE propel:pg-sql-compat
        
        infoText "Propel - Converting configuration ..."
        # Write Propel2 configuration
        $CONSOLE propel:config:convert

        infoText "Propel - Build models ..."
        # Build Propel2 classes
        $CONSOLE propel:model:build

        infoText "Propel - Create database ..."
        # Create database if it does not already exist
        $CONSOLE propel:database:create
        
        infoText "Propel - Create schema diff ..."
        # Generate diff for Propel2
        $CONSOLE propel:diff

        infoText "Propel - Migrate Schema ..."
        # Migrate database
        $CONSOLE propel:migrate

        infoText "Propel - Initialize database ..."
        # Fill the database with required data
        $CONSOLE setup:init-db
        
        # Jenkins
        
        wait_for_service $JENKINS_HOST $JENKINS_PORT
        
        infoText "Jenkins - Register setup wide cronjobs ..."
        # FIXME [bug01] until the code of the following cronsole command completely
        # relies on API calls, we need to workaround the issue with missing local
        # jenkins job definitions.
        mkdir -p /tmp/jenkins/jobs
        # Generate Jenkins jobs configuration
        $CONSOLE setup:jenkins:generate
        
        # Customer hooks
        
        exec_hooks "$SHOP/docker/init.d/Shared"
        exec_hooks "$SHOP/docker/init.d/Zed"
        exec_hooks "$SHOP/docker/init.d/Yves"
        
        
        successText "Setup Initialization has been successfully FINISHED"
        
    ;;
    
    *)
        sh -c "$*"
        ;;
esac
