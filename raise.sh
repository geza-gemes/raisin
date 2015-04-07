#!/usr/bin/env bash

set -e

source config
source common-functions.sh

_help() {
    echo "Usage: ./build.sh <options> <command>"
    echo "where options are:"
    echo "    -n | --no-deps       Do no install build-time dependencies"
    echo "    -v | --verbose       Verbose"
    echo "    -y | --yes           Do not ask questions and continue"
    echo "where commands are:"
    echo "    build                Build the components enabled in config"
    echo "    install              Install binaries under /  (requires sudo)"
    echo "    configure            Configure the system  (requires sudo)"
}

_build() {
    if [[ $YES != "y" ]]
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
}

_install() {
    install_package xen-system
}

_configure() {
    if [[ $YES != "y" ]]
    then
        echo "Proceeding we'll make changes to the running system,"
        echo "are you sure that you want to continue? (y/n)"
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

    for_each_component configure
}

# start execution
common_init

# parameters check
export VERBOSE=0
export YES="n"
export NO_DEPS=0
while [[ $# -gt 1 ]]
do
  if [[ "$1" = "-v" || "$1" = "--verbose" ]]
  then
    VERBOSE=1
    shift 1
  elif [[ "$1" = "-y" || "$1" = "--yes" ]]
  then
    YES="y"
    shift 1
  else
    _help
    exit 1
  fi
done

case "$1" in
    "build" | "install" | "configure" )
        COMMAND=$1
        ;;
    *)
        _help
        exit 1
        ;;
esac

_$COMMAND

