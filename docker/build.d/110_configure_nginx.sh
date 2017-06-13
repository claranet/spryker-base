#!/bin/sh

#
# Configures the nginx webserver
#

stage_one_configure_nginx() {
  # remove default vhost config, if favour of our yves/zed vhosts
  rm /etc/nginx/conf.d/default.conf

  # create the required run dir to allow nginx to create its pid file
  mkdir /run/nginx
}

add_stage_step one stage_one_configure_nginx
