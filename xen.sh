#!/usr/bin/env bash

source config

function xen_clean() {
    rm -rf xen-dir
}

function xen_build() {
    echo installing Xen dependencies
    case $DISTRO in
        "Debian" | "Ubuntu" )
        $SUDO apt-get install -y git build-essential python-dev gettext \
          uuid-dev libncurses5-dev libyajl-dev libaio-dev
        if test $ARCH = "x86_32" || test $ARCH = "x86_64"
        then
                $SUDO apt-get install -y bcc iasl bin86 libglib2.0-0 \
                  libpixman-1-dev
        fi
        if test $ARCH = "x86_64"
        then
            $SUDO apt-get install -y libc6-dev-i386
        fi
        ;;
        * )
        echo "I don't know how to install xen dependencies on $DISTRO"
        return 1
        ;;
    esac

    ./git-checkout.sh $XEN_UPSTREAM_URL $XEN_UPSTREAM_REVISION xen-dir
    cd xen-dir
    ./configure --prefix=$PREFIX
    $MAKE
    $MAKE install DESTDIR="$INST_DIR"
    cd ..
}
