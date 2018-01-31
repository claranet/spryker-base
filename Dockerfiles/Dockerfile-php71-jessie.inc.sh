#!/bin/bash
set -a
source Dockerfile-common.inc.sh
source Dockerfile-common-debian.inc.sh

FROM="FROM php:7.1.13-fpm-jessie"
