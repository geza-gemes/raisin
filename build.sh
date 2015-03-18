#!/usr/bin/env bash

source config
source common-functions.sh

export PWD=`pwd`
export GIT=${GIT-git}
export SUDO=${SUDO-sudo}
export MAKE=${MAKE-make -j}
export PREFIX=${PREFIX-/usr}
export INST_DIR=${DESTDIR-dist}

INST_DIR=`readlink -f $INST_DIR`
mkdir -p "$INST_DIR" &>/dev/null

source xen.sh
source grub.sh
source libvirt.sh


# execution
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

install_dependencies git

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
