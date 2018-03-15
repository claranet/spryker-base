#!/bin/sh

if is_in_list "jenkins" "$ENABLED_SERVICES"; then

  sectionText "Bootstrapping jenkins slave ..."
  install_java
  mkdir -p /data/shop/${APPLICATION_ENV}
  ln -fvs /data/shop /data/shop/${APPLICATION_ENV}/current
  ln -fvs /usr/local/bin/php /usr/bin/php

  sectionText "Waiting for jenkins master to be available ..."
  wait_for_http_service $JENKINS_URL
  retry 60 curl -s $JENKINS_URL/jnlpJars/jenkins-cli.jar -o /usr/local/bin/jenkins-cli.jar
  retry 60 curl -s $JENKINS_URL/jnlpJars/slave.jar -o /usr/local/bin/jenkins-slave.jar

  (java -jar /usr/local/bin/jenkins-cli.jar -s $JENKINS_URL get-node $JENKINS_SLAVE_NAME 2>&1 || true ) > /tmp/jenkins.node
  if grep ERROR: /tmp/jenkins.node >/dev/null; then
    sectionText "Registering jenkins slave $JENKINS_SLAVE_NAME at master ... "
    cat <<EOF | java -jar /usr/local/bin/jenkins-cli.jar -s $JENKINS_URL create-node $JENKINS_SLAVE_NAME
        <slave>
          <name>backend</name>
          <description></description>
          <remoteFS>/data/shop</remoteFS>
          <numExecutors>1</numExecutors>
          <mode>NORMAL</mode>
          <retentionStrategy class="hudson.slaves.RetentionStrategy$Always"/>
          <launcher class="hudson.slaves.JNLPLauncher"/>
          <label>backend</label>
          <nodeProperties/>
        </slave>
EOF
    else
        sectionText "Already registered as jenkins slave $JENKINS_SLAVE_NAME:"
        cat /tmp/jenkins.node
    fi

fi

return 0
