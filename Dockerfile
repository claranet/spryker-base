
FROM ubuntu:trusty

MAINTAINER Fabian Dörk <fabian.doerk@de.clara.net>

RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y nginx nginx-extras php5-fpm monit

ADD etc/ /etc/
RUN mkdir -p /data/shop/public/Yves/ /data/shop/public/Zed/ /data/logs && \
    rm /etc/nginx/sites-enabled/default
COPY index.php /data/shop/public/Yves
COPY index.php /data/shop/public/Zed
RUN chown www-data: -R /data/

EXPOSE 80 8080

CMD  monit -d 10 -Ic /etc/monit/monitrc

ENV SPRYKER_SHOP_CC=DE 
ENV SPRYKER_APP_ENV=development

ENV ES_HOST=elastic
ENV ES_PORT=10000

ENV REDIS_HOST=redis
ENV REDIS_PORT=6379

ENV ZED_DB_USERNAME=postgres
ENV ZED_DB_PASSWORD=
ENV ZED_DB_DATABASE=spryker
ENV ZED_DB_HOST=db
ENV ZED_DB_PORT=5432

LABEL org.label-schema.name="spryker-base" \
      org.label-schema.description="Providing base infrastructure for a containerized spryker e-commerce application" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://git.eu.clara.net/de-docker-images/spryker.git"
