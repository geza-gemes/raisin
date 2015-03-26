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

if test $EUID -eq 0
then
    export SUDO=""
elif test ! -f `which sudo 2>/dev/null`
then
    echo "Raixen requires sudo to install build dependencies for you."
    echo "Please install sudo, then run this script again."
    exit 1
fi

get_distro
get_arch

for f in `cat "$BASEDIR"/components/series`
do
    source "$BASEDIR"/components/"$f"
done

for_each_component clean
for_each_component unconfigure

for i in `cat /var/log/raisin.log 2>/dev/null`
do
    if test -f /"$i"
    then
        rm -f /"$i"
    fi
done
for i in `cat /var/log/raisin.log 2>/dev/null`
do
    if test -d /"$i"
    then
        rmdir --ignore-fail-on-non-empty /"$i"
    fi
done

rm -rf /var/log/raisin.log
rm -rf "$INST_DIR"

