#!/bin/sh

# Author: Tony Fahrion <tony.fahrion@de.clara.net>

#
# This script installs the nginx webserver
#

# shortcut for apk add
apk_add='apk add --no-cache'


# include helper functions
source functions.sh

# include custom build config on demand
if [[ -e "$WORKDIR/docker/build.conf" ]]; then
  source "$WORKDIR/docker/build.conf"
fi

# abort on error
set -e


# we are using more_clear_headers to remove client header
# see: https://github.com/openresty/headers-more-nginx-module
$apk_add nginx nginx-mod-http-headers-more
