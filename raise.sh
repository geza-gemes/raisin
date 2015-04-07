#!/usr/bin/env bash

set -e

source config
source common-functions.sh

help() {
    echo "Usage: ./build.sh <options>"
    echo "where options are:"
    echo "    -n | --no-deps       Do no install build-time dependencies"
    echo "    -v | --verbose       Verbose"
    echo "    -y | --yes           Do not ask questions and continue"
    echo "    -i | --install       Install under / and configure the system (needs sudo)"
}


# start execution
common_init

# parameters check
INST=0
export NO_DEPS=0
export VERBOSE=0
export YES="n"
while [[ $# -ge 1 ]]
do
  if [[ "$1" = "-n" || "$1" = "--no-deps" ]]
  then
    NO_DEPS=1
    shift 1
  elif [[ "$1" = "-v" || "$1" = "--verbose" ]]
  then
    VERBOSE=1
    shift 1
  elif [[ "$1" = "-i" || "$1" = "--install" ]]
  then
    INST=1
    shift 1
  elif [[ "$1" = "-y" || "$1" = "--yes" ]]
  then
    YES="y"
    shift 1
  else
    help
    exit 1
  fi
done

if [[ $YES != "y" && $NO_DEPS -eq 0 ]]
then
    echo "Do you want Raisin to automatically install build time dependencies for you? (y/n)"
    while read answer
    do
        if [[ "$answer" = "n" ]]
        then
            NO_DEPS=1
            break
        elif [[ "$answer" = "y" ]]
        then
            break
        fi
    done
fi


mkdir -p "$INST_DIR" &>/dev/null
install_dependencies git
if [[ $DISTRO = "Fedora" ]]
then
    install_dependencies rpm-build
fi

# build and install under $DESTDIR
for_each_component clean
for_each_component build

build_package xen-system

if [[ -z "$INST" || "$INST" -eq 0 ]]
then
    exit 0
elif [[ -z "$YES" || "$YES" != "y" ]]
    echo "Proceeding we'll make changes to the running system,"
    echo "Installing the components we built and configuring the system"
    echo "(requires sudo)."
    echo "Are you sure that you want to continue? (y/n)"
    while read answer
    do
        if [[ "$answer" = "n" ]]
        then
            exit 0
        elif [[ "$answer" = "y" ]]
        then
            break
        fi
    done
fi

install_package xen-system

# configure
for_each_component configure
