# Copyright (c) 2019 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

################################
# headers and library location #
################################

{.push raises: [Defect].}

import os
when defined(windows):
  import winlean
else:
  import posix

when defined(libnatpmpUseSystemLibs):
  {.passL: "-lnatpmp".}
else:
  const includePath = currentSourcePath.parentDir().parentDir() / "vendor" / "libnatpmp-upstream"
  {.passC: "-I" & includePath.}
  {.passL: includePath / "libnatpmp.a".}

when defined(windows):
  import nativesockets # for that wsaStartup() call at the end
  {.passC: "-DNATPMP_STATICLIB".}
  {.passL: "-lws2_32 -liphlpapi".}

############
# natpmp.h #
############

{.passC: "-DENABLE_STRNATPMPERR".}

##  NAT-PMP Port as defined by the NAT-PMP draft
const NATPMP_PORT* = cint(5351)

type
  PublicAddressStruct* {.importc: "struct no_name", header: "natpmp.h", bycopy.} = object
    address* {.importc: "addr".}: InAddr ## culong addr;

  NewPortMappingStruct* {.importc: "struct no_name", header: "natpmp.h", bycopy.} = object
    privateport* {.importc: "privateport".}: cushort
    mappedpublicport* {.importc: "mappedpublicport".}: cushort
    lifetime* {.importc: "lifetime".}: culong

  PnuUnion* {.importc: "struct no_name", header: "natpmp.h", bycopy, union.} = object
    publicaddress* {.importc: "publicaddress".}: PublicAddressStruct
    newportmapping* {.importc: "newportmapping".}: NewPortMappingStruct

  natpmp_t* {.importc: "natpmp_t", header: "natpmp.h", bycopy.} = object
    s* {.importc: "s".}: cint    ##  socket
    gateway* {.importc: "gateway".}: culong ##  default gateway (IPv4)
    has_pending_request* {.importc: "has_pending_request".}: cint
    pending_request* {.importc: "pending_request".}: array[12, cuchar]
    pending_request_len* {.importc: "pending_request_len".}: cint
    try_number* {.importc: "try_number".}: cint
    retry_time* {.importc: "retry_time".}: Timeval

  natpmpresp_t* {.importc: "natpmpresp_t", header: "natpmp.h", bycopy.} = object
    resptype* {.importc: "type".}: cushort ##  NATPMP_RESPTYPE_*
    resultcode* {.importc: "resultcode".}: cushort ##  NAT-PMP response code
    epoch* {.importc: "epoch".}: culong ##  Seconds since start of epoch
    pnu* {.importc: "pnu".}: PnuUnion


##  possible values for type field of natpmpresp_t
const
  NATPMP_RESPTYPE_PUBLICADDRESS* = cushort(0)
  NATPMP_RESPTYPE_UDPPORTMAPPING* = cushort(1)
  NATPMP_RESPTYPE_TCPPORTMAPPING* = cushort(2)

##  Values to pass to sendnewportmappingrequest()
const
  NATPMP_PROTOCOL_UDP* = 1
  NATPMP_PROTOCOL_TCP* = 2

##  return values

##  NATPMP_ERR_INVALIDARGS : invalid arguments passed to the function
const NATPMP_ERR_INVALIDARGS* = cint(-1)
##  NATPMP_ERR_SOCKETERROR : socket() failed. check errno for details
const NATPMP_ERR_SOCKETERROR* = cint(-2)
##  NATPMP_ERR_CANNOTGETGATEWAY : can't get default gateway IP
const NATPMP_ERR_CANNOTGETGATEWAY* = cint(-3)
##  NATPMP_ERR_CLOSEERR : close() failed. check errno for details
const NATPMP_ERR_CLOSEERR* = cint(-4)
##  NATPMP_ERR_RECVFROM : recvfrom() failed. check errno for details
const NATPMP_ERR_RECVFROM* = cint(-5)
##  NATPMP_ERR_NOPENDINGREQ : readnatpmpresponseorretry() called while no NAT-PMP request was pending
const NATPMP_ERR_NOPENDINGREQ* = cint(-6)
##  NATPMP_ERR_NOGATEWAYSUPPORT : the gateway does not support NAT-PMP
const NATPMP_ERR_NOGATEWAYSUPPORT* = cint(-7)
##  NATPMP_ERR_CONNECTERR : connect() failed. check errno for details
const NATPMP_ERR_CONNECTERR* = cint(-8)
##  NATPMP_ERR_WRONGPACKETSOURCE : packet not received from the network gateway
const NATPMP_ERR_WRONGPACKETSOURCE* = cint(-9)
##  NATPMP_ERR_SENDERR : send() failed. check errno for details
const NATPMP_ERR_SENDERR* = cint(-10)
##  NATPMP_ERR_FCNTLERROR : fcntl() failed. check errno for details
const NATPMP_ERR_FCNTLERROR* = cint(-11)
##  NATPMP_ERR_GETTIMEOFDAYERR : gettimeofday() failed. check errno for details
const NATPMP_ERR_GETTIMEOFDAYERR* = cint(-12)

