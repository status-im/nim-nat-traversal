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

Install it using Nimble:

```bash
nimble install
```

## Dependencies

- [nim-result](https://github.com/arnetheduck/nim-result)

## Usage

See the [examples](examples) directory for some generic usage.

A real-world example, complete with periodic port mapping renewal in a separate thread, is available in [nim-eth](https://github.com/status-im/nim-eth/blob/32bb1f35d75f226938fc560e15690e3251d7f246/eth/net/nat.nim) and [nimbus](https://github.com/status-im/nimbus/blob/a89b0d677a263cac38987ce39b8b066a746d3b99/nimbus/nimbus.nim#L61).

By default, your code will be linked to bundled static libraries. If you want to dynamically link against your system libraries,
pass the "-d:miniupnpcUseSystemLibs" and/or "-d:libnatpmpUseSystemLibs" flags to the Nim compiler.

Let's see both scenarios in action:

```bash
nimble buildBundledLibs

# statically linked against the bundled libminiupnpc.a:
nim c -r -f examples/miniupnpc_test.nim
# dynamically linked against the system libminiupnpc.so:
nim c -r -f -d:miniupnpcUseSystemLibs examples/miniupnpc_test.nim

# statically linked against the bundled libnatpmp.a:
nim c -r -f examples/natpmp_test.nim
# dynamically linked against the system libnatpmp.so:
nim c -r -f -d:libnatpmpUseSystemLibs examples/natpmp_test.nim
```

## TODO

miniupnpc:

- add IPv6 pinhole helper procs for the Miniupnp type

## License

These wrappers are licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT

or

* Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. These files may not be copied, modified, or distributed except according to those terms.

