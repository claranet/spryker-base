#!/bin/sh

cd $WORKDIR

wait_for_service $JENKINS_HOST $JENKINS_PORT

infoText "Jenkins - Register setup wide cronjobs ..."
# FIXME [bug01] until the code of the following cronsole command completely
# relies on API calls, we need to workaround the issue with missing local
# jenkins job definitions.
mkdir -p /tmp/jenkins/jobs
# Generate Jenkins jobs configuration
$CONSOLE setup:jenkins:generate
