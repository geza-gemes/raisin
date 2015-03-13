#!/usr/bin/env bash

test -f config && . config

PWD=`pwd`
GIT=${GIT-git}
MAKE=${MAKE-make -j}
PREFIX=${PREFIX-/usr}
if test "$DESTDIR"
then
    INST_DIR="$DESTDIR"
else
    INST_DIR=$PWD/dist
fi

if test "$GIT_HTTP" = y
then
    XEN_UPSTREAM_URL=${XEN_UPSTREAM_URL-"http://xenbits.xen.org/git-http/xen.git"}
    GRUB_UPSTREAM_URL=${GRUB_UPSTREAM_URL-"http://git.savannah.gnu.org/r/grub.git"}
    LIBVIRT_UPSTREAM_URL=${LIBVIRT_UPSTREAM_URL-"https://gitorious.org/libvirt/libvirt.git"}
else
    XEN_UPSTREAM_URL=${XEN_UPSTREAM_URL-"git://xenbits.xen.org/xen.git"}
    GRUB_UPSTREAM_URL=${GRUB_UPSTREAM_URL-"git://git.savannah.gnu.org/grub.git"}
    LIBVIRT_UPSTREAM_URL=${LIBVIRT_UPSTREAM_URL-"git://libvirt.org/libvirt.git"}
fi

XEN_UPSTREAM_REVISION=${XEN_UPSTREAM_REVISION-"RELEASE-4.5.0"}
GRUB_UPSTREAM_REVISION=${GRUB_UPSTREAM_REVISION-"master"}
LIBVIRT_UPSTREAM_REVISION=${LIBVIRT_UPSTREAM_REVISION-"v1.2.9.1"}



# two functions per component
clean_xen() {
    rm -rf xen-dir
}

build_xen() {
    ./git-checkout.sh $XEN_UPSTREAM_URL $XEN_UPSTREAM_REVISION xen-dir
    cd xen-dir
    ./configure --prefix=$PREFIX
    $MAKE
    $MAKE install DESTDIR="$INST_DIR"
    cd ..
}

clean_grub() {
    rm -rf memdisk.tar
    rm -rf grub-dir
}

build_grub() {
    tar cf memdisk.tar grub.cfg
    ./git-checkout.sh $GRUB_UPSTREAM_URL $GRUB_UPSTREAM_REVISION grub-dir
    cd grub-dir
    ./autogen.sh
    ## GRUB32
    ./configure --target=i386 --with-platform=xen
    $MAKE
    ./grub-mkimage -d grub-core -O i386-xen -c ../grub-bootstrap.cfg -m ../memdisk.tar -o grub-i386-xen grub-core/*mod
    cp grub-i386-xen "$INST_DIR"/$PREFIX/lib/xen/boot
    ## GRUB64
    $MAKE clean
    ./configure --target=amd64 --with-platform=xen
    $MAKE
    ./grub-mkimage -d grub-core -O x86_64-xen -c ../grub-bootstrap.cfg -m ../memdisk.tar -o grub-x86_64-xen grub-core/*mod
    cp grub-x86_64-xen "$INST_DIR"/$PREFIX/lib/xen/boot
    cd ..
}

clean_libvirt() {
    rm -rf libvirt-dir
}

build_libvirt() {
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



# execution
export GIT
rm -rf "$INST_DIR"
mkdir -p "$INST_DIR"

clean_xen
clean_grub
clean_libvirt

build_xen
build_grub
build_libvirt
