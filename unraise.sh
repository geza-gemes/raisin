#!/usr/bin/env bash

set -e

source config
source common-functions.sh

export PWD=`pwd`
export GIT=${GIT-git}
export SUDO=${SUDO-sudo}
export MAKE=${MAKE-make}
export PREFIX=${PREFIX-/usr}
export INST_DIR=${DESTDIR-dist}

INST_DIR=`readlink -f $INST_DIR`

xen_clean
grub_clean
libvirt_clean

xen_unconfigure
grub_unconfigure
libvirt_unconfigure

for i in `cat /var/log/raisin.log 2>/dev/null`
do
    rm -rf /"$i"
done
rm -rf /var/log/raisin.log
rm -rf "$INST_DIR"

