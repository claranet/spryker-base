#!/bin/sh

# This has been already implemented in the image build. But since in production
# these folder will very likely are being placed in an external volume, we need
# to recreate them on container bootstrap.

sectionText "Creating required directories"
mkdir -vp $WORKDIR/data/$SPRYKER_SHOP_CC/logs/ZED
chown -R www-data: $WORKDIR/data
mkdir -vp /data/logs
