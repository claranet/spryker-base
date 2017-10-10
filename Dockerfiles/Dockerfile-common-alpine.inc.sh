#!/bin/bash
set -a

PREPARE=$(cat <<'EOF'
RUN apk add --no-cache \
        perl \
        bash \
    && mkdir -p /data/logs \
    && ln -vfs /bin/bash /bin/sh \
    && ln -vfs $WORKDIR/docker/entrypoint.sh /entrypoint.sh
EOF
)
