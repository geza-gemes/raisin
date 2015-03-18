#!/usr/bin/env bash

function get_distro() {
    if test -x "`which lsb_release 2>/dev/null`"
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
        "Debian"* | "Ubuntu"* | "LinuxMint"* )
            DISTRO="Debian"
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

function install_dependencies() {
    if test "$NO_DEPS" && test "$NO_DEPS" -eq 1
    then
        echo "Not installing any dependencies, as requested."
        echo "Depency list: $*"
        return 0
    fi
    case $DISTRO in
        "Debian" )
        $SUDO apt-get install -y $*
        ;;
        "Fedora" )
        $SUDO yum install -y $*
        ;;
        * )
        echo "I don't know how to install dependencies on $DISTRO"
        ;;
    esac
}

function start_initscripts() {
    case $DISTRO in
        "Debian" )
        while test $# -ge 1
        do
            $SUDO update-rc.d $1
            shift 1
        done
        ;;
        * )
        echo "I don't know how to start initscripts on $DISTRO"
        ;;
    esac
}

