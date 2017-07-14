#!/bin/sh

NGINX_SITES_AVAILABLE='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
FPM_APPS_AVAILABLE="/etc/php/fpm"
FPM_APPS_ENABLED="/usr/local/etc/php-fpm.d"


# force setting a symlink from sites-available to sites-enabled if vhost file exists
enable_nginx_vhost() {
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
  for SERVICE in $(echo $ENABLED_SERVICES | egrep 'yves|zed'); do
    enable_nginx_vhost ${SERVICE}
    enable_phpfpm_app ${SERVICE}
    
  done
}


clean_service_dirs() {
    rm -f $NGINX_SITES_ENABLED/*
    rm -f $FPM_APPS_ENABLED/*
}

clean_service_dirs
enable_services

return 0
