#!/usr/bin/env bash

source config

function libvirt_clean() {
    rm -rf libvirt-dir
}

function libvirt_build() {
    echo installing Libvirt dependencies
    case $DISTRO in
        "Debian" | "Ubuntu" )
        # libvirt also requires xen
        $SUDO apt-get install -y git build-essential libtool autoconf \
                                 autopoint xsltproc libxml2-utils     \
                                 pkg-config python-dev libxml-xpath-perl \
                                 libyajl-dev libxml2-dev gettext \
                                 libdevmapper-dev libnl-3-dev libnl-route-3-dev
        ;;
        * )
        echo "I don't know how to install libvirt dependencies on $DISTRO"
        return 1
        ;;
    esac

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
