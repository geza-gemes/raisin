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
          uuid-dev libncurses5-dev libyajl-dev libaio-dev pkg-config \
          libglib2.0-dev libssl-dev libpixman-1-dev
        if test $ARCH = "x86_32" || test $ARCH = "x86_64"
        then
                $SUDO apt-get install -y bcc iasl bin86 texinfo
        fi
        if test $ARCH = "x86_64"
        then
            $SUDO apt-get install -y libc6-dev-i386
        fi
        if test $ARCH = "arm32" || test $ARCH = "arm64"
        then
            $SUDO apt-get install -y libfdt-dev
        fi
        ;;
        "Fedora" )
        $SUDO yum install -y git make gcc python-devel gettext \
          libuuid-devel ncurses-devel glib2-devel libaio-devel openssl-devel \
          yajl-devel patch pixman-devel 
        if test $ARCH = "x86_32" || test $ARCH = "x86_64"
        then
            $SUDO yum install -y dev86 iasl texinfo
        fi
        if test $ARCH = "x86_64"
        then
            $SUDO yum install -y glibc-devel.i686
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
