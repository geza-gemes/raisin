#!/usr/bin/env bash

function verbose_echo() {
    if [[ $VERBOSE -eq 1 ]]
    then
        echo "$PREPEND" "$@"
    fi
}

function error_echo() {
    echo "$PREPEND" "$@" >&2
}

# Executed once at the beginning of the script
function common_init() {
    export BASEDIR=`pwd`
    export GIT=${GIT-git}
    export SUDO=${SUDO-sudo}
    export RAISIN_MAKE=${MAKE-make}
    export PREFIX=${PREFIX-/usr}
    export INST_DIR=${DESTDIR-dist}
    export PREPEND="[raisin]"

    INST_DIR=`readlink -f $INST_DIR`

    # execution
    if [[ $EUID -eq 0 ]]
    then
        export SUDO=""
    elif [[ ! -f `which sudo 2>/dev/null` ]]
    then
        error_echo "Raisin requires sudo to install build dependencies for you."
        error_echo "You can only build without it."
        export SUDO=""
    fi

    if [[ -z "$BASH_VERSINFO" || ${BASH_VERSINFO[0]} -lt 3 ||
        (${BASH_VERSINFO[0]} -eq 3 && ${BASH_VERSINFO[1]} -lt 2) ]]
    then
        error_echo "Raisin requires BASH 3.2 or newer."
        exit 1
    fi

    get_distro
    get_arch
    get_components
    get_tests

    verbose_echo "Distro: $DISTRO"
    verbose_echo "Arch: $RAISIN_ARCH"
    verbose_echo "Components: $COMPONENTS"

    for f in $COMPONENTS
    do
        source "$BASEDIR"/components/"$f"
    done
}

function get_components() {
    if [[ -z "$COMPONENTS" ]]
    then
        COMPONENTS="$ENABLED_COMPONENTS"
    fi

    if [[ -z "$COMPONENTS" ]]
    then
        local component
        for component in `cat "$BASEDIR"/components/series`
        do
            local capital
            capital=`echo $component | tr '[:lower:]' '[:upper:]'`
            if eval [[ ! -z \$"$capital"_REVISION ]]
            then
                COMPONENTS="$COMPONENTS $component"
                verbose_echo "Found component $component"
            fi
        done
    fi
    export COMPONENTS
}

function get_tests() {
    if [[ -z "$TESTS" ]]
    then
        TESTS="$ENABLED_TESTS"
    fi

    if [[ -z "$TESTS" ]]
    then
        local t
        for t in `cat "$BASEDIR"/tests/series`
        do
            TESTS="$TESTS $t"
            verbose_echo "Found test $t"
        done
    fi
    export TESTS
}

function get_distro() {
    os_VENDOR="unknown"

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
    elif [[ -f /etc/gentoo-release ]]
    then
        os_VENDOR="Gentoo"
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
            PKGTYPE="unknown"
            ;;
    esac

    export os_VENDOR os_RELEASE os_UPDATE os_CODENAME
    export DISTRO
    export PKGTYPE
}

function get_arch() {
    export RAISIN_ARCH=`uname -m | sed -e s/i.86/x86_32/ -e s/i86pc/x86_32/ -e \
                s/amd64/x86_64/ -e s/armv7.*/arm32/ -e s/armv8.*/arm64/ \
                -e s/aarch64/arm64/`
}

function _check-package-deb() {
    verbose_echo "Checking for package $1"

    if dpkg -s "$1" 2>/dev/null | grep -q "Status:.*installed"
    then
        return 0
    else
        return 1
    fi
}

function _install-package-deb() {
    $SUDO apt-get install -y $* > /dev/null
}

function _check-package-rpm() {
    verbose_echo "Checking for package $1"

    if rpm -q "$1" 2>&1 >/dev/null
    then
        return 0
    else
        return 1
    fi
}

function _install-package-rpm() {
    $SUDO yum install -y $* > /dev/null
}

function _check-package-unknown() {
    error_echo "I don't know distro $DISTRO. It might be missing packages."
    return 1
}

