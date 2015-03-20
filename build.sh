#!/usr/bin/env bash

source config
source common-functions.sh

export PWD=`pwd`
export GIT=${GIT-git}
export SUDO=${SUDO-sudo}
export MAKE=${MAKE-make}
export PREFIX=${PREFIX-/usr}
export INST_DIR=${DESTDIR-dist}

INST_DIR=`readlink -f $INST_DIR`
mkdir -p "$INST_DIR" &>/dev/null

source xen.sh
source grub.sh
source libvirt.sh

help() {
    echo "Usage: ./build.sh <options>"
    echo "where options are:"
    echo "    -n | --no-deps       Do no install build-time dependencies"
    echo "    -v | --verbose       Verbose"
    echo "    -i | --install       Install under / and configure the system"
}

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

# parameters check
INST=0
export NO_DEPS=0
export VERBOSE=0
while test $# -ge 1
do
  if test "$1" = "-n" || test "$1" = "--no-deps"
  then
    NO_DEPS=1
    shift 1
  elif test "$1" = "-v" || test "$1" = "--verbose"
  then
    VERBOSE=1
    shift 1
  elif test "$1" = "-i" || test "$1" = "--install"
  then
    INST=1
    shift 1
  else
    help
    exit 1
  fi
done


get_distro
get_arch

install_dependencies git

# build and install under $DESTDIR ($PWD/dist by default)
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


if test -z "$INST" || test "$INST" -eq 0
then
    exit 0
fi
# install under /
TMPFILE=`mktemp`
cd $INST_DIR
find . > $TMPFILE
$SUDO mv $TMPFILE /var/log/raixen.log
$SUDO mv -f * /

# configure
if test "$XEN_UPSTREAM_REVISION"
then
    xen_configure
fi
if test "$GRUB_UPSTREAM_REVISION"
then
    grub_configure
fi
if test "$LIBVIRT_UPSTREAM_REVISION"
then
    libvirt_configure
fi
