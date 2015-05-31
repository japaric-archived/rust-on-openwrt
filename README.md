# `Rust on OpenWRT (MIPS edition)`

This how-to covers:

- Setting up a cross-compilation environment
- Cross compiling a "Hello, world!" Rust program
- Configuring cargo for cross-compilation

Although this how-to uses a MIPS based router as the target device, the steps outlined here should
be applicable to other targets/architectures.

## Cross compilation requirements

In general to cross compile Rust programs you need four things:

- Know what's the `rustc` target triple for your device, e.g. `arm-unknown-linux-gnueabi` or
  `mips-unknown-linux-gnu`.
- A `gcc` cross-compiler, because `rustc` uses `gcc` as a linker
- Cross compiled C dependencies (libraries) that will be linked to your program, at the very least
  `libc`
- Rust dependencies (crates) that will be linked to your program, most likely the `std` crate will
  be one of them.

Once you have all those, cross compiling is as easy as passing `--target=$TRIPLE` to `rustc`.

We can get the first three things from [the OpenWRT SDK], so let's install that.

[the OpenWRT SDK]: http://wiki.openwrt.org/doc/howto/obtain.firmware.sdk

## Installing the OpenWRT SDK

If you already have the SDK installed in your system, you can skip this section.

The SDK can be downloaded from https://downloads.openwrt.org, but you need to know which OpenWRT
release is running on your device and what's your device "codename". You can find this information
by looking at the `/etc/openwrt_release` file in your OpenWRT device:

```
# On your OpenWRT device
$ cat /etc/openwrt_release
DISTRIB_ID="OpenWrt"
DISTRIB_RELEASE="14.07"  # <-- this is the release
DISTRIB_REVISION="r42625"
DISTRIB_CODENAME="barrier_breaker"
DISTRIB_TARGET="ar71xx/generic"  # <-- this is the codename
DISTRIB_DESCRIPTION="OpenWrt Barrier Breaker 14.07"
DISTRIB_TAINTS=""
```

The SDK for your device will be under the folder `$RELEASE/$CODENAME` of the download website. In
my case the full URL to the right SDK is:

```
https://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
                                              ~~~~~~~~~~~~~~~~~~~~
```

After downloading the SDK, extract it using `tar`.

```
$ pwd
/home/japaric/openwrt

$ ls *.tar.bz2
OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2

$ tar jxf *.tar.bz2 --strip-components=1
```

## Verifying that the SDK works

To verify that you got the right SDK, we'll compile a "Hello, world!" C program, and run it on the
OpenWRT device.

When working with the OpenWRT SDK you'll need to set these two environment variables, and be sure
to keep them in your environment for the rest of this how-to.

```
# Make sure you are in the OpenWRT SDK folder
$ pwd
/home/japaric/openwrt

$ export STAGING_DIR="$PWD/staging_dir"

$ export PATH="$PWD/$(echo staging_dir/toolchain-*/bin):$PATH"
```

You should now be able to call the cross compiler, which should be in your `PATH`:

```
$ mips-openwrt-linux-gcc -v
gcc version 4.8.3 (OpenWrt/Linaro GCC 4.8-2014.04 r42625)
```

Now let's compile a "Hello, world!" C program:

```
$ cat hello.c
#include <stdio.h>

int main() {
    printf("Hello, world!");
}

$ mips-openwrt-linux-gcc hello.c

$ file a.out
a.out: ELF 32-bit MSB executable, MIPS, MIPS32 rel2 version 1, dynamically linked, interpreter /lib/ld-uClibc.so.0, not stripped
```

Let's test this program on the OpenWRT device:

```
$ scp a.out root@openwrt:~

$ ssh root@openwrt ./a.out
Hello, world!
```

So far, so good.

The SDK contains the toolchain, (`uC`)`libc` and other C libraries cross compiled for the target
device. Now we must find out...

## What's the `rustc` target triple for my device?

The easiest way to get the target triple for your device is to look at the prefix of the OpenWRT
toolchain and "translate" that to a triple that `rustc` understands. In my case, the prefix is
`mips-openwrt-linux-`(`gcc`), this means that the `rustc` target triple for my device is
`mips-unknown-linux-gnu`.

Here's a "dictionary" for other toolchains prefixes:

```
# Toolchain prefix                -> `rustc` target triple
arm-openwrt-linux-uclibcgnueabi-  -> arm-unknown-linux-gnueabi
mips-openwrt-linux-               -> mips-unknown-linux-gnu
mipsel-openwrt-linux-             -> mipsel-unknown-linux-gnu
```

