#!/bin/sh

# propel data imports are generating log files as root, let www-data rw access them
chown -R www-data: $WORKDIR/data/DE/logs
