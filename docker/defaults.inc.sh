#!/bin/sh

#
#  General
#

APPLICATION_ENV="production"
DEV_TOOLS="off"

# build log location
BUILD_LOG=/data/logs/build.log


#
#  NodeJS defaults
#

SUPPORTED_NODEJS_VERSIONS='6 7'
SUPPORTED_NODEJS_PACKAGE_MANAGER='npm yarn'


NODEJS_VERSION="6" # nodejs major 6 or 7 are supported
NPM=npm            # npm or yarn are supported

NPM_DEPENDENCIES="" # specify os package dependencies from npm modules


#
#  PHP defaults
#

# a list of common PHP extensions required to run a spryker shop... so you don't have to
# specify them within every shop implementation.
COMMON_PHP_EXTENSIONS="bcmath bz2 gd gmp intl mcrypt redis"

# pecl extensions
PHP_EXTENSION_IMAGICK="3.4.3"
PHP_EXTENSION_REDIS="3.1.2"

# NGINX: we are using more_clear_headers to remove client header
#        see: https://github.com/openresty/headers-more-nginx-module
BASE_PACKAGES="nginx nginx-mod-http-headers-more libpng libjpeg-turbo freetype \
    readline libedit \
    libintl icu-libs \
    postgresql-dev \
    libxml2 gmp libmcrypt libcurl bzip2 \
    postgresql-client"

BUILD_PACKAGES="ccache autoconf file g++ gcc libc-dev make pkgconf git redis freetype-dev \
      libjpeg-turbo-dev \
      libmcrypt-dev \
      libpng-dev \
      bzip2-dev curl-dev libxml2-dev libmcrypt-dev gmp-dev icu-dev readline-dev zlib-dev libedit-dev re2c"

# each step in the same STAGE will be executed in parallel
# each STAGE will wait with execution their scripts until the previouse STAGE
# has finished all its tasks.
# FINISHING_TASKS will be executed sequentialy after all STAGES are done
#
# IMPORTANT: STAGES only handle build tasks!
STAGE_ONE=""
STAGE_TWO=""
STAGE_THREE=""
FINISHING_TASKS=""
