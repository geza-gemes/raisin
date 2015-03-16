#!/usr/bin/env bash

source config

grub_clean() {
    rm -rf memdisk.tar
    rm -rf grub-dir
}

grub_build() {
    tar cf memdisk.tar grub.cfg
    ./git-checkout.sh $GRUB_UPSTREAM_URL $GRUB_UPSTREAM_REVISION grub-dir
    cd grub-dir
    ./autogen.sh
    ## GRUB32
    ./configure --target=i386 --with-platform=xen
    $MAKE
    ./grub-mkimage -d grub-core -O i386-xen -c ../grub-bootstrap.cfg -m ../memdisk.tar -o grub-i386-xen grub-core/*mod
    cp grub-i386-xen "$INST_DIR"/$PREFIX/lib/xen/boot
    ## GRUB64
    $MAKE clean
    ./configure --target=amd64 --with-platform=xen
    $MAKE
    ./grub-mkimage -d grub-core -O x86_64-xen -c ../grub-bootstrap.cfg -m ../memdisk.tar -o grub-x86_64-xen grub-core/*mod
    cp grub-x86_64-xen "$INST_DIR"/$PREFIX/lib/xen/boot
    cd ..
}
