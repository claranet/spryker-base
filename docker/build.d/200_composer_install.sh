#!/bin/sh


install_composer_dependencies() {
  #wait_for_service "php_install_composer"
  while ! test -e "/tmp/php_install_composer.task.finished"; do
    sectionNote "checking /tmp/php_install_composer.task.finished"
    sleep 1s
  done
  
  composer.phar install --ignore-platform-reqs --prefer-dist --dev
  composer.phar clear-cache # Clears composer's internal package cache
  
  touch /tmp/install_composer_dependencies.task.finished
}

add_stage_step one install_composer_dependencies
