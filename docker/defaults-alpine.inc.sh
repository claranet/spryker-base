#!/bin/sh

is_alpine || return 0

COMMON_BASE_DEPENDENCIES="$COMMON_BASE_DEPENDENCIES redis"
