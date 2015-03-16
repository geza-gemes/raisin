#!/usr/bin/env bash

source config

function grub_clean() {
    rm -rf memdisk.tar
    rm -rf grub-dir
}

function grub_build() {
    if test $ARCH != "x86_64" && test $ARCH != "x86_32"
    then
        echo grub is only supported on x86_32 and x86_64
        return
    fi
    echo installing Grub dependencies
    case $DISTRO in
        "Debian" | "Ubuntu" )
        # grub also requires xen
        $SUDO apt-get install -y git build-essential tar autoconf bison flex
        if test $ARCH = "x86_64"
        then
            $SUDO apt-get install -y libc6-dev-i386
        fi
        ;;
        * )
        echo "I don't know how to install grub dependencies on $DISTRO"
        return 1
        ;;
    esac

    tar cf memdisk.tar grub.cfg
    ./git-checkout.sh $GRUB_UPSTREAM_URL $GRUB_UPSTREAM_REVISION grub-dir
    cd grub-dir
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
