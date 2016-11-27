
FROM ubuntu:trusty

MAINTAINER Fabian Dörk <fabian.doerk@de.clara.net>


ENV SPRYKER_SHOP_CC=DE 
ENV SPRYKER_APP_ENV=development

ENV ES_HOST=elastic
ENV ES_PORT=10000

ENV SHOP_REDIS_HOST=redis
ENV SHOP_REDIS_PORT=6379
ENV SHOP_REDIS_USER=
ENV SHOP_REDIS_PASS=

ENV SESSION_REDIS_HOST=redis
ENV SESSION_REDIS_PORT=6379
ENV SESSION_REDIS_USER=
ENV SESSION_REDIS_PASS=

ENV ZED_DB_USERNAME=postgres
ENV ZED_DB_PASSWORD=
ENV ZED_DB_DATABASE=spryker
ENV ZED_DB_HOST=db
ENV ZED_DB_PORT=5432


RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y nginx nginx-extras php5-fpm monit && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /data/shop/public/Yves/ /data/shop/public/Zed/ /data/logs && \
    rm /etc/nginx/sites-enabled/default

ADD etc/ /etc/
ADD https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 /usr/bin/confd
COPY index.php /data/shop/public/Yves
COPY index.php /data/shop/public/Zed
COPY entrypoint.sh /

RUN chown www-data: -R /data/ && \
    chmod 755 /usr/bin/confd

EXPOSE 80 8080

WORKDIR /data/shop/
ENTRYPOINT [ "/entrypoint.sh" ]
CMD  [ "run" ]

LABEL org.label-schema.name="spryker-base" \
      org.label-schema.description="Providing base infrastructure for a containerized spryker e-commerce application" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://git.eu.clara.net/de-docker-images/spryker.git"
