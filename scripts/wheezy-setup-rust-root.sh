#!/bin/bash

# sets up a wheezy rootfs for rust builds (part I)

#
# run this script in freshly debootstrapped Wheezy rootfs
#
# $ debootstrap wheezy /chroot/wheezy/rust
#
# $ systemd-nspawn
#     /on-openwrt/scripts/wheezy-setup-rust-root.sh
#

: ${SDK_URL:=https://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2}

set -x
set -e

## install g++
apt-get update -qq
apt-get install -qq build-essential g++-4.7
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 50 --slave /usr/bin/g++ g++ /usr/bin/g++-4.7

## install dropbox_uploader.sh
apt-get install -qq curl git
cd ~
git clone https://github.com/andreafabrizi/Dropbox-Uploader
cd /usr/bin
cp /root/Dropbox-Uploader/dropbox_uploader.sh .

## install rust build dependencies
apt-get install -qq ccache file python

## install OpenWRT SDK
cd /
mkdir openwrt
cd openwrt
wget $SDK_URL
tar jxf *.tar.bz2 --strip-components=1
rm *.tar.bz2

## add some symlinks required by the rust build
cd staging_dir/toolchain-*/bin
ln -s mips-openwrt-linux-gcc mips-linux-gnu-gcc
ln -s mips-openwrt-linux-ar mips-linux-gnu-ar

## add rustbuild user
useradd -m rustbuild
