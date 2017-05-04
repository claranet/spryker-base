
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
    JENKINS_HOST="jenkins" \
    JENKINS_PORT="8080"


COPY etc/ /etc/
COPY docker $WORKDIR/docker
COPY entrypoint.sh /usr/bin/

EXPOSE 80

WORKDIR $WORKDIR
ENTRYPOINT [ "entrypoint.sh" ]

# on default, start yves and zed in one container
CMD  [ "run_yves_and_zed" ]


#
# all onbuild commands will be executed before a child image gets build.
#


# With DEV_TOOLS=on, we won't clean up the image from build tools and debugging tools.
# Even further we will add tools like vim, tree and less.
# supported vaules are (on/off), defaults to "off"

# application env decides in which mode the application is installed/runned.
# so if you choose development here, e.g. composer and npm/yarn will also install
# dev dependencies! There are more modifications, which depend on this switch.
# defaults to "production"

# support NODEJS_VERSION as ARG to let the user switch between nodejs 6.x and 7.x
# NODEJS_PACKAGE_MANAGER: you can, additionally to npm, install yarn; if you select yarn here
# also, if yarn is selected, it would be used while running the base installation
ONBUILD ARG DEV_TOOLS=off
ONBUILD ARG APPLICATION_ENV
ONBUILD ARG NODEJS_VERSION=6
ONBUILD ARG NODEJS_PACKAGE_MANAGER

ONBUILD ENV APPLICATION_ENV=${APPLICATION_ENV:-production} \
            NODEJS_PACKAGE_MANAGER=${NODEJS_PACKAGE_MANAGER:-npm}


# copy shop specific data
# if you want to get some files ignored, please leverage the .dockerignore file
ONBUILD COPY * $WORKDIR/
# we have to copy "docker/" distinct from the above, as there is already an docker/ folder
ONBUILD COPY docker docker/

# build the specific shop image
ONBUILD RUN entrypoint.sh build
