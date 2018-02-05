#!/bin/sh

# we are using more_clear_headers to remove client header
# see: https://github.com/openresty/headers-more-nginx-module
install_packages nginx-common nginx-extras nginx

# remove default nginx configuration
rm /etc/nginx/sites-enabled/default

# create the required run dir to allow nginx to create its pid file
mkdir /run/nginx
