#!/bin/sh

configure_jenkins() {
  sectionText "Configuring jenkins as the cronjob handler"

  wait_for_http_service http://$JENKINS_HOST:$JENKINS_PORT

  # FIXME [bug01] until the code of the following cronsole command completely
  # relies on API calls, we need to workaround the issue with missing local
  # jenkins job definitions.
  mkdir -p /tmp/jenkins/jobs
  # Generate Jenkins jobs configuration
  $CONSOLE setup:jenkins:generate
}

# check if we support the CRONJOB_HANDLER
if ! is_in_list "$CRONJOB_HANDLER" "jenkins crond"; then
  errorText "got unknown CRONJOB_HANDLER (allowed: jenkins or crond): $CRONJOB_HANDLER"
fi


# only handle jenkins here... crond will be handled by "/entrypoint.sh run-crond"
if [ "$CRONJOB_HANDLER" == "jenkins" ]; then
  configure_jenkins
fi
