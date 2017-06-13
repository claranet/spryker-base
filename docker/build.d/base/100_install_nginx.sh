#!/bin/sh

# we are using more_clear_headers to remove client header
# see: https://github.com/openresty/headers-more-nginx-module
install_packages nginx nginx-mod-http-headers-more

# remove default vhost config, if favour of our yves/zed vhosts
[ -e /etc/nginx/conf.d/default.conf ] && rm /etc/nginx/conf.d/default.conf

# create the required run dir to allow nginx to create its pid file
mkdir -p /run/nginx
