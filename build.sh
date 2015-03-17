#!/usr/bin/env bash

source config

export PWD=`pwd`
export GIT=${GIT-git}
export SUDO=${SUDO-sudo}
export MAKE=${MAKE-make -j}
export PREFIX=${PREFIX-/usr}
export INST_DIR=${DESTDIR-dist}

INST_DIR=`readlink -f $INST_DIR`
mkdir -p "$INST_DIR" &>/dev/null

source xen.sh
source grub.sh
source libvirt.sh

function get_distro() {
    if test -x "`which lsb_release`"
    then
        os_VENDOR=`lsb_release -i -s`
        os_RELEASE=`lsb_release -r -s`
        os_CODENAME=`lsb_release -c -s`
        os_UPDATE=""
    elif test -r /etc/redhat-release
    then
        # Red Hat Enterprise Linux Server release 5.5 (Tikanga)
        # Red Hat Enterprise Linux Server release 7.0 Beta (Maipo)
        # CentOS release 5.5 (Final)
        # CentOS Linux release 6.0 (Final)
        # Fedora release 16 (Verne)
        # XenServer release 6.2.0-70446c (xenenterprise)
        os_CODENAME=""
        for r in "Red Hat" "CentOS" "Fedora" "XenServer"; do
            os_VENDOR="$r"
            if test -n "`grep -i \"$r\" /etc/redhat-release`"
            then
                ver=`sed -e 's/^.* \([0-9].*\) (\(.*\)).*$/\1\|\2/' /etc/redhat-release`
                os_CODENAME=${ver#*|}
                os_RELEASE=${ver%|*}
                os_UPDATE=${os_RELEASE##*.}
                os_RELEASE=${os_RELEASE%.*}
                break
            fi
        done
    elif test -r /etc/SuSE-release
    then
        for r in "openSUSE" "SUSE Linux"
        do
            os_VENDOR="$r"

            if test -n "`grep -i \"$r\" /etc/SuSE-release`"
            then
                os_CODENAME=`grep "CODENAME = " /etc/SuSE-release | \
                             sed 's:.* = ::g'`
                os_RELEASE=`grep "VERSION = " /etc/SuSE-release | \
                            sed 's:.* = ::g'`
                os_UPDATE=`grep "PATCHLEVEL = " /etc/SuSE-release | \
                           sed 's:.* = ::g'`
                break
            fi
        done
    # If lsb_release is not installed, we should be able to detect Debian OS
    elif test -f /etc/debian_version && [[ `cat /proc/version` =~ "Debian" ]]
    then
        os_VENDOR="Debian"
        os_CODENAME=`awk '/VERSION=/' /etc/os-release | sed 's/VERSION=//' | \
                     sed -r 's/\"|\(|\)//g' | awk '{print $2}'`
        os_RELEASE=`awk '/VERSION_ID=/' /etc/os-release | sed 's/VERSION_ID=//' \
                    | sed 's/\"//g'`
    fi

    # Simply distro version string
    case "$os_VENDOR" in
        "Ubuntu"* | "LinuxMint"* )
            DISTRO="Ubuntu"
            ;;
        "SUSE"* )
            DISTRO="SUSE"
            ;;
        "OpenSUSE"* | "openSUSE"* )
            DISTRO="openSUSE"
            ;;
        "Red"* | "CentOS"* )
            DISTRO="CentOS"
            ;;
        *)
            DISTRO=$os_VENDOR
            ;;
    esac

    export os_VENDOR os_RELEASE os_UPDATE os_CODENAME
    export DISTRO
}

function get_arch() {
    export ARCH=`uname -m | sed -e s/i.86/x86_32/ -e s/i86pc/x86_32/ -e \
                s/amd64/x86_64/ -e s/armv7.*/arm32/ -e s/armv8.*/arm64/ \
                -e s/aarch64/arm64/`
}


# execution
if test $EUID -eq 0
then
    export SUDO=""
elif test ! -f `which sudo`
then
    echo "Raixen requires sudo to install build dependencies for you."
    echo "Please install sudo, then run this script again."
    exit 1
fi

get_distro
get_arch

if test "$XEN_UPSTREAM_REVISION"
then
    xen_clean
    xen_build
fi
if test "$GRUB_UPSTREAM_REVISION"
then
    grub_clean
    grub_build
fi
if test "$LIBVIRT_UPSTREAM_REVISION"
then
    libvirt_clean
    libvirt_build
fi
