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

import ospaths, ./utils
when defined(windows):
  import winlean
  {.passC: "-DNATPMP_STATICLIB".}
else:
  import posix

when defined(libnatpmpUseSystemLibs):
  {.passL: "-lnatpmp".}
else:
  const includePath = currentSourcePath.parentDir().parentDir() / "vendor" / "libnatpmp"
  {.passC: "-I" & includePath.}
  {.passL: includePath / "libnatpmp.a".}

############
# natpmp.h #
############

{.passC: "-DENABLE_STRNATPMPERR".}

##  NAT-PMP Port as defined by the NAT-PMP draft
importConst(NATPMP_PORT, "natpmp.h", cint)

type
  PublicAddressStruct* {.importc: "struct no_name", header: "natpmp.h", bycopy.} = object
    address* {.importc: "addr".}: InAddr ## culong addr;

  NewPortMappingStruct* {.importc: "struct no_name", header: "natpmp.h", bycopy.} = object
    privateport* {.importc: "privateport".}: cushort
    mappedpublicport* {.importc: "mappedpublicport".}: cushort
    lifetime* {.importc: "lifetime".}: culong

  PnuUnion* {.importc: "struct no_name", header: "natpmp.h", bycopy.} = object {.union.}
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
importConst(NATPMP_RESPTYPE_PUBLICADDRESS, "natpmp.h", cint)
importConst(NATPMP_RESPTYPE_UDPPORTMAPPING, "natpmp.h", cint)
importConst(NATPMP_RESPTYPE_TCPPORTMAPPING, "natpmp.h", cint)

##  Values to pass to sendnewportmappingrequest()
const
  NATPMP_PROTOCOL_UDP* = 1
  NATPMP_PROTOCOL_TCP* = 2

##  return values

##  NATPMP_ERR_INVALIDARGS : invalid arguments passed to the function
importConst(NATPMP_ERR_INVALIDARGS, "natpmp.h", cint)
##  NATPMP_ERR_SOCKETERROR : socket() failed. check errno for details
importConst(NATPMP_ERR_SOCKETERROR, "natpmp.h", cint)
##  NATPMP_ERR_CANNOTGETGATEWAY : can't get default gateway IP
importConst(NATPMP_ERR_CANNOTGETGATEWAY, "natpmp.h", cint)
##  NATPMP_ERR_CLOSEERR : close() failed. check errno for details
importConst(NATPMP_ERR_CLOSEERR, "natpmp.h", cint)
##  NATPMP_ERR_RECVFROM : recvfrom() failed. check errno for details
importConst(NATPMP_ERR_RECVFROM, "natpmp.h", cint)
##  NATPMP_ERR_NOPENDINGREQ : readnatpmpresponseorretry() called while no NAT-PMP request was pending
importConst(NATPMP_ERR_NOPENDINGREQ, "natpmp.h", cint)
##  NATPMP_ERR_NOGATEWAYSUPPORT : the gateway does not support NAT-PMP
importConst(NATPMP_ERR_NOGATEWAYSUPPORT, "natpmp.h", cint)
##  NATPMP_ERR_CONNECTERR : connect() failed. check errno for details
importConst(NATPMP_ERR_CONNECTERR, "natpmp.h", cint)
##  NATPMP_ERR_WRONGPACKETSOURCE : packet not received from the network gateway
importConst(NATPMP_ERR_WRONGPACKETSOURCE, "natpmp.h", cint)
##  NATPMP_ERR_SENDERR : send() failed. check errno for details
importConst(NATPMP_ERR_SENDERR, "natpmp.h", cint)
##  NATPMP_ERR_FCNTLERROR : fcntl() failed. check errno for details
importConst(NATPMP_ERR_FCNTLERROR, "natpmp.h", cint)
##  NATPMP_ERR_GETTIMEOFDAYERR : gettimeofday() failed. check errno for details
importConst(NATPMP_ERR_GETTIMEOFDAYERR, "natpmp.h", cint)

