#!/bin/sh

# launches an instance of nginx and php-fpm
# nginx starts forked - if configtest fails, it will exit != 0 and therefor php-fpm won't start
# php-fpm starts unforked and remains in the forground
start_services() {
  sectionHead "Starting enabled services $ENABLED_SERVICES"

  if is_in_list "yves" "$ENABLED_SERVICES" || is_in_list "zed" "$ENABLED_SERVICES"; then
    # starts nginx daemonized to be able to start php-fpm in background
    # TODO: report to the user if nginx configtest fails
    nginx && php-fpm --nodaemonize

  elif is_in_list "crond" "$ENABLED_SERVICES"; then
      crond -f -L /dev/stdout
  fi
}

start_services
