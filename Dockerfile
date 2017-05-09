
FROM php:7.0.17-fpm-alpine

# see http://label-schema.org/rc1/
LABEL org.label-schema.name="spryker-base" \
      org.label-schema.version="0.6.0" \
      org.label-schema.description="Providing base infrastructure for a containerized Spryker Commerce Framework based Shop" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://github.com/claranet/spryker-base" \
      author1="Fabian Dörk <fabian.doerk@de.clara.net>" \
      author2="Tony Fahrion <tony.fahrion@de.clara.net>"

ENV WORKDIR=/data/shop

# Reference of spryker config related ENV vars
ENV SPRYKER_SHOP_CC="DE" \
    ZED_HOST="zed" \
    YVES_HOST="yves" \
    ES_HOST="elasticsearch" \
    ES_PROTOCOL="http" \
    ES_PORT="9200" \
    REDIS_STORAGE_HOST="redis" \
    REDIS_STORAGE_PORT="6379" \
    REDIS_STORAGE_PASSWORD="" \
    REDIS_SESSION_HOST="redis" \
    REDIS_SESSION_PORT="6379" \
    REDIS_SESSION_PASSWORD="" \
    ZED_DB_USERNAME="postgres" \
    ZED_DB_PASSWORD="" \
    ZED_DB_DATABASE="spryker" \
    ZED_DB_HOST="database" \
    ZED_DB_PORT="5432" \
    JENKINS_HOST="jenkins" \
    JENKINS_PORT="8080"


COPY etc/ /etc/
COPY docker $WORKDIR/docker
COPY entrypoint.sh /usr/bin/

EXPOSE 80

WORKDIR $WORKDIR
ENTRYPOINT [ "entrypoint.sh" ]

CMD  [ "run_yves_and_zed" ]

ONBUILD ARG DEV_TOOLS=off

ONBUILD ARG APPLICATION_ENV
ONBUILD ENV APPLICATION_ENV=${APPLICATION_ENV:-production}

# You need to maintain a .dockerignore file!
ONBUILD COPY . $WORKDIR

ONBUILD RUN entrypoint.sh build
