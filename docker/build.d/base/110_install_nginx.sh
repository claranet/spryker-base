#!/bin/sh

# we are using more_clear_headers to remove client header
# see: https://github.com/openresty/headers-more-nginx-module
#install_packages nginx nginx-mod-http-headers-more
install_packages nginx nginx-common nginx-extras

# remove default vhost config, if favour of our yves/zed vhosts
rm -f /etc/nginx/sites-enabled/*

# create the required run dir to allow nginx to create its pid file
#mkdir /run/nginx
