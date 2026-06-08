# Copyright (c) 2019-2022 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import nat_traversal/pcpnatpmp, strformat

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

echo "PCP/NAT-PMP test"
when defined(libpcpnatpmpUseSystemLibs):
  echo "(using the system's libpcpnatpmp.so)"
else:
  echo "(statically linked to the bundled libpcpnatpmp.a)"

var pcp = newPcpNatPmp()
checkError pcp.init()

## enable this if you want to exercise actual port mapping (requires a PCP- or
## NAT-PMP-capable router on the local network):
if false:
  let port = 64000.uint16
  checkError pcp.addPortMapping(port, TCP, lifetime = 60):
    let m = res.value
    echo &"Mapped internal port {port} -> external {m.externalHost}:{m.externalPort} (lifetime {m.lifetime}s)"

    checkError pcp.deletePortMapping(port, TCP):
      echo "Deleted port mapping."

pcp.close()
echo "Done."
