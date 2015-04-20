#!/usr/bin/env bash

# Executed once at the beginning of the script
function common_init() {
    export BASEDIR=`pwd`
    export GIT=${GIT-git}
    export SUDO=${SUDO-sudo}
    export RAISIN_MAKE=${MAKE-make}
    export PREFIX=${PREFIX-/usr}
    export INST_DIR=${DESTDIR-dist}
    
    INST_DIR=`readlink -f $INST_DIR`
    
    # execution
    if [[ $EUID -eq 0 ]]
    then
        export SUDO=""
    elif [[ ! -f `which sudo 2>/dev/null` ]]
    then
        echo "Raisin requires sudo to install build dependencies for you."
        echo "Please install sudo, then run this script again."
        exit 1
    fi

    if [[ -z "$BASH_VERSINFO" || ${BASH_VERSINFO[0]} -lt 3 ||
        (${BASH_VERSINFO[0]} -eq 3 && ${BASH_VERSINFO[1]} -lt 2) ]]
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
    if [[ -x "`which lsb_release 2>/dev/null`" ]]
    then
        os_VENDOR=`lsb_release -i -s`
        os_RELEASE=`lsb_release -r -s`
        os_CODENAME=`lsb_release -c -s`
        os_UPDATE=""
    elif [[ -r /etc/redhat-release ]]
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
            if [[ -n "`grep -i \"$r\" /etc/redhat-release`" ]]
            then
                ver=`sed -e 's/^.* \([0-9].*\) (\(.*\)).*$/\1\|\2/' /etc/redhat-release`
                os_CODENAME=${ver#*|}
                os_RELEASE=${ver%|*}
                os_UPDATE=${os_RELEASE##*.}
                os_RELEASE=${os_RELEASE%.*}
                break
            fi
        done
    elif [[ -r /etc/SuSE-release ]]
    then
        for r in "openSUSE" "SUSE Linux"
        do
            os_VENDOR="$r"

            if [[ -n "`grep -i \"$r\" /etc/SuSE-release`" ]]
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
    elif [[ -f /etc/debian_version && `cat /proc/version` =~ "Debian" ]]
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
            PKGTYPE="deb"
            ;;
        "Fedora" )
            DISTRO="Fedora"
            PKGTYPE="rpm"
            ;;
        "SUSE"* )
            DISTRO="SUSE"
            PKGTYPE="rpm"
            ;;
        "OpenSUSE"* | "openSUSE"* )
            DISTRO="openSUSE"
            PKGTYPE="rpm"
            ;;
        "Red"* | "CentOS"* )
            DISTRO="CentOS"
            PKGTYPE="rpm"
            ;;
        *)
            DISTRO=$os_VENDOR
            ;;
    esac

    export os_VENDOR os_RELEASE os_UPDATE os_CODENAME
    export DISTRO
    export PKGTYPE
}

function get_arch() {
    export ARCH=`uname -m | sed -e s/i.86/x86_32/ -e s/i86pc/x86_32/ -e \
                s/amd64/x86_64/ -e s/armv7.*/arm32/ -e s/armv8.*/arm64/ \
                -e s/aarch64/arm64/`
}

function _check-package-deb() {
    if [[ $VERBOSE -eq 1 ]]
    then
        echo "Checking for package ${args[0]}"
    fi

    if dpkg -s "$1" 2>/dev/null | grep -q "Status:.*installed"
    then
        return 0
    else
        return 1
    fi
}

function _install-package-deb() {
    $SUDO apt-get install -y $*
}

function _check-package-rpm() {
    if [[ $VERBOSE -eq 1 ]]
    then
        echo "Checking for package $1"
    fi

    if rpm -q "$1" 2>&1 >/dev/null
    then
        return 0
    else
        return 1
    fi
}

function _install-package-rpm() {
    $SUDO yum install -y $*
}

# Modifies inherited variable "missing"
function check-package() {
    for p in $*
    do
        if ! _check-package-${PKGTYPE} $p
        then
            missing+=("$p")
        fi
    done

}

function install-package() {
    _install-package-${PKGTYPE} $*
}

function start_initscripts() {
    while [[ $# -ge 1 ]]
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
    while [[ $# -ge 1 ]]
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
        if [[ $VERBOSE -eq 1 ]]
        then
            echo -n "$capital"_REVISION =" "
            eval echo \$"$capital"_REVISION
        fi
        if eval [[ ! -z \$"$capital"_REVISION ]]
        then
            if [[ $VERBOSE -eq 1 ]]
            then
                echo calling "$component"_"$1"
            fi
            "$component"_"$1"
            if [[ $VERBOSE -eq 1 ]]
            then
                echo "$component"_"$1" done
            fi
        fi
    done
}

function build_package() {
    if [[ $DISTRO = "Debian" ]]
    then
        ./scripts/mkdeb "$1"
    elif [[  $DISTRO = "Fedora" ]]
    then
        ./scripts/mkrpm "$1"
    else
        echo "Don't know how to create packages for $DISTRO"
    fi
}

function install_package() {
    if [[ $DISTRO = "Debian" ]]
    then
        $SUDO dpkg -i "$1".deb
    elif [[  $DISTRO = "Fedora" ]]
    then
        $SUDO rpm -i --force "$1"-`git show --oneline | head -1 | cut -d " " -f 1`-0.$ARCH.rpm
    else
        echo "Don't know how to install packages on $DISTRO"
    fi
}

function uninstall_package() {
    if [[ $DISTRO = "Debian" ]]
    then
        $SUDO dpkg -r "$1"
    elif [[ $DISTRO = "Fedora" ]]
    then
        $SUDO rpm -e "$1"
    else
        echo "Don't know how to uninstall packages on $DISTRO"
    fi
}
