
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


ENV PHP_VERSION=7.0 \
    WORKDIR=/data/shop

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


COPY etc/ /etc/
COPY entrypoint.sh functions.sh build/* /data/bin/


# first start with an upgrade to alpine 3.5 as we need some nginx packages which are only available in alpine >3.5
# install basic packages
# bash is installed as current shell scripts are using bash syntactic sugar
# so it is required until they are rewritten.
RUN sed -i -e 's/3\.4/3.5/g' /etc/apk/repositories && apk update && apk upgrade \
    && apk add monit git \
    
    # fix wrong permissions of monitrc, else monit will refuse to run
    && chmod 0700 /etc/monit/monitrc \
    
    # our own copied scripts
    && chmod +x /data/bin/* \
    
    # create required shop directories
    && mkdir -pv /data/logs /data/bin /data/etc /data/shop
    


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

# application env decides in which mode the application is installed/runned.
# so if you choose development here, e.g. composer and npm/yarn will also install
# dev dependencies! There are more modifications, which depend on this switch.
# defaults to "production"

# support NODEJS_VERSION as ARG for the same reason we support PHP_VERSION
# NODEJS_PACKAGE_MANAGER: you can, additionally to npm, install yarn; if you select yarn here
# also, if yarn is selected, it would be used while running the base installation
ONBUILD ARG OPS_MODE
ONBUILD ARG APPLICATION_ENV
ONBUILD ARG NODEJS_VERSION
ONBUILD ARG NODEJS_PACKAGE_MANAGER


ONBUILD ENV OPS_MODE=${OPS_MODE:-production} \
            APPLICATION_ENV=${APPLICATION_ENV:-production} \
            NODEJS_VERSION=${NODEJS_VERSION:-6} \
            NODEJS_PACKAGE_MANAGER=${NODEJS_PACKAGE_MANAGER:-npm}


ONBUILD COPY ./src /data/shop/src
ONBUILD COPY ./config /data/shop/config
ONBUILD COPY ./public /data/shop/public
ONBUILD COPY ./docker /data/shop/docker
ONBUILD COPY ./package.json ./composer.json /data/shop/


# use ccache to decrease compile times
ONBUILD RUN apk add ccache \
            && cd /data/bin/ && ./install_php.sh \
            && ./install_nodejs.sh \
            && ./install_nginx.sh \
            && ./entrypoint.sh build_image \
            
            # install ops tools while in debugging and testing stage
            && [ "$OPS_MODE" = "production" ] || apk add --no-cache \
                  vim \
                  less \
                  tree \
            
            # clean up if in production mode
            && [ "$OPS_MODE" = "development" ] || apk del ccache
