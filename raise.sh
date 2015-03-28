#!/usr/bin/env bash

set -e

source config
source common-functions.sh

help() {
    echo "Usage: ./build.sh <options>"
    echo "where options are:"
    echo "    -n | --no-deps       Do no install build-time dependencies"
    echo "    -v | --verbose       Verbose"
    echo "    -i | --install       Install under / and configure the system"
}


# start execution
common_init

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

mkdir -p "$INST_DIR" &>/dev/null
install_dependencies git

# build and install under $DESTDIR
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
