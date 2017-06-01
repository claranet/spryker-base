#!/bin/sh

# check if we support the CRONJOB_HANDLER
if ! is_in_list "$CRONJOB_HANDLER" "jenkins crond"; then
  errorText "got unknown CRONJOB_HANDLER (allowed: jenkins or crond): $CRONJOB_HANDLER"
fi


# only handle jenkins here... crond will be handled by "/entrypoint.sh run-crond"
if [ "$CRONJOB_HANDLER" == "jenkins" ]; then
  configure_jenkins
fi
