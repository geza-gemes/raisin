#!/usr/bin/env bash

set -e

source config
source common-functions.sh

export BASEDIR=`pwd`
export GIT=${GIT-git}
export SUDO=${SUDO-sudo}
export MAKE=${MAKE-make}
export PREFIX=${PREFIX-/usr}
export INST_DIR=${DESTDIR-dist}

INST_DIR=`readlink -f $INST_DIR`

for f in `cat "$BASEDIR"/components/series`
do
    source "$BASEDIR"/components/"$f"
done

for_each_component clean
for_each_component unconfigure

for i in `cat /var/log/raisin.log 2>/dev/null`
do
    rm -rf /"$i"
done
rm -rf /var/log/raisin.log
rm -rf "$INST_DIR"

