#!/usr/bin/env bash

build() {
    if [[ $YES != "y" ]]
    then
        echo "Do you want Raisin to automatically install build time dependencies for you? (y/n)"
        while read answer
        do
            if [[ "$answer" = "n" ]]
            then
                NO_DEPS=1
                break
            elif [[ "$answer" = "y" ]]
            then
                break
            else
                echo "Reply y or n"
            fi
        done
    fi

    mkdir -p "$INST_DIR" &>/dev/null
    install_dependencies git
    if [[ $DISTRO = "Fedora" ]]
    then
        install_dependencies rpm-build
    fi
    # build and install under $DESTDIR
    for_each_component clean
    for_each_component build
    
    build_package xen-system
}

unraise() {
    for_each_component clean

    uninstall_package xen-system
    for_each_component unconfigure

    rm -rf "$INST_DIR"
}

install() {
    # need single braces for filename matching expansion
    if [ ! -f xen-sytem*rpm ] && [ ! -f xen-system*deb ]
    then
        echo You need to raise build first.
        exit 1
    fi
    install_package xen-system
}

configure() {
    if [[ $YES != "y" ]]
    then
        echo "Proceeding we'll make changes to the running system,"
        echo "are you sure that you want to continue? (y/n)"
        while read answer
        do
            if [[ "$answer" = "n" ]]
            then
                exit 0
            elif [[ "$answer" = "y" ]]
            then
                break
            else
                echo "Reply y or n"
            fi
        done
    fi

    for_each_component configure
}

