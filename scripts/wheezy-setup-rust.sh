#!/bin/bash

# sets up a wheezy rootfs for rust builds (part II)

#
# run this script in freshly debootstrapped Wheezy rootfs
#
# $ debootstrap wheezy /chroot/wheezy/rust
#
# $ systemd-nspawn
#     /on-openwrt/scripts/wheezy-setup-rust-root.sh
#

: ${DIST_DIR:=~/dist}
: ${SRC_DIR:=~/src}

## setup dropbox_uploader.sh
dropbox_uploader.sh

## fetch rust source
git clone --recursive https://github.com/rust-lang/rust $SRC_DIR
cd $SRC_DIR
mkdir build
cd build
# sanity check
../configure  --enable-ccache

## prepare snap and dist folders
mkdir -p $DIST_DIR
