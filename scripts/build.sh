#!/bin/bash

set -o pipefail
#set -x

ROOT="$(cd `dirname $0` && cd .. && pwd )"
IMAGE=${IMAGE:-"claranet/spryker-base"}
VERSION=${VERSION:-$(cat $ROOT/VERSION)}
BUILD_TAGS=()

[[ -n "$BUILD_NUMBER" ]] && VERSION="$VERSION-$BUILD_NUMBER"

# Tries to find files and only return the image tag
get_tags() {
    pattern=${1:-"$ROOT/Dockerfiles/Dockerfile*"}
    echo $(ls -1 $pattern | grep -v common | grep '\.sh$' | sed -e 's/^.*Dockerfile-\(.*\).inc.sh$/\1/g')
}

print_template() {
    pushd $(dirname $1) >/dev/null
    source $1
    for template in ${ELEMENTS[*]}; do 
        echo -e "\n\n# $template ----------------------------------------------------------------"
        echo -e "${!template}"
    done
    popd >/dev/null
}

# Iterate either across given files by argument or read all the the available ones
if [ -n $1 ]; then 
    while true; do
        file=$1; shift
        if [ ! -e $file ]; then
            echo "Error: Given file could not be found: $file" >&2
            exit 1
        fi
        tag=$(get_tags $file)
        if [ -z "$tag" ]; then
            echo "Error: Given file is a common one; use concrete flavor/variant image templates instead: $file" >&2
            exit 1
        else
            BUILD_TAGS+=( $tag )
        fi
        [ -z $1 ] && break
    done

else
    echo "INFO: No Dockerfile given, building images for all flavors and variants ..."
    BUILD_TAGS+=( $(get_tags) )
fi


for tag in "${BUILD_TAGS[@]}" ; do
    Dockerfile="$ROOT/Dockerfiles/Dockerfile-$tag.inc.sh"
    Tag="$VERSION-$tag"
    File="$(dirname $Dockerfile)/Dockerfile-$Tag"
    echo "[INFO] Building: $(basename $Dockerfile) --> $IMAGE:$Tag ..."
    print_template $Dockerfile > $File
    docker build -f $File --tag $IMAGE:$Tag .
    rm -v $File
done

exit 0
