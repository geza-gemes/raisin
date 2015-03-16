#!/usr/bin/env bash

source config

clean_xen() {
    rm -rf xen-dir
}

build_xen() {
    ./git-checkout.sh $XEN_UPSTREAM_URL $XEN_UPSTREAM_REVISION xen-dir
    cd xen-dir
    ./configure --prefix=$PREFIX
    $MAKE
    $MAKE install DESTDIR="$INST_DIR"
    cd ..
}
