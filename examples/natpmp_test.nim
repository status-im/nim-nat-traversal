# Copyright (c) 2019 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import nat_traversal/natpmp, result, strformat

template checkError(expr, body: untyped): untyped =
  block:
    let res {.inject.} = expr
    if res.isOk:
      body
    else:
      echo res.error
      quit(1)

template checkError(expr: untyped): untyped =
  checkError expr:
    discard

echo "NAT-PMP test"
when defined(libnatpmpUseSystemLibs):
  echo "(using the system's libnatpmp.so)"
else:
  echo "(statically linked to the bundled libnatpmp.a)"
var npmp = newNatPmp()
checkError npmp.init()
checkError npmp.externalIPAddress():
  echo "External IP address: ", res.value

## enable this if you don't already have a redirection for port 64000:
if false:
  let port = 64000.cushort
  checkError npmp.addPortMapping(port, port, TCP, 3600):
    let eport = res.value
    echo &"Mapped external port {eport} to internal port {port}."
    checkError npmp.deletePortMapping(eport, port, TCP):
      echo "Deleted port mapping."