const NATPMP_ERR_UNSUPPORTEDVERSION* = cint(-14)
const NATPMP_ERR_UNSUPPORTEDOPCODE* = cint(-15)

##  Errors from the server :
const NATPMP_ERR_UNDEFINEDERROR* = cint(-49)
const NATPMP_ERR_NOTAUTHORIZED* = cint(-51)
const NATPMP_ERR_NETWORKFAILURE* = cint(-52)
const NATPMP_ERR_OUTOFRESOURCES* = cint(-53)
##  NATPMP_TRYAGAIN : no data available for the moment. try again later
const NATPMP_TRYAGAIN* = cint(-100)

##  initnatpmp()
##  initialize a natpmp_t object
##  With forcegw=1 the gateway is not detected automaticaly.
##  Return values :
##  0 = OK
##  NATPMP_ERR_INVALIDARGS
##  NATPMP_ERR_SOCKETERROR
##  NATPMP_ERR_FCNTLERROR
##  NATPMP_ERR_CANNOTGETGATEWAY
##  NATPMP_ERR_CONNECTERR
proc initnatpmp*(p: ptr natpmp_t; forcegw: cint; forcedgw: culong): cint {.importc: "initnatpmp", header: "natpmp.h".}

##  closenatpmp()
##  close resources associated with a natpmp_t object
##  Return values :
##  0 = OK
##  NATPMP_ERR_INVALIDARGS
##  NATPMP_ERR_CLOSEERR
proc closenatpmp*(p: ptr natpmp_t): cint {.importc: "closenatpmp", header: "natpmp.h".}

##  sendpublicaddressrequest()
##  send a public address NAT-PMP request to the network gateway
##  Return values :
##  2 = OK (size of the request)
##  NATPMP_ERR_INVALIDARGS
##  NATPMP_ERR_SENDERR
proc sendpublicaddressrequest*(p: ptr natpmp_t): cint {.importc: "sendpublicaddressrequest", header: "natpmp.h".}

##  sendnewportmappingrequest()
##  send a new port mapping NAT-PMP request to the network gateway
##  Arguments :
##  protocol is either NATPMP_PROTOCOL_TCP or NATPMP_PROTOCOL_UDP,
##  lifetime is in seconds.
##  To remove a port mapping, set lifetime to zero.
##  To remove all port mappings to the host, set lifetime and both ports
##  to zero.
##  Return values :
##  12 = OK (size of the request)
##  NATPMP_ERR_INVALIDARGS
##  NATPMP_ERR_SENDERR
proc sendnewportmappingrequest*(p: ptr natpmp_t; protocol: cint;
                               privateport: cushort; publicport: cushort;
                               lifetime: culong): cint {.importc: "sendnewportmappingrequest", header: "natpmp.h".}

##  getnatpmprequesttimeout()
##  fills the timeval structure with the timeout duration of the
##  currently pending NAT-PMP request.
##  Return values :
##  0 = OK
##  NATPMP_ERR_INVALIDARGS
##  NATPMP_ERR_GETTIMEOFDAYERR
##  NATPMP_ERR_NOPENDINGREQ
proc getnatpmprequesttimeout*(p: ptr natpmp_t; timeout: ptr Timeval): cint {.importc: "getnatpmprequesttimeout", header: "natpmp.h".}

