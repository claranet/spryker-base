#!/bin/sh

# abort on error
set -eu -o pipefail

export SHOP="/data/shop"
export SETUP=spryker
export TERM=xterm 
export VERBOSITY='-v'

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
