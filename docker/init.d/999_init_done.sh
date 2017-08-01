#!/bin/sh

# Prevent concurrent execution of exports: Synchronize init, deploy and cron
# via redis

[ -n "$REDIS_STORAGE_PASSWORD" ] && export PASS="-a $REDIS_STORAGE_PASSWORD "
redis-cli -h $REDIS_STORAGE_HOST -p $REDIS_STORAGE_PORT $PASS SET init done
