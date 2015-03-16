#!/usr/bin/env bash

source config

function xen_clean() {
    rm -rf xen-dir
}

function xen_build() {
    # install dependencies
    case $DISTRO in
        "Debian" | "Ubuntu" )
        apt-get install build-essential
        ;;
        * )
        echo "I don't know how to install xen dependencies on $DISTRO"
        return 1
        ;;
    esac

    ./git-checkout.sh $XEN_UPSTREAM_URL $XEN_UPSTREAM_REVISION xen-dir
    cd xen-dir
    ./configure --prefix=$PREFIX
    $MAKE
    $MAKE install DESTDIR="$INST_DIR"
    cd ..
}
