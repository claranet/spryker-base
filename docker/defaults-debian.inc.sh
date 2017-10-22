#!/bin/sh

is_debian || return 0

COMMON_BASE_DEPENDENCIES="$COMMON_BASE_DEPENDENCIES netcat curl redis-tools"
