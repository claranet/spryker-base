#!/bin/sh

# Author: Tony Fahrion <tony.fahrion@de.clara.net>

#
# This script installs the nginx webserver
#


# include helper functions and common settings
source library.sh


# we are using more_clear_headers to remove client header
# see: https://github.com/openresty/headers-more-nginx-module
$apk_add nginx nginx-mod-http-headers-more

# remove default vhost config, if favour of our yves/zed vhosts
rm /etc/nginx/conf.d/default.conf

# create the required run dir to allow nginx to create its pid file
mkdir /run/nginx
