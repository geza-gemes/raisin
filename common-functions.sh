#!/usr/bin/env bash

# Executed once at the beginning of the script
function common_init() {
    export BASEDIR=`pwd`
    export GIT=${GIT-git}
    export SUDO=${SUDO-sudo}
    export MAKE=${MAKE-make}
    export PREFIX=${PREFIX-/usr}
    export INST_DIR=${DESTDIR-dist}
    
    INST_DIR=`readlink -f $INST_DIR`
    
    # execution
    if test $EUID -eq 0
    then
        export SUDO=""
    elif test ! -f `which sudo 2>/dev/null`
    then
        echo "Raisin requires sudo to install build dependencies for you."
        echo "Please install sudo, then run this script again."
        exit 1
    fi

    if test -z "$BASH_VERSINFO" || test ${BASH_VERSINFO[0]} -lt 3 ||
       (test ${BASH_VERSINFO[0]} -eq 3 && test ${BASH_VERSINFO[1]} -lt 2)
    then
        echo "Raisin requires BASH 3.2 or newer."
        exit 1
    fi

    get_distro
    get_arch

    for f in `cat "$BASEDIR"/components/series`
    do
        source "$BASEDIR"/components/"$f"
    done
}

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
    while test $# -ge 1
    do
        case $DISTRO in
            "Debian" )
            $SUDO update-rc.d $1 defaults || echo "Couldn't set $1 to start"
            ;;
            "Fedora" )
            $SUDO chkconfig --add $1 || echo "Couldn't set $1 to start"
            ;;
            * )
            echo "I don't know how to start initscripts on $DISTRO"
            return 1
            ;;
        esac
        shift 1
    done
}

function stop_initscripts() {
    while test $# -ge 1
    do
        case $DISTRO in
            "Debian" )
            $SUDO update-rc.d $1 remove || echo "Couldn't remove $1 from init"
            ;;
            "Fedora" )
            $SUDO chkconfig --del $1 || echo "Couldn't remove $1 from init"
            ;;
            * )
            echo "I don't know how to start initscripts on $DISTRO"
            return 1
            ;;
        esac
        shift 1
    done
}

function for_each_component () {
    for component in `cat "$BASEDIR"/components/series`
    do
        capital=`echo $component | tr '[:lower:]' '[:upper:]'`
        if test "`eval echo \$"$capital"_UPSTREAM_URL`"
        then
            "$component"_"$1"
        fi
    done
}

function build_package() {
    if test $DISTRO = "Debian"
    then
        ./mkdeb "$1"
    elif test $DISTRO = "Fedora"
    then
        ./mkrpm "$1"
    else
        echo "Don't know how to create packages for $DISTRO"
    fi
}

function install_package() {
    if test $DISTRO = "Debian"
    then
        $SUDO dpkg -i "$1".deb
    elif test $DISTRO = "Fedora"
    then
        $SUDO rpm -i --force "$1"-`git show --oneline | head -1 | cut -d " " -f 1`-0.$ARCH.rpm
    else
        echo "Don't know how to install packages on $DISTRO"
    fi
}

function uninstall_package() {
    if test $DISTRO = "Debian"
    then
        $SUDO dpkg -r "$1"
    elif test $DISTRO = "Fedora"
    then
        $SUDO rpm -e "$1"
    else
        echo "Don't know how to uninstall packages on $DISTRO"
    fi
}
