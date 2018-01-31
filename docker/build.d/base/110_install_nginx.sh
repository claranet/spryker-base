#!/bin/sh

# we are using more_clear_headers to remove client header
# see: https://github.com/openresty/headers-more-nginx-module
install_packages nginx-common 
install_packages nginx-extras 
install_packages nginx

# remove default vhost config, if favour of our yves/zed vhosts
#rm /etc/nginx/conf.d/default.conf

# create the required run dir to allow nginx to create its pid file
mkdir /run/nginx
