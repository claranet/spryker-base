#!/bin/bash
set -a

PREPARE=$(cat <<'EOF'
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
         perl \
         bash \
    && rm -r /var/lib/apt/lists/* \
    && mkdir -p /data/logs \
    && ln -vfs /bin/bash /bin/sh \
    && ln -vfs $WORKDIR/docker/entrypoint.sh /entrypoint.sh
EOF
)
