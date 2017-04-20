#!/bin/sh

# abort on error
set -eu -o pipefail

export SHOP="/data/shop"
export SETUP=spryker
export TERM=xterm 
export VERBOSITY='-v'

# path to our antelope binary
ANTELOPE='/data/shop/node_modules/.bin/antelope'

# make modifying parameters easy by a central apk add command
apk_add='apk add'


# include custom build config on demand
if [[ -e "$WORKDIR/docker/build.conf" ]]; then
  source "$WORKDIR/docker/build.conf"
fi


NPM=${NODEJS_PACKAGE_MANAGER:-npm}

ERROR_BKG=';41m' # background red
GREEN_BKG=';42m' # background green
BLUE_BKG=';44m' # background blue
YELLOW_BKG=';43m' # background yellow
MAGENTA_BKG=';45m' # background magenta

INFO_TEXT='\033[33' # yellow text
WHITE_TEXT='\033[37' # text white
BLACK_TEXT='\033[30' # text black
RED_TEXT='\033[31' # text red
NC='\033[0m' # reset

if [[ `echo "$@" | grep '\-v'` ]]; then
    VERBOSITY='-v'
fi

if [[ `echo "$@" | grep '\-vv'` ]]; then
    VERBOSITY='-vv'
fi

if [[ `echo "$@" | grep '\-vvv'` ]]; then
    VERBOSITY='-vvv'
fi

labelText() {
    echo -e "\n${WHITE_TEXT}${BLUE_BKG}-> ${1} ${NC}\n"
}

errorText() {
    echo -e "\n${WHITE_TEXT}${ERROR_BKG}=> ${1} <=${NC}\n"
}

infoText() {
    echo -e "\n${INFO_TEXT}m=> ${1} <=${NC}\n"
}

successText() {
    echo -e "\n${BLACK_TEXT}${GREEN_BKG}=> ${1} <=${NC}\n"
}

warningText() {
    echo -e "\n${RED_TEXT}${YELLOW_BKG}=> ${1} <=${NC}\n"
}

setupText() {
    echo -e "\n${WHITE_TEXT}${MAGENTA_BKG}=> ${1} <=${NC}\n"
}

writeErrorMessage() {
    if [[ $? != 0 ]]; then
        errorText "${1}"
        errorText "Command unsuccessful"
        exit 1
    fi
}

createDevelopmentDatabase() {
    # postgres
    createdb ${DATABASE_NAME}

    # mysql
    # mysql -u root -e "CREATE DATABASE DE_development_zed;"
}

dumpDevelopmentDatabase() {
    export PGPASSWORD=$DATABASE_PASSWORD
    export LC_ALL="en_US.UTF-8"

    pg_dump -i -h 127.0.0.1 -U $DATABASE_USER  -F c -b -v -f  $DATABASE_NAME.backup $DATABASE_NAME
}

restoreDevelopmentDatabase() {
    read -r -p "Restore database ${DATABASE_NAME} ? [y/N] " response
    case $response in
        [yY][eE][sS]|[yY])
            export PGPASSWORD=$DATABASE_PASSWORD
            export LC_ALL="en_US.UTF-8"

            pg_ctlcluster 9.4 main restart --force
            dropdb $DATABASE_NAME
            createdb $DATABASE_NAME
            pg_restore -i -h 127.0.0.1 -p 5432 -U $DATABASE_USER -d $DATABASE_NAME -v $DATABASE_NAME.backup
            ;;
        *)
            echo "Nothing done."
            ;;
    esac
}

installDemoshop() {
    labelText "Preparing to install Spryker Platform..."

    composerInstall

    installZed
    sleep 1
    installYves

    configureCodeception

    successText "Setup successful"
    infoText "\nYves URL: http://www.de.spryker.dev/\nZed URL: http://zed.de.spryker.dev/\n"
}

installZed() {
    setupText "Zed setup"

    resetDataStores

    dropDevelopmentDatabase

    $CONSOLE setup:install $VERBOSITY
    writeErrorMessage "Setup install failed"

    labelText "Importing Demo data"
    $CONSOLE import:demo-data $VERBOSITY
    writeErrorMessage "DemoData import failed"

    labelText "Setting up data stores"
    $CONSOLE collector:search:export $VERBOSITY
    $CONSOLE collector:storage:export $VERBOSITY
    writeErrorMessage "DataStore setup failed"

    labelText "Setting up cronjobs"
    $CONSOLE setup:jenkins:generate $VERBOSITY
    writeErrorMessage "Cronjob setup failed"

    antelopeInstall

    labelText "Zed setup successful"
}

