#!/bin/sh

if is_in_list "cron" "$ENABLED_SERVICES"; then
  sectionText "Configuring crond as the cronjob handler"
  php $WORKDIR/docker/contrib/gen_crontab.php
fi

return 0
