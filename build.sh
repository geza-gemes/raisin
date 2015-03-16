#!/usr/bin/env bash

source config

export PWD=`pwd`
export GIT=${GIT-git}
export MAKE=${MAKE-make -j}
export PREFIX=${PREFIX-/usr}
export INST_DIR=${DESTDIR-dist}

INST_DIR=`readlink -f $INST_DIR`
mkdir -p "$INST_DIR"

source xen.sh
source grub.sh
source libvirt.sh


# execution
rm -rf "$INST_DIR"
mkdir -p "$INST_DIR"

if test "$XEN_UPSTREAM_REVISION"
then
    xen_clean
    xen_build
fi
if test "$GRUB_UPSTREAM_REVISION"
then
    grub_clean
    grub_build
fi
if test "$LIBVIRT_UPSTREAM_REVISION"
then
    libvirt_clean
    libvirt_build
fi
