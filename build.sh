#!/usr/bin/env bash

source config

export PWD=`pwd`
export GIT=${GIT-git}
export MAKE=${MAKE-make -j}
export PREFIX=${PREFIX-/usr}
export INST_DIR=${DESTDIR-dist}

if test ! -d "$INST_DIR"
then
    echo "DESTDIR not set correctly"
    exit 1
fi
INST_DIR=`readlink -f $INST_DIR`


source xen.sh
source grub.sh
source libvirt.sh


# execution
rm -rf "$INST_DIR"
mkdir -p "$INST_DIR"

if test "$XEN_UPSTREAM_REVISION"
then
    clean_xen
    build_xen
fi
if test "$GRUB_UPSTREAM_REVISION"
then
    clean_grub
    build_grub
fi
if test "$LIBVIRT_UPSTREAM_REVISION"
then
    clean_libvirt
    build_libvirt
fi
