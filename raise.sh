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
mkdir -p "$INST_DIR" &>/dev/null

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

for f in `cat "$BASEDIR"/components/series`
do
    source "$BASEDIR"/components/"$f"
done

# build and install under $DESTDIR ($BASEDIR/dist by default)
for_each_component clean
for_each_component build

if test -z "$INST" || test "$INST" -eq 0
then
    exit 0
fi
# install under /
TMPFILE=`mktemp`
cd "$INST_DIR"
find . > $TMPFILE
$SUDO mv -f $TMPFILE /var/log/raisin.log
$SUDO cp -ar * / || true

# configure
for_each_component configure

rm -rf "$INST_DIR"
