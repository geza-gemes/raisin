#!/usr/bin/env bash

source config
source common-functions.sh


function xen_install_dependencies() {
    local DEP_Debian_common="build-essential python-dev gettext uuid-dev   \
             libncurses5-dev libyajl-dev libaio-dev pkg-config libglib2.0-dev  \
             libssl-dev libpixman-1-dev"
    local DEP_Debian_x86_32="$DEP_Debian_common bcc iasl bin86 texinfo"
    local DEP_Debian_x86_64="$DEP_Debian_x86_32 libc6-dev-i386"
    local DEP_Debian_arm32="$DEP_Debian_common libfdt-dev"
    local DEP_Debian_arm64="$DEP_Debian_arm32"

    local DEP_Fedora_common="make gcc python-devel gettext libuuid-devel   \
             ncurses-devel glib2-devel libaio-devel openssl-devel yajl-devel   \
             patch pixman-devel glibc-devel"
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
    chmod +x "$INST_DIR"/etc/init.d/xencommons
    chmod +x "$INST_DIR"/etc/init.d/xendomains
    chmod +x "$INST_DIR"/etc/init.d/xen-watchdog
    cd ..
}

function xen_clean() {
    rm -rf xen-dir
}

function xen_create_bridge_Debian() {
    BRIDGE="xenbr0"
    IFACE=`grep "dhcp" /etc/network/interfaces | head -1 | awk '{print$2}'`

    if test -z "$IFACE"
    then
        echo "Please refer to the following page to setup networking:"
        echo "http://wiki.xenproject.org/wiki/Network_Configuration_Examples_(Xen_4.1%2B)"
        return 1
    fi
    if test "`grep $BRIDGE /etc/network/interfaces`"
    then
        echo "a network bridge seems to be already setup"
        return 0
    fi

    TMPFILE=`mktemp`
    cat /etc/network/interfaces | \
        sed -e "s/iface $IFACE inet dhcp/iface $IFACE inet manual/" \
            -e "/auto/s/\<$IFACE\>/$BRIDGE/g" \
            -e "/allow-hotplug/s/\<$IFACE\>/$BRIDGE/g" > $TMPFILE
    echo "" >> $TMPFILE
    echo "iface $BRIDGE inet dhcp" >> $TMPFILE
    echo "    bridge_ports $IFACE" >> $TMPFILE
    $SUDO cp $TMPFILE /etc/network/interfaces
    rm $TMPFILE
}

function xen_configure() {
    if test "$DISTRO" != "Debian"
    then
        echo "I don't know how to configure Xen on $DISTRO"
        return 1
    fi
    xen_create_bridge_$DISTRO
    start_initscripts xencommons xendomains xen-watchdog
}
