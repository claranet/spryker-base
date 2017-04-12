
FROM php:7.0-fpm-alpine


# NOTE: to get a list of possible build args,
#       run `egrep 'ARG ' Dockerfile`


# see http://label-schema.org/rc1/
LABEL org.label-schema.name="spryker-base" \
      org.label-schema.version="1.0" \
      org.label-schema.description="Providing base infrastructure for a containerized spryker e-commerce application" \
      org.label-schema.vendor="Claranet GmbH" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-url="https://git.eu.clara.net/de-docker-images/spryker.git" \
      maintainer="Fabian Dörk <fabian.doerk@de.clara.net>" \
      co_author="Tony Fahrion <tony.fahrion@de.clara.net>"


# Spryker config related ENV vars
ENV SPRYKER_SHOP_CC="DE" \
    ZED_HOST="zed" \
    PUBLIC_ZED_DOMAIN="zed.spryker.dev" \
    YVES_HOST="yves" \
    PUBLIC_YVES_DOMAIN="yves.spryker.dev" \
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
    JENKINS_BASEURL="http://jenkins:8080/"


# install basic packages
# bash is installed as current shell scripts are using bash syntactic sugar
# so it is required until they are rewritten.
RUN apk add --no-cache nginx \
      monit \
      git \
      bash


# copy image data and prepare image filesystem structure

# copy prepared config files
COPY etc/ /etc/
RUN mkdir -pv /data/logs /data/bin /data/etc /data/shop
ENV PATH="/data/bin/:$PATH"

# make bash default shell for better syntax support
RUN ln -fs /bin/bash /bin/sh

# copy our command and container entrypoint script
# also add docker build helper scripts
COPY entrypoint.sh functions.sh build/* /data/bin/
RUN chmod +x /data/bin/*


# fix wrong permissions of monitrc, else monit will refuse to run
# and remove nginx default vhost
RUN chmod 0700 /etc/monit/monitrc


EXPOSE 80

WORKDIR /data/shop/
ENTRYPOINT [ "/data/bin/entrypoint.sh" ]

# on default, start yves and zed in one container
CMD  [ "run_yves_and_zed" ]


#
# all onbuild commands will be executed before a child image gets build.
# 
# 


# ops mode defines the mode while building docker images... it does NOT control
# in which ENV the application is installed.
# supported vaules are (dev/prod), defaults to "prod"
ONBUILD ARG OPS_MODE
ONBUILD ENV OPS_MODE=${OPS_MODE:-prod}

# application env decides in which mode the application is installed/runned.
# so if you choose development here, e.g. composer and npm/yarn will also install
# dev dependencies! There are more modifications, which depend on this switch.
# defaults to "production"
ONBUILD ARG APPLICATION_ENV
ONBUILD ENV APPLICATION_ENV=${APPLICATION_ENV:-production}

# support PHP_VERSION as ARG to support an easy way to build multiple flavors
# of your image (one for e.g. 5.6 and one for 7.0)
# This is especially useful while in OPS_MODE=dev! Or for OPS tests.
ONBUILD ARG PHP_VERSION
ONBUILD ENV PHP_VERSION=${PHP_VERSION:-7.0}

# support NODEJS_VERSION as ARG for the same reason we support PHP_VERSION
ONBUILD ARG NODEJS_VERSION
ONBUILD ENV NODEJS_VERSION=${NODEJS_VERSION:-6}

# support different nodejs package managers, as spryker supports npm and yarn!
ONBUILD ARG NODEJS_PACKAGE_MANAGER
ONBUILD ENV NODEJS_PACKAGE_MANAGER=${NODEJS_PACKAGE_MANAGER:-npm}


# via PHP_VERSION you can control which PHP version you need. Version 7.0 is default
# via NODEJS_VERSION you can control which nodejs version you need. Version 6 (LTS) is default
ONBUILD RUN cd /data/bin/ && ./install_php.sh
ONBUILD RUN cd /data/bin/ && ./install_nodejs.sh


ONBUILD COPY ./src /data/shop/src
ONBUILD COPY ./config /data/shop/config
ONBUILD COPY ./public /data/shop/public
ONBUILD COPY ./docker /data/shop/docker
ONBUILD COPY ./package.json ./composer.json /data/shop/

# 
ONBUILD RUN  /data/bin/entrypoint.sh build_image

# install ops tools while in debugging and testing stage
ONBUILD RUN [ "$OPS_MODE" == "prod" ] || apk add --no-cache \
      vim \
      less \
      tree