importConst(NATPMP_ERR_UNSUPPORTEDVERSION, "natpmp.h", cint)
importConst(NATPMP_ERR_UNSUPPORTEDOPCODE, "natpmp.h", cint)

##  Errors from the server :
importConst(NATPMP_ERR_UNDEFINEDERROR, "natpmp.h", cint)
importConst(NATPMP_ERR_NOTAUTHORIZED, "natpmp.h", cint)
importConst(NATPMP_ERR_NETWORKFAILURE, "natpmp.h", cint)
importConst(NATPMP_ERR_OUTOFRESOURCES, "natpmp.h", cint)
##  NATPMP_TRYAGAIN : no data available for the moment. try again later
importConst(NATPMP_TRYAGAIN, "natpmp.h", cint)

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

import result, strutils

type NatPmp* {.packed.} = ref object
  cstruct*: natpmp_t

proc natpmpFinalizer(x: NatPmp) =
  discard closenatpmp(addr(x.cstruct))

proc newNatPmp*(): NatPmp =
  new(result, natpmpFinalizer)

proc init*(self: NatPmp): Result[bool, cstring] =
  let res = initnatpmp(addr(self.cstruct), 0, 0)
  if res == 0:
    result.ok(true)
  else:
    result.err(strnatpmperr(res))

proc getNatPmpResponse(self: NatPmp, natPmpResponsePtr: ptr natpmpresp_t): Result[bool, cstring] =
  var
    res: cint
    timeout: Timeval
    fds: TFdSet

  while true:
    FD_ZERO(fds);
    FD_SET(SocketHandle(self.cstruct.s), fds)
    res = getnatpmprequesttimeout(addr(self.cstruct), addr(timeout))
    if res != 0:
      result.err(strnatpmperr(res))
      return
    res = select(FD_SETSIZE, addr(fds), nil, nil, addr(timeout))
    if res == -1:
      result.err(osErrorMsg(osLastError()))
      return
    res = readnatpmpresponseorretry(addr(self.cstruct), natPmpResponsePtr)
    if res < 0 and res != NATPMP_TRYAGAIN:
      result.err(strnatpmperr(res))
      return
    if res != NATPMP_TRYAGAIN:
      break

  result.ok(true)


proc externalIPAddress*(self: NatPmp): Result[cstring, cstring] =
  var
    res: cint
    natPmpResponse: natpmpresp_t

  res = sendpublicaddressrequest(addr(self.cstruct))
  if res < 0:
    result.err(strnatpmperr(res))
    return
  if (let r = self.getNatPmpResponse(addr(natPmpResponse)); r.isErr):
    result.err(r.error)
    return
  result.ok(inet_ntoa(natPmpResponse.pnu.publicaddress.address))

type NatPmpProtocol* = enum
  UDP = NATPMP_PROTOCOL_UDP
  TCP = NATPMP_PROTOCOL_TCP

proc doMapping(self: NatPmp, eport: cushort, iport: cushort, protocol: NatPmpProtocol, lifetime: culong): Result[cushort, cstring] =
  var
    res: cint
    natPmpResponse: natpmpresp_t

  res = sendnewportmappingrequest(addr(self.cstruct), protocol.cint, iport, eport, lifetime)
  if res < 0:
    result.err(strnatpmperr(res))
    return
  if (let r = self.getNatPmpResponse(addr(natPmpResponse)); r.isErr):
    result.err(r.error)
    return
  result.ok(natPmpResponse.pnu.newportmapping.mappedpublicport)

## returns the mapped external port (might be different than the one requested)
## "lifetime" is in seconds
proc addPortMapping*(self: NatPmp, eport: cushort, iport: cushort, protocol: NatPmpProtocol, lifetime: culong): Result[cushort, cstring] =
  return self.doMapping(eport, iport, protocol, lifetime)

proc deletePortMapping*(self: NatPmp, eport: cushort, iport: cushort, protocol: NatPmpProtocol): Result[cushort, cstring] =
  return self.doMapping(eport, iport, protocol, 0)

