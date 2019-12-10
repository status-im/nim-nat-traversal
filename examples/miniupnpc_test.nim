# Copyright (c) 2019 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

# This is the equivalent of miniupnpc/pymoduletest.py (without the command line args).

import nat_traversal/miniupnpc, result, strformat

template checkError(expr, body: untyped): untyped =
  block:
    let res {.inject.} = expr
    if res.isOk:
      body
    else:
      echo res.error
      quit(1)

echo &"miniupnpc-{MINIUPNPC_VERSION}, API version {MINIUPNPC_API_VERSION}"
var upnp = newMiniupnp()
upnp.discoverDelay = 200
echo &"Discovering... (delay={upnp.discoverDelay})"

checkError upnp.discover():
  echo res.value, " device(s) detected"

case upnp.selectIGD():
  of IGDNotFound:
    echo "Internet Gateway Device not found. Giving up."
    quit(1)
  of IGDFound:
    echo "Internet Gateway Device found."
  of IGDNotConnected:
    echo "Internet Gateway Device found but it's not connected. Trying anyway."
  of NotAnIGD:
    echo "Some device found, but it's not recognised as an Internet Gateway Device. Trying anyway."

echo "Local ip address: ", upnp.lanaddr
var externalIP: string
checkError upnp.externalIPAddress():
  externalIP = res.value
  echo "External ip address: ", res.value
checkError upnp.statusInfo():
  echo &"Status: {res.value.status}, uptime: {res.value.uptime}, lastConnError: {res.value.lastconnerror}"
checkError upnp.connectionType():
  echo &"Connection type: {res.value}"

var bytesSent, bytesReceived, packetsSent, packetsReceived: culonglong
checkError upnp.totalBytesSent():
  bytesSent = res.value
checkError upnp.totalBytesReceived():
  bytesReceived = res.value
checkError upnp.totalPacketsSent():
  packetsSent = res.value
checkError upnp.totalPacketsReceived():
  packetsReceived = res.value
echo &"Total bytes: sent {bytesSent}, received {bytesReceived}"
echo &"Total packets: sent {packetsSent}, received {packetsReceived}"

proc printPortMapping(pm: PortMappingRes) =
  echo &"Port mapping: {externalIP}:{pm.externalPort} -> {pm.internalClient}:{pm.internalPort} ({pm.protocol}, \"{pm.description}\", enabled: {pm.enabled}, lease duration: {pm.leaseDuration})"

## enable this if you don't already have a redirection for port 64000:
if false:
  let port = "64000"
  checkError upnp.addPortMapping(port, TCP, upnp.lanAddr, port, "port mapping test", 0, externalIP):
    echo "Added port mapping for: ", port
  checkError upnp.getSpecificPortMapping(port, TCP):
    printPortMapping(res.value)
  checkError upnp.deletePortMapping(port, TCP):
    echo "Deleted port mapping for: ", port
  doAssert(upnp.getSpecificPortMapping(port, TCP).isErr)

var i = 0
while true:
  let res = upnp.getGenericPortMapping(i)
  if res.isErr:
    break
  printPortMapping(res.value)
  inc(i)

let res = upnp.getPortMappingNumberOfEntries()
if res.isOk:
  echo "Port mapping number of entries: ", res.value
else:
  echo &"getPortMappingNumberOfEntries() is not supported by this IGD. Error message: \"{res.error}\""

