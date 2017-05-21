#!/bin/sh

set -e -o pipefail
export TERM=xterm

# import default variables
source $WORKDIR/docker/defaults.inc.sh

# include custom build config on demand
[ -e "$WORKDIR/docker/build.conf" ] && source $WORKDIR/docker/build.conf

ERROR_BKG=';41m' # background red
GREEN_BKG=';42m' # background green
BLUE_BKG='\e[44m' # background blue
YELLOW_BKG=';43m' # background yellow
MAGENTA_BKG=';45m' # background magenta

INFO_TEXT='\033[33' # yellow text
WHITE_TEXT='\e[97m' # text white
BLACK_TEXT='\033[30' # text black
RED_TEXT='\033[31' # text red
NC='\033[0m' # reset

errorText() {
  echo -e "\n${WHITE_TEXT}${ERROR_BKG}!!! ${1} !!!${NC}\n"
  echo -e "\n!!! $1 !!!\n" >> $BUILD_LOG
}

successText() {
  echo -e "\n${BLACK_TEXT}${GREEN_BKG}=> ${1} <=${NC}\n"
  echo -e "SUCCESS: $1" >> $BUILD_LOG
}

chapterHead() {
  echo -e "\n${BLUE_BKG}${WHITE_TEXT}::: ${1} :::${NC}\n"
  echo -e "\n::: $1 :::\n" >> $BUILD_LOG
}

sectionHead() {
  echo -e "\n${INFO_TEXT}m===> ${1} <===${NC}\n"
  echo -e "\n==> $1" >> $BUILD_LOG
}

sectionText() {
  echo -e "${INFO_TEXT}m-> ${1}${NC}"
  echo -e "-> $1" >> $BUILD_LOG
}

writeErrorMessage() {
  if [[ $? != 0 ]]; then
    errorText "${1}"
    errorText "Command FAILED"
    exit 1
  fi
}

# arguments: $1 (build|run) $2...x packages to be installed
install_packages() {
  local PKG_LIST="$*"
  
  local INSTALL_FLAGS="--no-cache"
  if [ "$1" = "--build" ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS --virtual .build_deps"
    PKG_LIST=`echo "$PKG_LIST" | sed 's/--build //'` # just drop the first element, which is "build"
  fi
  
  sectionText "Installing package(s): $PKG_LIST"
  apk add $INSTALL_FLAGS $PKG_LIST >> $BUILD_LOG
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
  
  sectionText "Enabling nginx vhost $VHOST"
  ln -fs $NGINX_SITES_AVAILABLE/$VHOST $NGINX_SITES_ENABLED/${VHOST}.conf
}

# force setting a symlink from php-fpm/apps-available to php-fpm/pool.d if app file exists
enable_phpfpm_app() {
  local FPM_APPS_AVAILABLE="/etc/php/apps"
  local FPM_APPS_ENABLED="/usr/local/etc/php-fpm.d"
  
  local APP="${1}.conf"
  if [ ! -e $FPM_APPS_AVAILABLE/$APP ]; then
    errorText "\t php-fpm app '$APP' not found! Can't enable app!"
    return
  fi
  
  sectionText "Enabling php-fpm config for $1"
  ln -fs $FPM_APPS_AVAILABLE/$APP $FPM_APPS_ENABLED/$APP
}

# activates zed and/or yves instance, based the value of $ENABLED_SERVICES
enable_services() {
  for SERVICE in $ENABLED_SERVICES; do
    sectionHead "Enable ${SERVICE} vHost and PHP-FPM app"
    
    enable_nginx_vhost ${SERVICE}
    enable_phpfpm_app ${SERVICE}
    
  done
}

# launches an instance of nginx and php-fpm
# nginx starts forked - if configtest fails, it will exit != 0 and therefor php-fpm won't start
# php-fpm starts unforked and remains in the forground
start_services() {
  sectionHead "Starting enabled services $ENABLED_SERVICES"
  
  # starts nginx daemonized to be able to start php-fpm in background
  # TODO: report to the user if nginx configtest fails
  nginx && php-fpm --nodaemonize
}

exec_console() {
  sectionText "Executing 'console $@'"
  vendor/bin/console $@
}

# uses the find & sort to select scripts in lexical order (alpine doesn't support `find -s`)
# sources those scripts to make build.conf and defaults.inc.sh vars available to them
exec_scripts() {
  local directory=$1
  
  if [ -d "$directory" ]; then
    
    # provide script counting to inform the user about how many steps are available
    local available_scripts=`find $directory -type f -name '*.sh' | sort`
    local scripts_count=`echo "$available_scripts" | wc -l`
    local scripts_counter=1
    
    for f in $available_scripts; do
      local script_name=`basename $f`
      
      sectionHead "Executing build step ($scripts_counter/$scripts_count): $script_name"
      cd $WORKDIR # ensure we are starting within $WORKDIR for all scripts
      source $f
      
      let "scripts_counter += 1"
    done
    
  fi
}

# retries to connect to an remote address ($1) and port ($2) until the connection could be established
wait_for_tcp_service() {
  sectionHead "Waiting for $1 to come up"
  until nc -z $1 $2; do
    sectionText "Waiting for tcp://$1:$2..."
    sleep 1
  done
  
  sectionText "Success: tcp://$1:$2 seems to be up, port is open"
}

# retries to connect to an remote address ($1) and port ($2) until the connection could be established
wait_for_http_service() {
  url=$1; shift
  sectionHead "Waiting for $url to come up"
  until curl -s -k  $url -o /dev/null -L --fail $*; do
    sectionText "Waiting for $url ..."
    sleep 1
  done
  
  sectionText "Success: $1 seems to be up and running"
}


# checks if the given value exists in the list (space separated string recommended)
# parameter $1 => value, $2 => string, used in "for in do done"
is_in_list() {
  local VALUE="$1"
  local LIST="$2"
  
  for i in $LIST; do
    if [ "$VALUE" = "$i" ]; then
      return 0
    fi
  done
  
  return 1
}
