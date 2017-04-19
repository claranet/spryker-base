
# stuck on 7.0.17 as 7.0.18 breaks spryker predis usage
# see https://github.com/php/php-src/commit/bab0b99f376dac9170ac81382a5ed526938d595a for details
# php bug report: https://bugs.php.net/bug.php?id=74429
FROM php:7.0.17-fpm-alpine


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


ENV WORKDIR=/data/shop

# Spryker config related ENV vars
# ENV configs for ZED_HOST and YVES_HOST should be set by child Dockerfiles, or left to default
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
    JENKINS_BASEURL="http://jenkins:8080/"


COPY etc/ /etc/
COPY entrypoint.sh functions.sh build/* /data/bin/


# first start with an upgrade to alpine 3.5 as we need some nginx packages which are only available in alpine >3.5
# `apk upgrade --clean-protected` for not creating *.apk-new (config)files
# install basic packages
# bash is installed as current shell scripts are using bash syntactic sugar
# so it is required until they are rewritten.
RUN sed -i -e 's/3\.4/3.5/g' /etc/apk/repositories && apk update && apk upgrade --clean-protected \
    && apk add git \
    
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

# support NODEJS_VERSION as ARG to let the user switch between nodejs 6.x and 7.x
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
ONBUILD RUN apk add --virtual .base_build_deps ccache autoconf file g++ gcc libc-dev make pkgconf \
            
            # add psql command, should be removed later on... this should be done in an init task or externally!
            && apk add postgresql-client \
            
            && cd /data/bin/ && ./install_php.sh \
            && ./install_nodejs.sh \
            && ./install_nginx.sh \
            && ./entrypoint.sh build_image \
            
            # install ops tools while in debugging and testing stage
            && [ "$OPS_MODE" = "production" ] || apk add vim less tree \
            
            # clean up if in production mode
            && [ "$OPS_MODE" = "development" ] || apk del .base_build_deps