function _install-package-unknown() {
    error_echo "I don't know distro $DISTRO. Cannot install packages."
    return 1
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
            $SUDO update-rc.d $1 defaults || error_echo "Couldn't set $1 to start"
            ;;
            "Fedora" )
            $SUDO chkconfig --add $1 || error_echo "Couldn't set $1 to start"
            ;;
            * )
            error_echo "I don't know how to start initscripts on $DISTRO"
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
            $SUDO update-rc.d $1 remove || error_echo "Couldn't remove $1 from init"
            ;;
            "Fedora" )
            $SUDO chkconfig --del $1 || error_echo "Couldn't remove $1 from init"
            ;;
            * )
            error_echo "I don't know how to start initscripts on $DISTRO"
            return 1
            ;;
        esac
        shift 1
    done
}

function for_each_component () {
    local component
    local enabled
    local found

    for component in `cat "$BASEDIR"/components/series`
    do
        found=false
        for enabled in $COMPONENTS
        do
            if [[ $enabled = $component ]]
            then
                found=true
                break
            fi
        done
        if ! $found
        then
            verbose_echo "$component" is disabled
            continue
        fi
        if "$component"_skip
        then
            error_echo "$component" will be skipped on your platform
            continue
        fi

        echo "$PREPEND" calling "$component"_"$1"
        if [[ $VERBOSE -eq 0 ]]
        then
            "$component"_"$1" &> /dev/null
        else
            "$component"_"$1"
        fi
        echo "$PREPEND" "$component"_"$1" done
    done
}

function run_tests() {
    local t
    local enabled
    local found
    local ret

    for t in `cat "$BASEDIR"/tests/series`
    do
        found=false
        for enabled in $TESTS
        do
            if [[ $enabled = $t ]]
            then
                found=true
                break
            fi
        done
        if ! $found
        then
            verbose_echo "$t" is disabled
            continue
        fi

        source "$BASEDIR"/tests/$t
        ret=0
        if [[ $VERBOSE -eq 0 ]]
        then
            echo -n "$PREPEND test $t: "
            "$t"-test &>/dev/null || ret=1
            if [[ $ret -eq 0 ]]
            then
                echo "success"
            else
                echo "fail"
            fi
        else
            "$t"-test || ret=1
            if [[ $ret -eq 0 ]]
            then
                echo "$PREPEND test $t: success"
            else
                echo "$PREPEND test $t: fail"
            fi
        fi
        "$t"-cleanup

    done
}

function init_tests() {
    local -a missing

    check-package bridge-utils
    if [[ $DISTRO = "Debian" ]]
    then
        check-package busybox-static
    elif [[ $DISTRO = "Fedora" ]]
    then
        check-package busybox grub2 which
    else
        error_echo "I don't know distro $DISTRO. It might be missing packages."
    fi

    if [[ -n "${missing[@]}" ]]
    then
        verbose_echo "Installing ${missing[@]}"
        install-package "${missing[@]}"
    fi

    if ! ifconfig xenbr1 &>/dev/null
    then
        $SUDO brctl addbr xenbr1
        $SUDO ifconfig xenbr1 169.254.0.1 up
    fi
}

function _build_package_deb() {
    fakeroot bash ./scripts/mkdeb "$1"
}

function _build_package_rpm() {
    ./scripts/mkrpm "$1"
}

function build_package() {
    _build_package_"$PKGTYPE" "$1"
}

function install_package() {
    if [[ $DISTRO = "Debian" ]]
    then
        $SUDO dpkg -i "$1".deb
    elif [[  $DISTRO = "Fedora" || $DISTRO = "CentOS" ]]
    then
        $SUDO rpm -i --force "$1"-`git show --oneline | head -1 | cut -d " " -f 1`-0.$RAISIN_ARCH.rpm
    else
        error_echo "Don't know how to install packages on $DISTRO"
    fi
}

function uninstall_package() {
    if [[ $DISTRO = "Debian" ]]
    then
        $SUDO dpkg -r "$1"
    elif [[ $DISTRO = "Fedora" || $DISTRO = "CentOS" ]]
    then
        $SUDO rpm -e "$1"
    else
        error_echo "Don't know how to uninstall packages on $DISTRO"
    fi
}
