#!/usr/bin/env bash

source config
source common-functions.sh


DEP_Debian_common="git build-essential python-dev gettext uuid-dev \
    libncurses5-dev libyajl-dev libaio-dev pkg-config libglib2.0-dev \
    libssl-dev libpixman-1-dev"
DEP_Debian_x86_32="$DEP_Debian_common bcc iasl bin86 texinfo"
DEP_Debian_x86_64="$DEP_Debian_x86_32 libc6-dev-i386"
DEP_Debian_arm32="$DEP_Debian_common libfdt-dev"
DEP_Debian_arm64="$DEP_Debian_arm32"

DEP_Fedora_common="git make gcc python-devel gettext libuuid-devel \
    ncurses-devel glib2-devel libaio-devel openssl-devel yajl-devel patch \
    pixman-devel"
DEP_Fedora_x86_32="$DEP_Fedora_common dev86 iasl texinfo"
DEP_Fedora_x86_64="$DEP_Fedora_x86_32 glibc-devel.i686"


function xen_build() {
    echo installing Xen dependencies
    eval install_dependencies \$DEP_"$DISTRO"_"$ARCH"

    ./git-checkout.sh $XEN_UPSTREAM_URL $XEN_UPSTREAM_REVISION xen-dir
    cd xen-dir
    ./configure --prefix=$PREFIX
    $MAKE
    $MAKE install DESTDIR="$INST_DIR"
    cd ..
}

function xen_clean() {
    rm -rf xen-dir
}



