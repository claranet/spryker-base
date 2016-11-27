#!/usr/bin/env bash

sed -e


if [ -n "$ETCD_NODE" ]; then
    confd -backend etcd -node ${ETCD_NODE} -prefix ${ETCD_PREFIX} -onetime
else
    confd -backend env -onetime
fi



case $1 in 
    init)
        # wait for depending services and then initialize redis, elasticsearch and postgres
        ;;
    run)
        /usr/bin/monit -d 10 -Ic /etc/monit/monitrc
        ;;
    *)
        bash -c "$*"
        ;;
esac
