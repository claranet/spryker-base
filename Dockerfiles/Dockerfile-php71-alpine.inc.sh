#!/bin/bash
set -a
source Dockerfile-common.inc.sh
source Dockerfile-common-alpine.inc.sh

FROM="FROM php:7.1.10-fpm-alpine"
