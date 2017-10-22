#!/bin/sh

# * We are using more_clear_headers to remove client header
#   see: https://github.com/openresty/headers-more-nginx-module
# * Remove default vhost config, if favour of our yves/zed vhosts

if is_alpine; then
  install_packages nginx nginx-mod-http-headers-more
  rm -f /etc/nginx/conf.d/default.conf

  # create the required run dir to allow nginx to create its pid file
  mkdir /run/nginx

elif is_debian; then
  install_packages nginx nginx-common nginx-extras
fi


