#!/bin/sh

cd $WORKDIR

wait_for_service $ES_HOST $ES_PORT
$CONSOLE setup:search
