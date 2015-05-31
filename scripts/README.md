# `scripts`

Scripts to cross compile "standard" Rust crates, like `std` and `core`, for the
`mips-unknown-linux-gnu` target.

For reproducibility, these scripts target Debian Wheezy.

Here's an overview of what the scripts do:

- Download the OpenWRT SDK. There are several SDKs, one per device "family" supported by OpenWRT.
  This script defaults to the Barrier Breaker release for the ar71xx/generic target, but this can
  be overridden with the `SDK_URL` variable.

- Fetch the Rust source, and [patch](/scripts/remove-mno-compact-eh-flag.patch) it to not pass a
  compile flag that's not recognized by `gcc`.

- `configure` the Rust build system to target the `mips-unknown-linux-gnu` triple.

- `make && make install`

- Package only the cross compiled crates, which are found in the
  `lib/rustlib/mips-unknown-linux-gnu` folder.
