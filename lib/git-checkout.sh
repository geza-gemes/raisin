#!/usr/bin/env bash

function git-checkout() {
    if [[ $# -lt 3 ]]
    then
        echo "Usage: $0 <tree> <tag> <dir>"
        exit 1
    fi

    TREE=$1
    TAG=$2
    DIR=$3

    set -e

    if [[ ! -d $DIR-remote ]]
    then
        rm -rf $DIR-remote $DIR-remote.tmp
        mkdir -p $DIR-remote.tmp; rmdir $DIR-remote.tmp
        $GIT clone $TREE $DIR-remote.tmp
        if [[ "$TAG" ]]
        then
            cd $DIR-remote.tmp
            $GIT branch -D dummy >/dev/null 2>&1 ||:
            $GIT checkout -b dummy $TAG
            cd ..
        fi
        mv $DIR-remote.tmp $DIR-remote
    fi
    rm -f $DIR
    ln -sf $DIR-remote $DIR
}
