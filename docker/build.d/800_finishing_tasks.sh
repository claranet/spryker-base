#!/bin/sh

# fix error with missing event log dir
# TODO: configure log destination to /data/logs/
sectionNote "create required directories for logs"
mkdir -p $WORKDIR/data/$SPRYKER_SHOP_CC/logs/

# TODO: increase security by making this more granular
sectionNote "fix owner properties for files within /data/"
chown -R www-data: /data/logs /data/shop/data
