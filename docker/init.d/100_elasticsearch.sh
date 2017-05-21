#!/bin/sh

cd $WORKDIR

wait_for_http_service http://$ES_HOST:$ES_PORT/_cluster/health
$CONSOLE setup:search
