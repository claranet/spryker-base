#!/bin/sh

if is_in_list "crond" "$ENABLED_SERVICES"; then
  sectionText "Generating crontab"
  php $WORKDIR/docker/contrib/gen_crontab.php
fi

return 0
