#!/bin/sh

#get amount of available prozessors * 2 for faster compiling of sources
COMPILE_JOBS=$((`getconf _NPROCESSORS_ONLN`*2))

KEEP_DEVEL_TOOLS=false
SKIP_CLEANUP=false

# Rebuild the base layer in the downstream shop image to override
# claranet/spryker-base
REBUILD_BASE_LAYER=false

# log destinations
BUILD_LOG=/data/logs/build.log

# Packages installed temporarily during build time (base and deps layer)
COMMON_BUILD_DEPENDENCIES="ccache autoconf file g++ gcc libc-dev make pkgconf bash"
BUILD_DEPENDENCIES=""

# Base dependencies to be installed
COMMON_BASE_DEPENDENCIES="perl graphviz"
BASE_DEPENDENCIES=""

#  NodeJS defaults
NODEJS_VERSION="6" # nodejs major 6 or 7 are supported
NPM=npm            # npm or yarn are supported

#  PHP defaults
# pecl extensions
PHP_EXTENSION_IMAGICK="3.4.3"
PHP_EXTENSION_REDIS="3.1.2"
PHP_EXTENSION_XDEBUG="2.5.4"

CONSOLE="exec_console"

# a list of common PHP extensions required to run a spryker shop
COMMON_PHP_EXTENSIONS="bcmath bz2 gd gmp intl mcrypt redis xdebug opcache pdo_pgsql pgsql"
PHP_EXTENSIONS=""

# crond is the only allowed cronjob handler until we got a solution for jenkins too
# crond might be dropped then, so please don't rely on "crond" in your shop flavour!
CRONJOB_HANDLER="crond"

#  Codeception tests
CODECEPTION_RUN_CMD="vendor/bin/codecept run"

# This is for test groups to be ignored by codeception
# To mark a test to be ignored, add '-x TEST_GROUP'.
# This command allows multiple ignores, adding a '-x TEST_GROUP' for each test group to be ignored
CODECEPTION_IGNORED_GROUPS=""
