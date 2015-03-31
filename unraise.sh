#!/usr/bin/env bash

set -e

source config
source common-functions.sh


# start execution
common_init

for_each_component clean

uninstall_package xen-system
for_each_component unconfigure

rm -rf "$INST_DIR"
