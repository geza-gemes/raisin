#!/usr/bin/env bash

source config
source common-functions.sh


function libvirt_install_dependencies() {
    local DEP_Debian_common="build-essential libtool autoconf autopoint \
                             xsltproc libxml2-utils pkg-config python-dev   \
                             libxml-xpath-perl libyajl-dev libxml2-dev      \
                             gettext libdevmapper-dev libnl-3-dev           \
                             libnl-route-3-dev"
    local DEP_Debian_x86_32="$DEP_Debian_common"
    local DEP_Debian_x86_64="$DEP_Debian_common"
    local DEP_Debian_arm32="$DEP_Debian_common"
    local DEP_Debian_arm64="$DEP_Debian_common"

    local DEP_Fedora_common="patch make gcc libtool autoconf gettext-devel \
                             python-devel libxslt yajl-devel libxml2-devel     \
                             device-mapper-devel libpciaccess-devel            \
                             libuuid-devel"
    local DEP_Fedora_x86_32="$DEP_Fedora_common"
    local DEP_Fedora_x86_64="$DEP_Fedora_common"

    echo installing Libvirt dependencies
    eval install_dependencies \$DEP_"$DISTRO"_"$ARCH"
}

function libvirt_build() {
    libvirt_install_dependencies

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
    $MAKE --ignore-errors install DESTDIR="$INST_DIR"
    if test $DISTRO = "Debian"
    then
        cat ../libvirt.debian.init | sed -e "s/@PREFIX/$PREFIX/g" > "$INST_DIR"/etc/init.d/libvirtd
        chmod +x "$INST_DIR"/etc/init.d/libvirtd
    elif test $DISTRO = "Fedora" || test $DISTRO = "CentOS"
    then
        $MAKE -C daemon libvirtd.init
        cp daemon/libvirtd.init $INST_DIR/etc/init.d/libvirtd
        chmod +x "$INST_DIR"/etc/init.d/libvirtd
    else
        echo "I don't know how write an init script for Libvirt on $DISTRO"
    fi
    cd ..
}

function libvirt_clean() {
    rm -rf libvirt-dir
}

function libvirt_configure() {
    start_initscripts libvirtd libvirt-guests virtlockd
}