installYves() {
    setupText "Yves setup"

    antelopeInstall

    labelText "Yves setup successful"
}

configureCodeception() {
    labelText "Configuring test environment"
    vendor/bin/codecept build -q $VERBOSITY
    writeErrorMessage "Test configuration failed"
}

resetDataStores() {
    labelText "Flushing Elasticsearch"
    curl -XDELETE 'http://localhost:10005/de_search/'
    writeErrorMessage "Elasticsearch reset failed"

    labelText "Flushing Redis"
    redis-cli -p 10009 FLUSHALL
    writeErrorMessage "Redis reset failed"
}

resetDevelopmentState() {
    labelText "Preparing to reset data..."
    sleep 1

    resetDataStores

    dropDevelopmentDatabase

    labelText "Generating Transfer Objects"
    $CONSOLE transfer:generate
    writeErrorMessage "Generating Transfer Objects failed"

    labelText "Installing Propel"
    $CONSOLE propel:install $VERBOSITY
    $CONSOLE propel:diff $VERBOSITY
    $CONSOLE propel:migrate $VERBOSITY
    writeErrorMessage "Propel setup failed"

    labelText "Initializing DB"
    $CONSOLE setup:init-db $VERBOSITY
    writeErrorMessage "DB setup failed"
}

dropDevelopmentDatabase() {
    if [ `psql -l | grep ${DATABASE_NAME} | wc -l` -ne 0 ]; then

        PG_CTL_CLUSTER=`which pg_ctlcluster`
        DROP_DB=`which dropdb`

        if [[ -f $PG_CTL_CLUSTER ]] && [[ -f $DROP_DB ]]; then
            labelText "Deleting PostgreSql Database: ${DATABASE_NAME} "
            pg_ctlcluster 9.4 main restart --force && dropdb $DATABASE_NAME 1>/dev/null
            writeErrorMessage "Deleting DB command failed"
        fi
    fi

    # MYSQL=`which mysql`
    # if [[ -f $MYSQL ]]; then
    #    labelText "Drop MySQL database: ${1}"
    #    mysql -u root -e "DROP DATABASE IF EXISTS ${1};"
    # fi
}

composerInstall() {
    echo $@
    labelText "Installing composer packages"
    php /data/bin/composer.phar install --prefer-dist
}

dumpAutoload() {
    php /data/bin/composer.phar dump-autoload
}

resetYves() {
    if [[ -d "./node_modules" ]]; then
        labelText "Remove node_modules directory"
        rm -rf "./node_modules"
        writeErrorMessage "Could not remove node_modules directory"
    fi

    if [[ -d "./data/DE/logs" ]]; then
        labelText "Clear logs"
        rm -rf "./data/DE/logs"
        mkdir "./data/DE/logs"
        writeErrorMessage "Could not remove logs directory"
    fi

    if [[ -d "./data/DE/cache" ]]; then
        labelText "Clear cache"
        rm -rf "./data/DE/cache"
        writeErrorMessage "Could not remove cache directory"
    fi
}

antelopeInstall() {
    labelText "Installing project dependencies"
    $ANTELOPE install

    labelText "Building and optimizing assets for Zed"
    $ANTELOPE build zed
    writeErrorMessage "Antelope build failed"
}

displayHeader() {
    labelText "Spryker Platform Setup"
    echo "./$(basename $0) [OPTION] [VERBOSITY]"
}

displayHelp() {

    displayHeader

    echo ""
    echo "  -i, --install-demo-shop"
    echo "      Install and setup new instance of Spryker Platform and populate it with Demo data"
    echo " "
    echo "  -yves, --install-yves"
    echo "      (re)Install Yves only"
    echo " "
    echo "  -zed, --install-zed"
    echo "      (re)Install Zed only"
    echo " "
    echo "  -r, --reset"
    echo "      Reset state. Delete Redis, Elasticsearch and Database data"
    echo ""
    echo "  -ddb, --dump-db"
    echo "      Dump database into a file"
    echo ""
    echo "  -rdb, --restore-db"
    echo "      Restore database from a file"
    echo ""
    echo "  -h, --help"
    echo "      Show this help"
    echo ""
    echo "  -c, --clean"
    echo "      Cleanup unnecessary files and optimize the local repository"
    echo ""
    echo "  -v, -vv, -vvv"
    echo "      Set verbosity level"
    echo " "
}
