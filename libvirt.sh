#!/usr/bin/env bash

source config
source common-functions.sh


DEP_Debian_common="git build-essential libtool autoconf autopoint xsltproc libxml2-utils pkg-config python-dev libxml-xpath-perl libyajl-dev libxml2-dev gettext libdevmapper-dev libnl-3-dev libnl-route-3-dev"
DEP_Debian_x86_32="$DEP_Debian_common"
DEP_Debian_x86_64="$DEP_Debian_common"
DEP_Debian_arm32="$DEP_Debian_common"
DEP_Debian_arm64="$DEP_Debian_common"

DEP_Fedora_common="git patch make gcc libtool autoconf gettext-devel python-devel libxslt yajl-devel libxml2-devel device-mapper-devel libpciaccess-devel libuuid-devel"
DEP_Fedora_x86_32="$DEP_Fedora_common"
DEP_Fedora_x86_64="$DEP_Fedora_common"


function libvirt_build() {
    echo installing Libvirt dependencies
    eval install_dependencies \$DEP_"$DISTRO"_"$ARCH"

    ./git-checkout.sh $LIBVIRT_UPSTREAM_URL $LIBVIRT_UPSTREAM_REVISION libvirt-dir
    cd libvirt-dir
    CFLAGS="-I$INST_DIR/$PREFIX/include" \
    LDFLAGS="-L$INST_DIR/$PREFIX/lib -Wl,-rpath-link=$INST_DIR/$PREFIX/lib" \
    ./autogen.sh --with-xen --without-qemu --without-uml --without-openvz \
        --without-vmware --without-phyp --without-xenapi --with-libxl     \
        --without-vbox --without-lxc --without-esx --without-hyperv       \
        --without-parallels --without-test --with-libvirtd --without-sasl \
        --with-yajl --without-macvtap --without-avahi  --prefix=$PREFIX
    $MAKE
    $MAKE --ignore-errors install DESTDIR=$INST_DIR
    cd ..
}

function libvirt_clean() {
    rm -rf libvirt-dir
}