And [here's a list] of all the triples that `rustc` supports (as of 1.0.0).

[here's a list]: https://github.com/rust-lang/rust/tree/1.0.0/mk/cfg

## Getting a cross-compiled `std` crate

Most Rust programs depend on the `std` crate, so we'll need a version of `std` that has been cross
compiled for the `mips-unknown-linux-gnu` target, that's our last requirement.

There are two ways to get the `std` crate:

- You can compile it yourself from rust source, or

- You can use one of my pre-compiled versions.

The first option is the sure way to get a `std` crate that will work on your device, but is also
the most time-consuming. On the other hand, the second option is the easiest but may not work for
your device (because it was compiled for a specific device).

In this how-to we'll pick the second route, if that doesn't work for you or if you want to try the
other route, then check the [scripts](/scripts) folder for more information about how to cross
compile the `std` crate from source.

You can get the pre-compiled crates from [here].

[here]: https://www.dropbox.com/sh/e5fy42812q4am68/AACKAMp_Otg4Ii9QJPXq-PAZa?dl=0

It's very important that the `rustc` version that you have installed in your host matches the
version of the cross-compiled crates that you will download. In this how-to we'll use the 1.0.0
version of `rustc`. So make sure your `rustc` version is the 1.0.0 one:

```
rustc 1.0.0 (a59de37e9 2015-05-13) (built 2015-05-14)
```

Next fetch the 1.0.0 version of the cross compiled crates:

```
$ wget $SOME_URL/1.0.0/rust-$DATE-$HASH-mips-unknown-linux-gnu-$HASH.tar.gz
```

You'll need to extract the tarball in the `rustlib` directory of your Rust distribution. For
`rustup.sh` users that would be the `/usr/local/lib/rustlib` path, and for `multirust` users that
would be the `~/.multirust/toolchains/1.0.0/lib/rustlib` path.

Ultimately your `lib` folder should look like this:

```
# I'm using multirust, use the right path for your setup
$ tree ~/.multirust/toolchains/1.0.0/lib
lib
├── libarena-4e7c5e5c.so
├── (..)
└── rustlib
    ├── mips-unknown-linux-gnu  <- this the folder that you just extracted
    │   └── lib
    │       ├── libarena-4e7c5e5c.rlib
    │       └── (..)
    └── x86_64-unknown-linux-gnu  <- this is part of the original distribution
        └── lib
            ├── libarena-4e7c5e5c.rlib
            └── (..)

```

## Hello, Rust!

Alright, after a very long setup, we can finally cross compile a "Hello, world!" Rust program.

```
$ cat hello.rs
fn main() {
    println!("Hello, world!");
}
```

I mentioned in the requirements that `rustc` will use `gcc` as linker when compiling programs, so
we'll need to tell `rustc` what's the right `gcc` to use when cross compiling, otherwise it will,
by default, use the `cc` linker and fail spectacularly:

```
$ rustc --target=mips-unknown-linux-gnu -C linker=mips-openwrt-linux-gcc hello.rs
$ file hello
hello: ELF 32-bit MSB shared object, MIPS, MIPS32 rel2 version 1 (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, not stripped
```

Now, let's test the binary on the OpenWRT device. You may need to install `libpthread` and `librt`
on OpenWRT your device if you don't have them installed:

```
$ scp hello root@openwrt:~
$ ssh root@openwrt

# On the OpenWRT device
$ opkg install libpthread
$ opkg install librt
$ ./hello
Hello, world!
```

It's interesting to compare the shared libraries required by the Rust program vs the ones required
by the C program. You can do this using the `LD_TRACE_LOADED_OBJECTS` environment variable:

```
# On the OpenWRT device
$ LD_TRACE_LOADED_OBJECTS=1 ./a.out
        libgcc_s.so.1 => /lib/libgcc_s.so.1 (0x77426000)
        libc.so.0 => /lib/libc.so.0 (0x773b9000)
        ld-uClibc.so.0 => /lib/ld-uClibc.so.0 (0x7744a000)

$ LD_TRACE_LOADED_OBJECTS=1 ./hello
        libdl.so.0 => /lib/libdl.so.0 (0x77330000)
        libpthread.so.0 => /lib/libpthread.so.0 (0x7730a000)
        librt.so.0 => /lib/librt.so.0 (0x772f6000)
        libgcc_s.so.1 => /lib/libgcc_s.so.1 (0x772d2000)
        libc.so.0 => /lib/libc.so.0 (0x77265000)
        ld-uClibc.so.0 => /lib/ld-uClibc.so.0 (0x77344000)
        libm.so.0 => /lib/libm.so.0 (0x7723f000)
```

NOTE: If you compile `hello.rs` with `-C lto`, the binary won't depend on `libm` or `librt`.

## Cargo all the things

For non-toy programs, you'll want to use `cargo` to handle your program dependencies and the
multiple `rustc` calls required to build it.

Just like with `rustc`, to cross compile you just need to pass the `--target=$TRIPLE` flag to
`cargo`, but there is one extra thing that we must do before it just works.

By default, `cargo` will use `cc` as linker and `ar` as archiver for native and cross compilation.
We'll have to instruct `cargo` to use the right prefixed tools for cross compilation; that's done
with a [`config`] file.

[`config`]: http://doc.crates.io/config.html

```
$ cat ~/.cargo/config
[target.mips-unknown-linux-gnu]
ar = "mips-openwrt-linux-ar"
linker = "mips-openwrt-linux-gcc"
```

Now we can use cargo to cross compile.

```
$ cargo new --bin hello
$ cd hello
$ cargo build --target=mips-unknown-linux-gnu
Compiling hello v0.1.0 (file:///home/japaric/tmp/hello)
```

The final binary will be under the `target/mips-unknown-linux-gnu/debug` folder.

```
$ file target/mips-unknown-linux-gnu/debug/hello
target/mips-unknown-linux-gnu/debug/hello: ELF 32-bit MSB shared object, MIPS, MIPS32 rel2 version 1 (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, not stripped
```

Finally, let's check that the binary actually works:

```
$ scp target/mips-unknown-linux-gnu/debug/hello root@openwrt:~
$ ssh root@openwrt ./hello
Hello, world!
```

---

That's all for this how-to, happy cross compiling!
