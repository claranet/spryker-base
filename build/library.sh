#!/bin/sh

# abort on first error
set -e -o pipefail


export TERM=xterm 

# make modifying parameters easy by a central apk add command
apk_add='apk add'


# include custom build config on demand
[ -e "$WORKDIR/docker/build.conf" ] && source $WORKDIR/docker/build.conf


NPM=${NODEJS_PACKAGE_MANAGER:-npm}

ERROR_BKG=';41m' # background red
GREEN_BKG=';42m' # background green
BLUE_BKG=';44m' # background blue
YELLOW_BKG=';43m' # background yellow
MAGENTA_BKG=';45m' # background magenta

INFO_TEXT='\033[33' # yellow text
WHITE_TEXT='\033[37' # text white
BLACK_TEXT='\033[30' # text black
RED_TEXT='\033[31' # text red
NC='\033[0m' # reset


labelText() {
    echo -e "\n${WHITE_TEXT}${BLUE_BKG}-> ${1} ${NC}\n"
}

errorText() {
    echo -e "\n${WHITE_TEXT}${ERROR_BKG}=> ${1} <=${NC}\n"
}

infoText() {
    echo -e "\n${INFO_TEXT}m=> ${1} <=${NC}\n"
}

successText() {
    echo -e "\n${BLACK_TEXT}${GREEN_BKG}=> ${1} <=${NC}\n"
}

warningText() {
    echo -e "\n${RED_TEXT}${YELLOW_BKG}=> ${1} <=${NC}\n"
}

setupText() {
    echo -e "\n${WHITE_TEXT}${MAGENTA_BKG}=> ${1} <=${NC}\n"
}

writeErrorMessage() {
    if [[ $? != 0 ]]; then
        errorText "${1}"
        errorText "Command unsuccessful"
        exit 1
    fi
}


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


# activates zed and/or yves instance, based the value of $ENABLED_SERVICES
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


# launches an instance of nginx and php-fpm
# nginx starts forked - if configtest fails, it will exit != 0 and therefor php-fpm won't start
# php-fpm starts unforked and remains in the forground
start_services() {
  labelText "Starting enabled services $ENABLED_SERVICES"
  
  # fix error with missing event log dir
  # TODO: configure log destination to /data/logs/
  mkdir -p /data/shop/data/$SPRYKER_SHOP_CC/logs/
  
  # TODO: increase security by making this more granular
  chown -R www-data: /data/logs /data/shop
  
  # starts nginx daemonized to be able to start php-fpm in background
  # TODO: report to the user if nginx configtest fails
  nginx && php-fpm --nodaemonize
}

# short wrapper for projects "console" executeable
execute_console_command() {
  infoText "execute 'console $@'"
  vendor/bin/console $@
}

# uses the find command to select scripts in lexical order
# sources those scripts to make library.sh and other vars available to them
execute_scripts_within_directory() {
  local directory=$1
  
  if [ -d "$directory" ]; then
    
    # provide script counting to inform the user about how many steps are available
    local available_scripts=`find $directory -type f -name '*.sh' -s`
    local scripts_count=`echo "$available_scripts" | wc -l`
    local i=1
    
    for f in $available_scripts; do
      local script_name=`basename $f`
      
      infoText "Executing script ($i of $scripts_count) : $script_name"
      source $f
      
      let "i += 1"
    done
    
  fi
}


# retries to connect to an remote address ($1) and port ($2) until the connection could be established
wait_for_service() {
  until nc -z $1 $2; do
    echo "waiting for $1 to come up..."
    sleep 1
  done
  
  echo "$1 seems to be up, port is open"
}


# checks if the given value exists in the list (space separated string recommended)
# parameter $1 => value, $2 => string, used in "for in do done"
is_in_list() {
  local VALUE="$1"
  local LIST="$2"
  
  for i in $LIST; do
    if [ "$VALUE" == "$i" ]; then
      return 0
    fi
  done
  
  return 1
}

# the opposit of is_in_list
is_not_in_list() {
  if is_in_list "$1" "$2"; then
    return 1
  else
    return 0
  fi
}
