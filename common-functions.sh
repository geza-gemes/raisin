#!/usr/bin/env bash

function install_dependencies() {
    case $DISTRO in
        "Debian" | "Ubuntu" )
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
