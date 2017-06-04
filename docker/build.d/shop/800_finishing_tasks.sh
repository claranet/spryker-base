#!/bin/sh

# fix error with missing event log dir
# TODO: configure log destination to /data/logs/
sectionText "Creating required directories"
mkdir -vp $WORKDIR/data/$SPRYKER_SHOP_CC/logs/ZED
mkdir -vp /data/logs

# TODO: increase security by making this more granular
sectionText "Fixing owner properties for files within /data/"
chown -R www-data: /data/logs $WORKDIR/data
