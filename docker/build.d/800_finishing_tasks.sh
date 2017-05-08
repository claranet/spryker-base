#!/bin/sh

# fix error with missing event log dir
# TODO: configure log destination to /data/logs/
mkdir -p /data/logs $WORKDIR/data/$SPRYKER_SHOP_CC/logs/

# TODO: increase security by making this more granular
chown -R www-data: /data/logs /data/shop/data
