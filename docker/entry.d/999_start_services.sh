#!/bin/sh

# launches an instance of nginx, php-fpm or crond
#   * nginx starts forked - if configtest fails, it will exit != 0 and therefor php-fpm won't start
#   * php-fpm starts unforked and remains in the forground
#   * crond will start only if init has been done (synchronized via redis)
#   * jenkins slave will start only if init has been done (synchronized via redis)

is_init_done() {
  [ -n "$REDIS_STORAGE_PASSWORD" ] && export PASS="-a $REDIS_STORAGE_PASSWORD "
  T=`redis-cli -h $REDIS_STORAGE_HOST -p $REDIS_STORAGE_PORT $PASS GET init`
  [ "$T" = "done" ] && return 0
  return 1
}

start_services() {
  sectionHead "Starting enabled services $ENABLED_SERVICES"

  if is_in_list "yves" "$ENABLED_SERVICES" || is_in_list "zed" "$ENABLED_SERVICES"; then
    # starts nginx daemonized to be able to start php-fpm in background
    # TODO: report to the user if nginx configtest fails
    nginx && php-fpm --nodaemonize

  elif is_in_list "crond" "$ENABLED_SERVICES"; then
    sectionText "Waiting for init to finish ..."
    retry 600 is_init_done
    crond -f -L /dev/stdout

  elif is_in_list "jenkins" "$ENABLED_SERVICES"; then
    sectionText "Waiting for init to finish ..."
    retry 600 is_init_done
    java -jar /usr/local/bin/jenkins-cli.jar -s $JENKINS_URL offline-node ""
    java -jar /usr/local/bin/jenkins-slave.jar -jnlpUrl $JENKINS_URL/computer/$JENKINS_SLAVE_NAME/slave-agent.jnlp &
    $CONSOLE setup:jenkins:generate
    wait
  fi
}

start_services
