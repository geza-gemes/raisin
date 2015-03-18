#!/usr/bin/env bash

source config
source common-functions.sh


function grub_install_dependencies() {
    local DEP_Debian_common="build-essential tar autoconf bison flex"
    local DEP_Debian_x86_32="$DEP_Debian_common"
    local DEP_Debian_x86_64="$DEP_Debian_common libc6-dev-i386"
    local DEP_Debian_arm32="$DEP_Debian_common"
    local DEP_Debian_arm64="$DEP_Debian_common"

    local DEP_Fedora_common="make gcc tar automake autoconf sysconftool bison flex"
    local DEP_Fedora_x86_32="$DEP_Fedora_common"
    local DEP_Fedora_x86_64="$DEP_Fedora_common glibc-devel.i686"


    if test $ARCH != "x86_64" && test $ARCH != "x86_32"
    then
        echo grub is only supported on x86_32 and x86_64
        return
    fi
    echo installing Grub dependencies
    eval install_dependencies \$DEP_"$DISTRO"_"$ARCH"
}


function grub_build() {
    grub_install_dependencies

    tar cf memdisk.tar grub.cfg
    ./git-checkout.sh $GRUB_UPSTREAM_URL $GRUB_UPSTREAM_REVISION grub-dir
    cd grub-dir
    export CPPFLAGS="-I$INST_DIR/$PREFIX/include"
    ./autogen.sh
    ## GRUB32
    ./configure --target=i386 --with-platform=xen
    $MAKE
    ./grub-mkimage -d grub-core -O i386-xen -c ../grub-bootstrap.cfg \
      -m ../memdisk.tar -o grub-i386-xen grub-core/*mod
    cp grub-i386-xen "$INST_DIR"/$PREFIX/lib/xen/boot
    ## GRUB64
    if test $ARCH = "x86_64"
    then
        $MAKE clean
        ./configure --target=amd64 --with-platform=xen
        $MAKE
        ./grub-mkimage -d grub-core -O x86_64-xen -c ../grub-bootstrap.cfg \
          -m ../memdisk.tar -o grub-x86_64-xen grub-core/*mod
        cp grub-x86_64-xen "$INST_DIR"/$PREFIX/lib/xen/boot
    fi
    cd ..
}

function grub_clean() {
    rm -rf memdisk.tar
    rm -rf grub-dir
}

function grub_configure() {
}
