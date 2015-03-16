#!/usr/bin/env bash

source config

libvirt_clean() {
    rm -rf libvirt-dir
}

libvirt_build() {
    ./git-checkout.sh $LIBVIRT_UPSTREAM_URL $LIBVIRT_UPSTREAM_REVISION libvirt-dir
    cd libvirt-dir
    ./autogen.sh --disable-threads --with-xen --without-qemu --without-uml     \
    	--without-outopenvz --without-vmware --without-libssh2 --without-phyp  \
    	--without-xenapi --with-libxl --without-vbox --without-lxc             \
    	--without-esx --without-hyperv --without-parallels --without-test      \
    	--without-remote --with-libvirtd --without-sasl --with-yajl            \
    	--without-dbus --without-selinux --without-python --without-apparmor   \
    	--without-macvtap --without-avahi --without-openvz --without-dbus      \
    	--prefix=$PREFIX
    $MAKE
    $MAKE --ignore-errors install DESTDIR=$INST_DIR
    cd ..
}
