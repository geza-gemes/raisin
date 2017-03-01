#!/usr/bin/env bash

source ${RAISIN_PATH}/common-functions.sh

# $1 disk name
# $2 disk size
function allocate_disk() {
    local disk
    local size

    disk=$1
    size=$2

    size=$((size+511))
    size=$((size/512))

    dd if=/dev/zero of=$disk bs=512 count=$size
    sync
}

# $1 disk name
# print loop device name
function create_loop() {
    local disk
    local loop

    disk=`readlink -f $1`

    $SUDO losetup -f $disk
    loop=`$SUDO losetup -a | grep $disk | cut -d : -f 1`
    echo $loop
}

# $1 disk name
# print loop device name of the partition
function create_one_partition() {
    local disk
    local dev

    disk=$1
    echo -e "o\nn\np\n1\n\n\nw" | $SUDO fdisk $disk &>/dev/null
    dev=`$SUDO $BASEDIR/scripts/lopartsetup $disk | head -1 | cut -d ":" -f 1`
    echo $dev
}

# $1 dev name
function busybox_rootfs() {
    local dev
    local tmpdir

    dev=$1

    $SUDO mkfs.ext3 $dev

    tmpdir=`mktemp -d`
    $SUDO mount $dev $tmpdir
    $SUDO mkdir -p $tmpdir/bin
    $SUDO mkdir -p $tmpdir/sbin
    $SUDO mkdir -p $tmpdir/dev
    $SUDO mkdir -p $tmpdir/proc
    $SUDO mkdir -p $tmpdir/sys
    $SUDO mkdir -p $tmpdir/lib
    $SUDO mkdir -p $tmpdir/var
    $SUDO cp `which busybox` $tmpdir/bin
    $SUDO $tmpdir/bin/busybox --install $tmpdir/bin

    $SUDO umount $tmpdir
    $SUDO rmdir $tmpdir
}

function busybox_network_init() {
    local dev
    local tmpdir

    dev=$1
    tmpdir=`mktemp -d`

    $SUDO mount $dev $tmpdir
    $SUDO rm -f $tmpdir/bin/init
    tmpinit=`mktemp`
    cat >$tmpinit <<EOF
#!/bin/sh
mount -t proc proc /proc
mount -t sysfs sysfs /sys
ifconfig eth0 169.254.0.2 up
/bin/sh
EOF
    $SUDO mv $tmpinit $tmpdir/bin/init
    $SUDO chmod +x $tmpdir/bin/init

    $SUDO umount $tmpdir
    $SUDO rmdir $tmpdir
}

function bootloader_init() {
    local dev
    local devp
    local tmpdir

    dev=$1
    devp=$2
    tmpdir=`mktemp -d`

    $SUDO mount $devp $tmpdir
    $SUDO mkdir -p $tmpdir/boot/grub
    $SUDO cp "`get_host_kernel`" $tmpdir/boot
    $SUDO cp "`get_host_initrd`" $tmpdir/boot || true
    tmpgrubcfg=`mktemp`
    cat >$tmpgrubcfg <<EOF
set default="0"
set timeout=0

menuentry 'Xen Guest' {
 set root=hd0,1
 linux `get_host_kernel` root=/dev/xvda1 console=ttyS0
EOF
    $SUDO mv $tmpgrubcfg $tmpdir/boot/grub/grub.cfg
    if [[ -e `get_host_initrd` ]]
    then
        $SUDO echo "initrd `get_host_initrd`" >> $tmpdir/boot/grub/grub.cfg
    fi
    $SUDO echo "}" >> $tmpdir/boot/grub/grub.cfg

    tmpgrubdevmap=`mktemp`
    cat >$tmpgrubdevmap <<EOF
(hd0)   $dev
(hd0,1) $devp
EOF
    $SUDO mv $tmpgrubdevmap $tmpdir/boot/grub/device.map

    if [[ $DISTRO = "Debian" ]]
    then
        $SUDO grub-install --no-floppy \
            --grub-mkdevicemap=$tmpdir/boot/grub/device.map \
            --root-directory=$tmpdir $dev
    elif [[ $DISTRO = "Fedora" ]]
    then
        $SUDO grub2-install --no-floppy \
            --grub-mkdevicemap=$tmpdir/boot/grub/device.map \
            --root-directory=$tmpdir $dev
    else
        echo "$PREPEND I don't know how to install grub on $DISTRO"
    fi

    $SUDO umount $tmpdir
    $SUDO rmdir $tmpdir
}

function check_guest_alive() {
    local i
    i=0
    while ! ping -c 1 169.254.0.2 &> /dev/null
    do
        sleep 1
        i=$((i+1))
        if [[ $i -gt 60 ]]
        then
            echo $PREPEND Timeout connecting to guest
            return 1
        fi
    done
    return 0
}

function get_host_kernel() {
    echo "/boot/vmlinuz-`uname -r`"
}

function get_host_initrd() {
    if [[ $DISTRO = "Debian" ]]
    then
        echo "/boot/initrd.img-`uname -r`"
    elif [[ $DISTRO = "Fedora" ]]
    then
        echo "/boot/initramfs-`uname -r`".img
    else
        echo "$PREPEND I don't know how to find the initrd" >&2
        exit 1
    fi
}