##  readnatpmpresponseorretry()
##  fills the natpmpresp_t structure if possible
##  Return values :
##  0 = OK
##  NATPMP_TRYAGAIN
##  NATPMP_ERR_INVALIDARGS
##  NATPMP_ERR_NOPENDINGREQ
##  NATPMP_ERR_NOGATEWAYSUPPORT
##  NATPMP_ERR_RECVFROM
##  NATPMP_ERR_WRONGPACKETSOURCE
##  NATPMP_ERR_UNSUPPORTEDVERSION
##  NATPMP_ERR_UNSUPPORTEDOPCODE
##  NATPMP_ERR_NOTAUTHORIZED
##  NATPMP_ERR_NETWORKFAILURE
##  NATPMP_ERR_OUTOFRESOURCES
##  NATPMP_ERR_UNSUPPORTEDOPCODE
##  NATPMP_ERR_UNDEFINEDERROR
proc readnatpmpresponseorretry*(p: ptr natpmp_t; response: ptr natpmpresp_t): cint {.importc: "readnatpmpresponseorretry", header: "natpmp.h".}

proc strnatpmperr*(t: cint): cstring {.importc: "strnatpmperr", header: "natpmp.h".}

###################
# custom wrappers #
###################

import
  stew/results
export results

type NatPmp* {.packed.} = ref object
  cstruct*: natpmp_t

proc close*(x: NatPmp) =
  discard closenatpmp(addr(x.cstruct))

proc newNatPmp*(): NatPmp =
  new(result)

proc init*(self: NatPmp): Result[bool, cstring] =
  let res = initnatpmp(addr(self.cstruct), 0, 0)
  if res == 0:
    result.ok(true)
  else:
    result.err(strnatpmperr(res))

proc `=deepCopy`(x: NatPmp): NatPmp =
  doAssert(false, "not implemented")

proc getNatPmpResponse(self: NatPmp, natPmpResponsePtr: ptr natpmpresp_t): Result[bool, string] =
  var
    res: cint
    timeout: Timeval
    fds: TFdSet

  while true:
    FD_ZERO(fds);
    FD_SET(SocketHandle(self.cstruct.s), fds)
    res = getnatpmprequesttimeout(addr(self.cstruct), addr(timeout))
    if res != 0:
      result.err($strnatpmperr(res))
      return
    res = select(FD_SETSIZE, addr(fds), nil, nil, addr(timeout))
    if res == -1:
      result.err(osErrorMsg(osLastError()))
      return
    res = readnatpmpresponseorretry(addr(self.cstruct), natPmpResponsePtr)
    if res < 0 and res != NATPMP_TRYAGAIN:
      result.err($strnatpmperr(res))
      return
    if res != NATPMP_TRYAGAIN:
      break

  result.ok(true)


proc externalIPAddress*(self: NatPmp): Result[cstring, string] =
  var
    res: cint
    natPmpResponse: natpmpresp_t

  res = sendpublicaddressrequest(addr(self.cstruct))
  if res < 0:
    result.err($strnatpmperr(res))
    return
  if (let r = self.getNatPmpResponse(addr(natPmpResponse)); r.isErr):
    result.err(r.error)
    return
  result.ok(inet_ntoa(natPmpResponse.pnu.publicaddress.address))

type NatPmpProtocol* = enum
  UDP = NATPMP_PROTOCOL_UDP
  TCP = NATPMP_PROTOCOL_TCP

proc doMapping(self: NatPmp, eport: cushort, iport: cushort, protocol: NatPmpProtocol, lifetime: culong): Result[cushort, string] =
  var
    res: cint
    natPmpResponse: natpmpresp_t

  res = sendnewportmappingrequest(addr(self.cstruct), protocol.cint, iport, eport, lifetime)
  if res < 0:
    result.err($strnatpmperr(res))
    return
  if (let r = self.getNatPmpResponse(addr(natPmpResponse)); r.isErr):
    result.err(r.error)
    return
  result.ok(natPmpResponse.pnu.newportmapping.mappedpublicport)

## returns the mapped external port (might be different than the one requested)
## "lifetime" is in seconds
proc addPortMapping*(self: NatPmp, eport: cushort, iport: cushort, protocol: NatPmpProtocol, lifetime: culong): Result[cushort, string] =
  return self.doMapping(eport, iport, protocol, lifetime)

proc deletePortMapping*(self: NatPmp, eport: cushort, iport: cushort, protocol: NatPmpProtocol): Result[cushort, string] =
  return self.doMapping(eport, iport, protocol, 0)

