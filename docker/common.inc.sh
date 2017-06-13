#!/bin/bash

set -e -o pipefail
export TERM=xterm

WORKDIR="${WORKDIR:-$PWD}"

# import default variables
source $WORKDIR/docker/defaults.inc.sh

# include custom build config on demand
[ -e "$WORKDIR/docker/build.conf" ] && source $WORKDIR/docker/build.conf

ERROR_BKG=';41m' # background red
GREEN_BKG=';42m' # background green
BLUE_BKG='\e[44m' # background blue
YELLOW_BKG='\e[43m' # background yellow
MAGENTA_BKG='\e[45m' # background magenta

INFO_TEXT='\033[33' # yellow text
WHITE_TEXT='\e[97m' # text white
BLACK_TEXT='\033[30' # text black
RED_TEXT='\033[31' # text red
MAGENTA_TEXT='\e[35m'
NC='\033[0m' # reset


debugHead() {
  echo -e "${WHITE_TEXT}${MAGENTA_BKG}$*${NC}\n"
  echo -e "$*\n" >> $BUILD_LOG
}

debugText() {
  echo -e "${MAGENTA_TEXT}$*${NC}\n"
  echo -e "$*\n" >> $BUILD_LOG
}

warnText() {
  echo -e "\n${BLACK_TEXT}${YELLOW_BKG}*** ${1} ***${NC}\n"
  echo -e "\n*** $1 ***\n" >> $BUILD_LOG
}

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

#
#  INIT helper functions
#
configure_jenkins() {
  sectionText "Configuring jenkins as the cronjob handler"
  
  wait_for_http_service http://$JENKINS_HOST:$JENKINS_PORT

  # FIXME [bug01] until the code of the following cronsole command completely
  # relies on API calls, we need to workaround the issue with missing local
  # jenkins job definitions.
  mkdir -p /tmp/jenkins/jobs
  # Generate Jenkins jobs configuration
  $CONSOLE setup:jenkins:generate
}

configure_crond() {
  sectionText "Configuring crond as the cronjob handler"
  php $WORKDIR/docker/contrib/gen_crontab.php
}


install_packages() {
  local INSTALL_FLAGS="--no-cache"
  if [ "$1" = "--build" ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS --virtual .build_deps"
    shift
  fi

  local PKG_LIST="$*"
  if [ -n "$PKG_LIST" ]; then
    sectionText "Installing package(s): $PKG_LIST"
    apk add $INSTALL_FLAGS $PKG_LIST >> $BUILD_LOG
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
    local available_scripts=`find $directory -type f -name '*.sh' -or -name '*.php' | sort`
    local scripts_count=`echo "$available_scripts" | wc -l`
    local scripts_counter=1

    echo $available_scripts | \
      tr ' ' '\n' | \
      xargs -I file basename file | \
      perl -n -e '/^(\d+)/ && do {$pfx=($1 ne $prev)?"\n":" "; $pfx="" unless $c; chomp($_); print "$pfx$_"; $prev=$1;$c++}; END { print "\n"}' | while read concurrent_scripts; do
      PIDS=""
      IFS=' ' read -r -a cscripts <<< "$concurrent_scripts"
      [ "${#cscripts[*]}X" != "1X" ] && MSG="concurrent "
      for f in ${cscripts[*]}; do
        file="$directory/$f"
        sectionHead "Executing ${MSG}build step ($scripts_counter/$scripts_count): $file"
        source $file &
        PIDS="$PIDS $!"
        let "scripts_counter += 1"
      done
      wait $PIDS
    done
  fi
}

# retries to connect to an remote address ($1) and port ($2) until the connection could be established
wait_for_tcp_service() {
  until nc -z $1 $2; do
    sectionText "Waiting for tcp://$1:$2 to come up ..."
    sleep 1
  done
  
  sectionText "Success: tcp://$1:$2 seems to be up, port is open"
}

# retries to connect to an remote address ($1) and port ($2) until the connection could be established
wait_for_http_service() {
  url=$1; shift
  until curl -s -k  $url -o /dev/null -L --fail $*; do
    sectionText "Waiting for $url to come up ..."
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


is_true() {
  local val="$1"
  case $val in 
    [yY][eE][sS]|[tT][rR][uU][eE]|1)
      return 0
      ;;
  esac
  return 1
}


skip_cleanup() {
  if is_true $SKIP_CLEANUP; then
    sectionText "WARNING: Skipping cleanup as requested by build.conf (!!!)"
    return 0
  fi
  return 1
}


start_timer() {
  varname=${1:-'total'}
  now=$(date +%s)
  eval "export $varname=$now"
  echo $now > "/var/cache/docker-build-timer-$varname-start"
}

stop_timer() {
  varname=${1:-'total'}
  start="$( (cat /var/cache/docker-build-timer-$varname-start || /bin/true) 2> /dev/null)"
  [ -z $start ] && return 0
  end=${2:-$(date +%s)}
  echo $end > "/var/cache/docker-build-timer-$varname-end"
  let 'diff=end-start'
  rm /var/cache/docker-build-timer-$varname-start /var/cache/docker-build-timer-$varname-end || /bin/true
  perl -e 'use Time::Piece; use Time::Seconds; print Time::Seconds->new($ARGV[0])->pretty;' $diff
}

print_timer() {
    MSG="${1:-'Time taken'}"
    DIFF=$(stop_timer $2)
    [ -n "$DIFF" ] &&  debugText "$MSG: $DIFF"
}

build_start() {
  start_timer
}

build_base_layer() {
  start_timer base
  chapterHead "Building Base Layer"
  exec_scripts "$WORKDIR/docker/build.d/base/"
  print_timer "\nBase Layer Build Time" "base"
}

build_deps_layer() {
  start_timer deps
  chapterHead "Building Dependency Layer"
  exec_scripts "$WORKDIR/docker/build.d/deps/"
  print_timer "\nDependencies Layer Build Time" "deps"
}

build_shop_layer() {
  start_timer shop
  chapterHead "Building Shop Layer"
  exec_scripts "$WORKDIR/docker/build.d/shop/"
  print_timer "\nShop Layer Build Time" "shop"
}

build_end() {
  skip_cleanup && warnText "Do not publish this image, since it might contain sensitive data due to SKIP_CLEANUP has been enabled"
  print_timer "\nTOTAL Build Time"
  successText "Image BUILD successfully FINISHED"
}

build_image() {
  build_start
  build_base_layer
  build_deps_layer
  build_shop_layer
  build_end
}


init() {
  start_timer init
  exec_scripts "$WORKDIR/docker/init.d/"
  print_timer "\nInitialization Time" "init"
  successText "Setup INITIALIZATION successfully FINISHED"
}


deploy() {
  start_timer deploy
  exec_scripts "$WORKDIR/docker/deploy.d/"
  print_timer "\nDeployment Time" "deploy"
  successText "DEPLOYMENT successfully FINISHED"
}
