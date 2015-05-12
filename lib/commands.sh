#!/usr/bin/env bash

function check-builddep() {
    local -a missing

    check-package git

    if [[ $PKGTYPE = "rpm" ]]
    then
        check-package rpm-build
    elif [[ $PKGTYPE = "deb" ]]
    then
        check-package fakeroot
    fi

    for_each_component check_package

    if [[ -n "${missing[@]}" ]]
    then
        echo "Missing packages: ${missing[@]}"
        if [[ "$YES" = "n" ]]
        then
            return
        elif [[ "$YES" != "y" ]]
        then
            echo "Do you want Raisin to automatically install them for you? (y/n)"
            while read answer
            do
                if [[ "$answer" = "n" ]]
                then
                    echo "Please install, or run ./raise install-builddep"
                    exit 1
                elif [[ "$answer" = "y" ]]
                then
                    break
                else
                    echo "Reply y or n"
                fi
            done
        fi

        echo "Installing..."
        install-package "${missing[@]}"
    fi
}

function install-builddep() {
    YES=y check-builddep
}

function build() {
    check-builddep
    
    mkdir -p "$INST_DIR" &>/dev/null

    # build and install under $DESTDIR
    for_each_component build
    
    build_package xen-system
}

function unraise() {
    for_each_component clean

    uninstall_package xen-system
    for_each_component unconfigure

    rm -rf "$INST_DIR"
}

function install() {
    # need single braces for filename matching expansion
    if [ ! -f xen-sytem*rpm ] && [ ! -f xen-system*deb ]
    then
        echo You need to raise build first.
        exit 1
    fi
    install_package xen-system
}

function configure() {
    if [[ "$YES" = "n" ]]
    then
        return
    elif [[ "$YES" != "y" ]]
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

function test() {
    init_tests
    run_tests
}
