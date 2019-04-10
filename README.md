# Nim NAT traversal using wrappers for miniupnpc and libnatpmp

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

## Installation

This repository uses submodules for
[miniupnp](https://github.com/miniupnp/miniupnp) and
[libnatpmp](https://github.com/miniupnp/libnatpmp), so either clone it all in
one go with `git clone --recurse-submodules <REPO_URL>` or clone it normally
and then run `git submodule update --init --recursive`.

Custom task that builds the static libraries before installation (optional):

```bash
nimble installWithBundledLibs
```

Regular `nimble install` will be enough, if you're planning on using the system libraries.

## Dependencies

- [nim-result](https://github.com/arnetheduck/nim-result)

## Usage

See the [examples](examples) directory.

By default, your code will be linked to bundled static libraries. If you want to dynamically link against your system libraries,
pass the "-d:miniupnpcUseSystemLibs" flag to the Nim compiler.

Let's see both scenarios in action:

```bash
nimble buildBundledLibs
# statically linked against the bundled libminiupnpc.a:
nim c -r -f examples/miniupnpc_test.nim
# dynamically linked agains the system libminiupnpc.so:
nim c -r -f -d:miniupnpcUseSystemLibs examples/miniupnpc_test.nim
```

## TODO

miniupnpc:

- add IPv6 pinhole helper procs for the Miniupnp type

- "importc" constants from headers instead of copying them

libnatpmp:

- add wrapper

## License

These wrappers are licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT

or

* Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. These files may not be copied, modified, or distributed except according to those terms.

