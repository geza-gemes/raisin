#!/usr/bin/env bash

set -e

source config
source common-functions.sh

common_init

for_each_component clean
for_each_component unconfigure

for i in `cat /var/log/raisin.log 2>/dev/null`
do
    if test -f /"$i"
    then
        rm -f /"$i"
    fi
done
for i in `cat /var/log/raisin.log 2>/dev/null`
do
    if test -d /"$i"
    then
        rmdir --ignore-fail-on-non-empty /"$i"
    fi
done

rm -rf /var/log/raisin.log
rm -rf "$INST_DIR"

