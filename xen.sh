#!/usr/bin/env bash

source config
source common-functions.sh


function xen_install_dependencies() {
    local DEP_Debian_common="git build-essential python-dev gettext uuid-dev   \
             libncurses5-dev libyajl-dev libaio-dev pkg-config libglib2.0-dev  \
             libssl-dev libpixman-1-dev"
    local DEP_Debian_x86_32="$DEP_Debian_common bcc iasl bin86 texinfo"
    local DEP_Debian_x86_64="$DEP_Debian_x86_32 libc6-dev-i386"
    local DEP_Debian_arm32="$DEP_Debian_common libfdt-dev"
    local DEP_Debian_arm64="$DEP_Debian_arm32"

    local DEP_Fedora_common="git make gcc python-devel gettext libuuid-devel   \
             ncurses-devel glib2-devel libaio-devel openssl-devel yajl-devel   \
             patch pixman-devel"
    local DEP_Fedora_x86_32="$DEP_Fedora_common dev86 iasl texinfo"
    local DEP_Fedora_x86_64="$DEP_Fedora_x86_32 glibc-devel.i686"

    echo installing Xen dependencies
    eval install_dependencies \$DEP_"$DISTRO"_"$ARCH"
}

function xen_build() {
    xen_install_dependencies

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



