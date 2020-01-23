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

import ./utils

when defined(miniupnpcUseSystemLibs):
  {.passC: staticExec("pkg-config --cflags miniupnpc").}
  {.passL: staticExec("pkg-config --libs miniupnpc").}
else:
  import os
  const includePath = currentSourcePath.parentDir().parentDir() / "vendor" / "miniupnp" / "miniupnpc"
  {.passC: "-I" & includePath.}
  # We can't use the {.link.} pragma in here, because it would place the static
  # library archive as the first object to be linked, which would lead to all
  # its exported symbols being ignored. We move it into the last position with {.passL.}.
  {.passL: includePath / "libminiupnpc.a".}

when defined(windows):
  import nativesockets # for that wsaStartup() call at the end
  {.passC: "-DMINIUPNP_STATICLIB".}
  {.passL: "-lws2_32 -liphlpapi".}

################
# upnperrors.h #
################

##  strupnperror()
##  Return a string description of the UPnP error code
##  or NULL for undefinded errors
proc upnpError*(err: cint): cstring {.importc: "strupnperror",
                                     header: "upnperrors.h".}

######################
# portlistingparse.h #
######################

type
  portMappingElt* {.size: sizeof(cint).} = enum
    PortMappingEltNone, PortMappingEntry, NewRemoteHost, NewExternalPort,
    NewProtocol, NewInternalPort, NewInternalClient, NewEnabled, NewDescription,
    NewLeaseTime

  PortMapping* {.importc: "struct PortMapping", header: "portlistingparse.h", bycopy.} = object
    l_next* {.importc: "l_next".}: ptr PortMapping ##  list next element
    leaseTime* {.importc: "leaseTime".}: culonglong ## assume the used C version is at lead C99 (see miniupnpctypes.h for the definition of UNSIGNED_INTEGER)
    externalPort* {.importc: "externalPort".}: cushort
    internalPort* {.importc: "internalPort".}: cushort
    remoteHost* {.importc: "remoteHost".}: array[64, char]
    internalClient* {.importc: "internalClient".}: array[64, char]
    description* {.importc: "description".}: array[64, char]
    protocol* {.importc: "protocol".}: array[4, char]
    enabled* {.importc: "enabled".}: cuchar

  PortMappingParserData* {.importc: "struct PortMappingParserData",
                          header: "portlistingparse.h", bycopy.} = object
    l_head* {.importc: "l_head".}: ptr PortMapping ##  list head
    curelt* {.importc: "curelt".}: portMappingElt

##################
# upnpcommands.h #
##################

##  MiniUPnPc return codes :
const
  UPNPCOMMAND_SUCCESS* = cint(0)
  UPNPCOMMAND_UNKNOWN_ERROR* = cint(-1)
  UPNPCOMMAND_INVALID_ARGS* = cint(-2)
  UPNPCOMMAND_HTTP_ERROR* = cint(-3)
  UPNPCOMMAND_INVALID_RESPONSE* = cint(-4)
  UPNPCOMMAND_MEM_ALLOC_ERROR* = cint(-5)

proc UPNP_GetTotalBytesSent*(controlURL: cstring; servicetype: cstring): culonglong {.
    importc: "UPNP_GetTotalBytesSent", header: "upnpcommands.h".}

proc UPNP_GetTotalBytesReceived*(controlURL: cstring; servicetype: cstring): culonglong {.
    importc: "UPNP_GetTotalBytesReceived", header: "upnpcommands.h".}

proc UPNP_GetTotalPacketsSent*(controlURL: cstring; servicetype: cstring): culonglong {.
    importc: "UPNP_GetTotalPacketsSent", header: "upnpcommands.h".}

proc UPNP_GetTotalPacketsReceived*(controlURL: cstring; servicetype: cstring): culonglong {.
    importc: "UPNP_GetTotalPacketsReceived", header: "upnpcommands.h".}

##  UPNP_GetStatusInfo()
##  status and lastconnerror are 64 byte buffers
##  Return values :
##  UPNPCOMMAND_SUCCESS, UPNPCOMMAND_INVALID_ARGS, UPNPCOMMAND_UNKNOWN_ERROR
##  or a UPnP Error code
proc UPNP_GetStatusInfo*(controlURL: cstring; servicetype: cstring; status: cstring;
                        uptime: ptr cuint; lastconnerror: cstring): cint {.
    importc: "UPNP_GetStatusInfo", header: "upnpcommands.h".}

##  UPNP_GetConnectionTypeInfo()
##  argument connectionType is a 64 character buffer
##  Return Values :
##  UPNPCOMMAND_SUCCESS, UPNPCOMMAND_INVALID_ARGS, UPNPCOMMAND_UNKNOWN_ERROR
##  or a UPnP Error code
proc UPNP_GetConnectionTypeInfo*(controlURL: cstring; servicetype: cstring;
                                connectionType: cstring): cint {.
    importc: "UPNP_GetConnectionTypeInfo", header: "upnpcommands.h".}

##  UPNP_GetExternalIPAddress() call the corresponding UPNP method.
##  if the third arg is not null the value is copied to it.
##  at least 16 bytes must be available
##
##  Return values :
##  0 : SUCCESS
##  NON ZERO : ERROR Either an UPnP error code or an unknown error.
##
##  possible UPnP Errors :
##  402 Invalid Args - See UPnP Device Architecture section on Control.
##  501 Action Failed - See UPnP Device Architecture section on Control.
proc UPNP_GetExternalIPAddress*(controlURL: cstring; servicetype: cstring;
                               extIpAdd: cstring): cint {.
    importc: "UPNP_GetExternalIPAddress", header: "upnpcommands.h".}

##  UPNP_GetLinkLayerMaxBitRates()
##  call WANCommonInterfaceConfig:1#GetCommonLinkProperties
##
##  return values :
##  UPNPCOMMAND_SUCCESS, UPNPCOMMAND_INVALID_ARGS, UPNPCOMMAND_UNKNOWN_ERROR
##  or a UPnP Error Code.
proc UPNP_GetLinkLayerMaxBitRates*(controlURL: cstring; servicetype: cstring;
                                  bitrateDown: ptr cuint; bitrateUp: ptr cuint): cint {.
    importc: "UPNP_GetLinkLayerMaxBitRates", header: "upnpcommands.h".}

##  UPNP_AddPortMapping()
##  if desc is NULL, it will be defaulted to "libminiupnpc"
##  remoteHost is usually NULL because IGD don't support it.
##
##  Return values :
##  0 : SUCCESS
##  NON ZERO : ERROR. Either an UPnP error code or an unknown error.
##
##  List of possible UPnP errors for AddPortMapping :
##  errorCode errorDescription (short) - Description (long)
##  402 Invalid Args - See UPnP Device Architecture section on Control.
##  501 Action Failed - See UPnP Device Architecture section on Control.
##  606 Action not authorized - The action requested REQUIRES authorization and
##                              the sender was not authorized.
##  715 WildCardNotPermittedInSrcIP - The source IP address cannot be
##                                    wild-carded
##  716 WildCardNotPermittedInExtPort - The external port cannot be wild-carded
##  718 ConflictInMappingEntry - The port mapping entry specified conflicts
##                      with a mapping assigned previously to another client
##  724 SamePortValuesRequired - Internal and External port values
##                               must be the same
##  725 OnlyPermanentLeasesSupported - The NAT implementation only supports
##                   permanent lease times on port mappings
##  726 RemoteHostOnlySupportsWildcard - RemoteHost must be a wildcard
##                              and cannot be a specific IP address or DNS name
##  727 ExternalPortOnlySupportsWildcard - ExternalPort must be a wildcard and
##                                         cannot be a specific port value
##  728 NoPortMapsAvailable - There are not enough free ports available to
##                            complete port mapping.
##  729 ConflictWithOtherMechanisms - Attempted port mapping is not allowed
##                                    due to conflict with other mechanisms.
##  732 WildCardNotPermittedInIntPort - The internal port cannot be wild-carded
##
proc UPNP_AddPortMapping*(controlURL: cstring; servicetype: cstring;
                         extPort: cstring; inPort: cstring; inClient: cstring;
                         desc: cstring; proto: cstring; remoteHost: cstring;
                         leaseDuration: cstring): cint {.
    importc: "UPNP_AddPortMapping", header: "upnpcommands.h".}

##  UPNP_AddAnyPortMapping()
##  if desc is NULL, it will be defaulted to "libminiupnpc"
##  remoteHost is usually NULL because IGD don't support it.
##
##  Return values :
##  0 : SUCCESS
##  NON ZERO : ERROR. Either an UPnP error code or an unknown error.
##
##  List of possible UPnP errors for AddPortMapping :
##  errorCode errorDescription (short) - Description (long)
##  402 Invalid Args - See UPnP Device Architecture section on Control.
##  501 Action Failed - See UPnP Device Architecture section on Control.
##  606 Action not authorized - The action requested REQUIRES authorization and
##                              the sender was not authorized.
##  715 WildCardNotPermittedInSrcIP - The source IP address cannot be
##                                    wild-carded
##  716 WildCardNotPermittedInExtPort - The external port cannot be wild-carded
##  728 NoPortMapsAvailable - There are not enough free ports available to
##                            complete port mapping.
##  729 ConflictWithOtherMechanisms - Attempted port mapping is not allowed
##                                    due to conflict with other mechanisms.
##  732 WildCardNotPermittedInIntPort - The internal port cannot be wild-carded
##
proc UPNP_AddAnyPortMapping*(controlURL: cstring; servicetype: cstring;
                            extPort: cstring; inPort: cstring; inClient: cstring;
                            desc: cstring; proto: cstring; remoteHost: cstring;
                            leaseDuration: cstring; reservedPort: cstring): cint {.
    importc: "UPNP_AddAnyPortMapping", header: "upnpcommands.h".}

##  UPNP_DeletePortMapping()
##  Use same argument values as what was used for AddPortMapping().
##  remoteHost is usually NULL because IGD don't support it.
##  Return Values :
##  0 : SUCCESS
##  NON ZERO : error. Either an UPnP error code or an undefined error.
##
##  List of possible UPnP errors for DeletePortMapping :
##  402 Invalid Args - See UPnP Device Architecture section on Control.
##  606 Action not authorized - The action requested REQUIRES authorization
##                              and the sender was not authorized.
##  714 NoSuchEntryInArray - The specified value does not exist in the array
proc UPNP_DeletePortMapping*(controlURL: cstring; servicetype: cstring;
                            extPort: cstring; proto: cstring; remoteHost: cstring): cint {.
    importc: "UPNP_DeletePortMapping", header: "upnpcommands.h".}

##  UPNP_DeletePortRangeMapping()
##  Use same argument values as what was used for AddPortMapping().
##  remoteHost is usually NULL because IGD don't support it.
##  Return Values :
##  0 : SUCCESS
##  NON ZERO : error. Either an UPnP error code or an undefined error.
##
##  List of possible UPnP errors for DeletePortMapping :
##  606 Action not authorized - The action requested REQUIRES authorization
##                              and the sender was not authorized.
##  730 PortMappingNotFound - This error message is returned if no port
## 			     mapping is found in the specified range.
##  733 InconsistentParameters - NewStartPort and NewEndPort values are not consistent.
proc UPNP_DeletePortMappingRange*(controlURL: cstring; servicetype: cstring;
                                 extPortStart: cstring; extPortEnd: cstring;
                                 proto: cstring; manage: cstring): cint {.
    importc: "UPNP_DeletePortMappingRange", header: "upnpcommands.h".}

##  UPNP_GetPortMappingNumberOfEntries()
##  not supported by all routers
proc UPNP_GetPortMappingNumberOfEntries*(controlURL: cstring; servicetype: cstring;
                                        numEntries: ptr cuint): cint {.
    importc: "UPNP_GetPortMappingNumberOfEntries", header: "upnpcommands.h".}

##  UPNP_GetSpecificPortMappingEntry()
##     retrieves an existing port mapping
##  params :
##   in   extPort
##   in   proto
##   in   remoteHost
##   out  intClient (16 bytes)
##   out  intPort (6 bytes)
##   out  desc (80 bytes)
##   out  enabled (4 bytes)
##   out  leaseDuration (16 bytes)
##
##  return value :
##  UPNPCOMMAND_SUCCESS, UPNPCOMMAND_INVALID_ARGS, UPNPCOMMAND_UNKNOWN_ERROR
##  or a UPnP Error Code.
##
##  List of possible UPnP errors for _GetSpecificPortMappingEntry :
##  402 Invalid Args - See UPnP Device Architecture section on Control.
##  501 Action Failed - See UPnP Device Architecture section on Control.
##  606 Action not authorized - The action requested REQUIRES authorization
##                              and the sender was not authorized.
##  714 NoSuchEntryInArray - The specified value does not exist in the array.
##
proc UPNP_GetSpecificPortMappingEntry*(controlURL: cstring; servicetype: cstring;
                                      extPort: cstring; proto: cstring;
                                      remoteHost: cstring; intClient: cstring;
                                      intPort: cstring; desc: cstring;
                                      enabled: cstring; leaseDuration: cstring): cint {.
    importc: "UPNP_GetSpecificPortMappingEntry", header: "upnpcommands.h".}

##  UPNP_GetGenericPortMappingEntry()
##  params :
##   in   index
##   out  extPort (6 bytes)
##   out  intClient (16 bytes)
##   out  intPort (6 bytes)
##   out  protocol (4 bytes)
##   out  desc (80 bytes)
##   out  enabled (4 bytes)
##   out  rHost (64 bytes)
##   out  duration (16 bytes)
##
##  return value :
##  UPNPCOMMAND_SUCCESS, UPNPCOMMAND_INVALID_ARGS, UPNPCOMMAND_UNKNOWN_ERROR
##  or a UPnP Error Code.
##
##  Possible UPNP Error codes :
##  402 Invalid Args - See UPnP Device Architecture section on Control.
##  606 Action not authorized - The action requested REQUIRES authorization
##                              and the sender was not authorized.
##  713 SpecifiedArrayIndexInvalid - The specified array index is out of bounds
##
proc UPNP_GetGenericPortMappingEntry*(controlURL: cstring; servicetype: cstring;
                                     index: cstring; extPort: cstring;
                                     intClient: cstring; intPort: cstring;
                                     protocol: cstring; desc: cstring;
                                     enabled: cstring; rHost: cstring;
                                     duration: cstring): cint {.
    importc: "UPNP_GetGenericPortMappingEntry", header: "upnpcommands.h".}

##  UPNP_GetListOfPortMappings()      Available in IGD v2
##
##
##  Possible UPNP Error codes :
##  606 Action not Authorized
##  730 PortMappingNotFound - no port mapping is found in the specified range.
##  733 InconsistantParameters - NewStartPort and NewEndPort values are not
##                               consistent.
##
proc UPNP_GetListOfPortMappings*(controlURL: cstring; servicetype: cstring;
                                startPort: cstring; endPort: cstring;
                                protocol: cstring; numberOfPorts: cstring;
                                data: ptr PortMappingParserData): cint {.
    importc: "UPNP_GetListOfPortMappings", header: "upnpcommands.h".}

##  IGD:2, functions for service WANIPv6FirewallControl:1
proc UPNP_GetFirewallStatus*(controlURL: cstring; servicetype: cstring;
                            firewallEnabled: ptr cint;
                            inboundPinholeAllowed: ptr cint): cint {.
    importc: "UPNP_GetFirewallStatus", header: "upnpcommands.h".}

proc UPNP_GetOutboundPinholeTimeout*(controlURL: cstring; servicetype: cstring;
                                    remoteHost: cstring; remotePort: cstring;
                                    intClient: cstring; intPort: cstring;
                                    proto: cstring; opTimeout: ptr cint): cint {.
    importc: "UPNP_GetOutboundPinholeTimeout", header: "upnpcommands.h".}

proc UPNP_AddPinhole*(controlURL: cstring; servicetype: cstring; remoteHost: cstring;
                     remotePort: cstring; intClient: cstring; intPort: cstring;
                     proto: cstring; leaseTime: cstring; uniqueID: cstring): cint {.
    importc: "UPNP_AddPinhole", header: "upnpcommands.h".}

proc UPNP_UpdatePinhole*(controlURL: cstring; servicetype: cstring;
                        uniqueID: cstring; leaseTime: cstring): cint {.
    importc: "UPNP_UpdatePinhole", header: "upnpcommands.h".}

proc UPNP_DeletePinhole*(controlURL: cstring; servicetype: cstring; uniqueID: cstring): cint {.
    importc: "UPNP_DeletePinhole", header: "upnpcommands.h".}

proc UPNP_CheckPinholeWorking*(controlURL: cstring; servicetype: cstring;
                              uniqueID: cstring; isWorking: ptr cint): cint {.
    importc: "UPNP_CheckPinholeWorking", header: "upnpcommands.h".}

proc UPNP_GetPinholePackets*(controlURL: cstring; servicetype: cstring;
                            uniqueID: cstring; packets: ptr cint): cint {.
    importc: "UPNP_GetPinholePackets", header: "upnpcommands.h".}

####################
# igd_desc_parse.h #
####################

##  Structure to store the result of the parsing of UPnP
##  descriptions of Internet Gateway Devices
const
  MINIUPNPC_URL_MAXSIZE* = (128)

type
  IGDdatas_service* {.importc: "struct IGDdatas_service",
                     header: "igd_desc_parse.h", bycopy.} = object
    controlurl* {.importc: "controlurl".}: array[MINIUPNPC_URL_MAXSIZE, char]
    eventsuburl* {.importc: "eventsuburl".}: array[MINIUPNPC_URL_MAXSIZE, char]
    scpdurl* {.importc: "scpdurl".}: array[MINIUPNPC_URL_MAXSIZE, char]
    servicetype* {.importc: "servicetype".}: array[MINIUPNPC_URL_MAXSIZE, char] ## char devicetype[MINIUPNPC_URL_MAXSIZE];

  IGDdatas* {.importc: "struct IGDdatas", header: "igd_desc_parse.h", bycopy.} = object
    cureltname* {.importc: "cureltname".}: array[MINIUPNPC_URL_MAXSIZE, char]
    urlbase* {.importc: "urlbase".}: array[MINIUPNPC_URL_MAXSIZE, char]
    presentationurl* {.importc: "presentationurl".}: array[MINIUPNPC_URL_MAXSIZE,
        char]
    level* {.importc: "level".}: cint ## int state;
                                  ##  "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1"
    CIF* {.importc: "CIF".}: IGDdatas_service ##  "urn:schemas-upnp-org:service:WANIPConnection:1"
                                          ##  "urn:schemas-upnp-org:service:WANPPPConnection:1"
    first* {.importc: "first".}: IGDdatas_service ##  if both WANIPConnection and WANPPPConnection are present
    second* {.importc: "second".}: IGDdatas_service ##  "urn:schemas-upnp-org:service:WANIPv6FirewallControl:1"
    IPv6FC* {.importc: "IPv6FC".}: IGDdatas_service ##  tmp
    tmp* {.importc: "tmp".}: IGDdatas_service

#############
# upnpdev.h #
#############

type
  UPNPDev* {.importc: "struct UPNPDev", header: "upnpdev.h", bycopy.} = object
    pNext* {.importc: "pNext".}: ptr UPNPDev
    descURL* {.importc: "descURL".}: cstring
    st* {.importc: "st".}: cstring
    usn* {.importc: "usn".}: cstring
    scope_id* {.importc: "scope_id".}: cuint
    buffer* {.importc: "buffer".}: array[3, char]

##  freeUPNPDevlist()
##  free list returned by upnpDiscover()
proc freeUPNPDevlist*(devlist: ptr UPNPDev) {.importc: "freeUPNPDevlist",
    header: "upnpdev.h".}

###############
# miniupnpc.h #
###############

##  error codes :
const UPNPDISCOVER_SUCCESS* = cint(0)
const UPNPDISCOVER_UNKNOWN_ERROR* = cint(-1)
const UPNPDISCOVER_SOCKET_ERROR* = cint(-101)
const UPNPDISCOVER_MEMORY_ERROR* = cint(-102)

##  versions :
# We use importConst here because when a system header is used, we want the
# number from the actual header file.
importConst(MINIUPNPC_VERSION, "miniupnpc.h", cstring)
importConst(MINIUPNPC_API_VERSION, "miniupnpc.h", cint)

##  Source port:
##    Using "1" as an alias for 1900 for backwards compatibility
##    (presuming one would have used that for the "sameport" parameter)
const UPNP_LOCAL_PORT_ANY* = cint(0)
const UPNP_LOCAL_PORT_SAME* = cint(1)

##  Structures definitions :
type
  UPNParg* {.importc: "struct UPNParg", header: "miniupnpc.h", bycopy.} = object
    elt* {.importc: "elt".}: cstring
    val* {.importc: "val".}: cstring

proc simpleUPnPcommand*(a1: cint; a2: cstring; a3: cstring; a4: cstring; a5: ptr UPNParg;
                       a6: ptr cint): cstring {.importc: "simpleUPnPcommand",
    header: "miniupnpc.h".}

##  upnpDiscover()
##  discover UPnP devices on the network.
##  The discovered devices are returned as a chained list.
##  It is up to the caller to free the list with freeUPNPDevlist().
##  delay (in millisecond) is the maximum time for waiting any device
##  response.
##  If available, device list will be obtained from MiniSSDPd.
##  Default path for minissdpd socket will be used if minissdpdsock argument
##  is NULL.
##  If multicastif is not NULL, it will be used instead of the default
##  multicast interface for sending SSDP discover packets.
##  If localport is set to UPNP_LOCAL_PORT_SAME(1) SSDP packets will be sent
##  from the source port 1900 (same as destination port), if set to
##  UPNP_LOCAL_PORT_ANY(0) system assign a source port, any other value will
##  be attempted as the source port.
##  "searchalltypes" parameter is useful when searching several types,
##  if 0, the discovery will stop with the first type returning results.
##  TTL should default to 2.
proc upnpDiscover*(delay: cint; multicastif: cstring; minissdpdsock: cstring;
                  localport: cint; ipv6: cint; ttl: cuchar; error: ptr cint): ptr UPNPDev {.
    importc: "upnpDiscover", header: "miniupnpc.h".}

proc upnpDiscoverAll*(delay: cint; multicastif: cstring; minissdpdsock: cstring;
                     localport: cint; ipv6: cint; ttl: cuchar; error: ptr cint): ptr UPNPDev {.
    importc: "upnpDiscoverAll", header: "miniupnpc.h".}

proc upnpDiscoverDevice*(device: cstring; delay: cint; multicastif: cstring;
                        minissdpdsock: cstring; localport: cint; ipv6: cint;
                        ttl: cuchar; error: ptr cint): ptr UPNPDev {.
    importc: "upnpDiscoverDevice", header: "miniupnpc.h".}

proc upnpDiscoverDevices*(deviceTypes: ptr cstring; delay: cint; multicastif: cstring;
                         minissdpdsock: cstring; localport: cint; ipv6: cint;
                         ttl: cuchar; error: ptr cint; searchalltypes: cint): ptr UPNPDev {.
    importc: "upnpDiscoverDevices", header: "miniupnpc.h".}

##  structure used to get fast access to urls
##  controlURL: controlURL of the WANIPConnection
##  ipcondescURL: url of the description of the WANIPConnection
##  controlURL_CIF: controlURL of the WANCommonInterfaceConfig
##  controlURL_6FC: controlURL of the WANIPv6FirewallControl
##
type
  UPNPUrls* {.importc: "struct UPNPUrls", header: "miniupnpc.h", bycopy.} = object
    controlURL* {.importc: "controlURL".}: cstring
    ipcondescURL* {.importc: "ipcondescURL".}: cstring
    controlURL_CIF* {.importc: "controlURL_CIF".}: cstring
    controlURL_6FC* {.importc: "controlURL_6FC".}: cstring
    rootdescURL* {.importc: "rootdescURL".}: cstring

##  UPNP_GetValidIGD() :
##  return values :
##      0 = NO IGD found
##      1 = A valid connected IGD has been found
##      2 = A valid IGD has been found but it reported as
##          not connected
##      3 = an UPnP device has been found but was not recognized as an IGD
##
##  In any non-zero return case, the urls and data structures
##  passed as parameters are set. Don't forget to call freeUPNPUrls(urls) to
##  free allocated memory.
##
proc UPNP_GetValidIGD*(devlist: ptr UPNPDev; urls: ptr UPNPUrls; data: ptr IGDdatas;
                      lanaddr: cstring; lanaddrlen: cint): cint {.
    importc: "UPNP_GetValidIGD", header: "miniupnpc.h".}

##  UPNP_GetIGDFromUrl()
##  Used when skipping the discovery process.
##  When succeding, urls, data, and lanaddr arguments are set.
##  return value :
##    0 - Not ok
##    1 - OK
proc UPNP_GetIGDFromUrl*(rootdescurl: cstring; urls: ptr UPNPUrls; data: ptr IGDdatas;
                        lanaddr: cstring; lanaddrlen: cint): cint {.
    importc: "UPNP_GetIGDFromUrl", header: "miniupnpc.h".}

proc freeUPNPUrls*(a1: ptr UPNPUrls) {.importc: "FreeUPNPUrls", header: "miniupnpc.h".}

##  return 0 or 1
proc UPNPIGD_IsConnected*(a1: ptr UPNPUrls; a2: ptr IGDdatas): cint {.
    importc: "UPNPIGD_IsConnected", header: "miniupnpc.h".}

###################
# custom wrappers #
###################

import stew/result, strutils

type Miniupnp* = ref object
  devList*: ptr UPNPDev
  urls*: UPNPUrls
  data*: IGDdatas
  discoverDelay*: cint # in ms, the delay defaults to 1000ms if this is left 0
  multicastIF*: string
  miniSsdpdSocket*: string
  localPort*: cint
  ipv6*: cint
  ttl*: cuchar
  error*: cint
  lanAddr*: string

proc miniupnpFinalizer(x: Miniupnp) =
  freeUPNPDevlist(x.devList)
  x.devList = nil
  freeUPNPUrls(addr(x.urls))

proc newMiniupnp*(): Miniupnp =
  new(result, miniupnpFinalizer)
  result.ttl = 2.cuchar

proc `=deepCopy`*(x: Miniupnp): Miniupnp =
  doAssert(false, "not implemented")

# trim a Nim string to the length of the internal cstring
proc trimString(s: var string) =
  s.setLen(len(s.cstring))

## returns the number of devices discovered or an error string
proc discover*(self: Miniupnp): Result[int, cstring] =
  if self.devList != nil:
    freeUPNPDevlist(self.devList)
  self.error = 0
  var
    multicastIF = if self.multicastIF.len > 0: self.multicastIF.cstring else: nil
    miniSsdpdSocket = if self.miniSsdpdSocket.len > 0: self.miniSsdpdSocket.cstring else: nil
  self.devList = upnpDiscover(self.discoverDelay,
                              multicastIF,
                              miniSsdpdSocket,
                              self.localPort,
                              self.ipv6,
                              self.ttl,
                              addr(self.error))
  var
    dev = self.devList
    i = 0

  while dev != nil:
    inc i
    dev = dev.pNext

  if self.error == 0:
    result.ok(i)
  else:
    result.err(upnpError(self.error))

type SelectIGDResult* = enum
  IGDNotFound = 0
  IGDFound = 1
  IGDNotConnected = 2
  NotAnIGD = 3

proc selectIGD*(self: Miniupnp): SelectIGDResult =
  let lanaddrlen = 40.cint
  self.lanAddr.setLen(40)
  result = UPNP_GetValidIGD(self.devList,
                            addr(self.urls),
                            addr(self.data),
                            self.lanAddr.cstring,
                            lanaddrlen).SelectIGDResult
  trimString(self.lanAddr)

type SentReceivedResult = Result[culonglong, cstring]

proc totalBytesSent*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalBytesSent(self.urls.controlURL_CIF, addr(self.data.CIF.servicetype))
  if res == cast[culonglong](UPNPCOMMAND_HTTP_ERROR):
    result.err(upnpError(res.cint))
  else:
    result.ok(res)

proc totalBytesReceived*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalBytesReceived(self.urls.controlURL_CIF, addr(self.data.CIF.servicetype))
  if res == cast[culonglong](UPNPCOMMAND_HTTP_ERROR):
    result.err(upnpError(res.cint))
  else:
    result.ok(res)

proc totalPacketsSent*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalPacketsSent(self.urls.controlURL_CIF, addr(self.data.CIF.servicetype))
  if res == cast[culonglong](UPNPCOMMAND_HTTP_ERROR):
    result.err(upnpError(res.cint))
  else:
    result.ok(res)

proc totalPacketsReceived*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalPacketsReceived(self.urls.controlURL_CIF, addr(self.data.CIF.servicetype))
  if res == cast[culonglong](UPNPCOMMAND_HTTP_ERROR):
    result.err(upnpError(res.cint))
  else:
    result.ok(res)

type StatusInfo* = object
  status*: string
  uptime*: cuint
  lastconnerror*: string

proc statusInfo*(self: Miniupnp): Result[StatusInfo, cstring] =
  var si: StatusInfo
  si.status.setLen(64)
  si.lastconnerror.setLen(64)
  let res = UPNP_GetStatusInfo(self.urls.controlURL,
                                addr(self.data.first.servicetype),
                                si.status.cstring,
                                addr(si.uptime),
                                si.lastconnerror.cstring)
  if res == UPNPCOMMAND_SUCCESS:
    trimString(si.status)
    trimString(si.lastconnerror)
    result.ok(si)
  else:
    result.err(upnpError(res))

proc connectionType*(self: Miniupnp): Result[string, cstring] =
  var connType = newString(64)
  let res = UPNP_GetConnectionTypeInfo(self.urls.controlURL,
                                        addr(self.data.first.servicetype),
                                        connType.cstring)
  if res == UPNPCOMMAND_SUCCESS:
    trimString(connType)
    result.ok(connType)
  else:
    result.err(upnpError(res))

proc externalIPAddress*(self: Miniupnp): Result[string, cstring] =
  var externalIP = newString(40)
  let res = UPNP_GetExternalIPAddress(self.urls.controlURL,
                                      addr(self.data.first.servicetype),
                                      externalIP.cstring)
  if res == UPNPCOMMAND_SUCCESS:
    trimString(externalIP)
    result.ok(externalIP)
  else:
    result.err(upnpError(res))

type UPNPProtocol* = enum
  TCP = "TCP"
  UDP = "UDP"

proc addPortMapping*(self: Miniupnp,
                      externalPort: string,
                      protocol: UPNPProtocol,
                      internalHost: string,
                      internalPort: string,
                      desc = "miniupnpc",
                      leaseDuration = 0,
                      externalIP = ""): Result[bool, cstring] =
  var extIP = externalIP.cstring
  if externalIP == "":
    # Some IGDs can't handle explicit external IPs here (they fail with "RemoteHostOnlySupportsWildcard").
    # That's why we default to an empty address, which gets converted into a
    # NULL pointer for the wrapped library.
    extIP = nil
  let res = UPNP_AddPortMapping(self.urls.controlURL,
                                addr(self.data.first.servicetype),
                                externalPort.cstring,
                                internalPort.cstring,
                                internalHost.cstring,
                                desc.cstring,
                                cstring($protocol),
                                extIP,
                                cstring($leaseDuration))
  if res == UPNPCOMMAND_SUCCESS:
    result.ok(true)
  else:
    result.err(upnpError(res))

## (IGD:2 only)
## Returns the actual external port (that may differ from the requested one), or
## an error string.
proc addAnyPortMapping*(self: Miniupnp,
                        externalPort: string,
                        protocol: UPNPProtocol,
                        internalHost: string,
                        internalPort: string,
                        desc = "miniupnpc",
                        leaseDuration = 0,
                        externalIP = ""): Result[string, cstring] =
  var extIP = externalIP.cstring
  if externalIP == "":
    extIP = nil
  var reservedPort = newString(6)
  let res = UPNP_AddAnyPortMapping(self.urls.controlURL,
                                addr(self.data.first.servicetype),
                                externalPort.cstring,
                                internalPort.cstring,
                                internalHost.cstring,
                                desc.cstring,
                                cstring($protocol),
                                extIP,
                                cstring($leaseDuration),
                                reservedPort.cstring)
  if res == UPNPCOMMAND_SUCCESS:
    trimString(reservedPort)
    result.ok(reservedPort)
  else:
    result.err(upnpError(res))

proc deletePortMapping*(self: Miniupnp,
                        externalPort: string,
                        protocol: UPNPProtocol,
                        remoteHost = ""): Result[bool, cstring] =
  var remHost = remoteHost.cstring
  if remoteHost == "":
    remHost = nil
  let res = UPNP_DeletePortMapping(self.urls.controlURL,
                                    addr(self.data.first.servicetype),
                                    externalPort.cstring,
                                    cstring($protocol),
                                    remHost)
  if res == UPNPCOMMAND_SUCCESS:
    result.ok(true)
  else:
    result.err(upnpError(res))

proc deletePortMappingRange*(self: Miniupnp,
                              externalPortStart: string,
                              externalPortEnd: string,
                              protocol: UPNPProtocol,
                              manage = false): Result[bool, cstring] =
  let res = UPNP_DeletePortMappingRange(self.urls.controlURL,
                                    addr(self.data.first.servicetype),
                                    externalPortStart.cstring,
                                    externalPortEnd.cstring,
                                    cstring($protocol),
                                    cstring($(manage.int)))
  if res == UPNPCOMMAND_SUCCESS:
    result.ok(true)
  else:
    result.err(upnpError(res))

## not supported by all routers
proc getPortMappingNumberOfEntries*(self: Miniupnp): Result[cuint, cstring] =
  var numEntries: cuint
  let res = UPNP_GetPortMappingNumberOfEntries(self.urls.controlURL,
                                                addr(self.data.first.servicetype),
                                                addr(numEntries))
  if res == UPNPCOMMAND_SUCCESS:
    result.ok(numEntries)
  else:
    result.err(upnpError(res))

type PortMappingRes* = object
  externalPort*: string
  internalClient*: string
  internalPort*: string
  protocol*: UPNPProtocol
  description*: string
  enabled*: bool
  remoteHost*: string
  leaseDuration*: uint64

proc getSpecificPortMapping*(self: Miniupnp,
                              externalPort: string,
                              protocol: UPNPProtocol,
                              remoteHost = ""): Result[PortMappingRes, cstring] =
  var
    portMapping = PortMappingRes(externalPort: externalPort,
                                  protocol: protocol,
                                  remoteHost: remoteHost)
    enabledStr = newString(4)
    leaseDurationStr = newString(16)

  portMapping.internalClient.setLen(40)
  portMapping.internalPort.setLen(6)
  portMapping.description.setLen(80)
  var remHost = remoteHost.cstring
  if remoteHost == "":
    remHost = nil
  let res = UPNP_GetSpecificPortMappingEntry(self.urls.controlURL,
                                              addr(self.data.first.servicetype),
                                              externalPort.cstring,
                                              cstring($protocol),
                                              remHost,
                                              portMapping.internalClient.cstring,
                                              portMapping.internalPort.cstring,
                                              portMapping.description.cstring,
                                              enabledStr.cstring,
                                              leaseDurationStr.cstring)
  if res == UPNPCOMMAND_SUCCESS:
    trimString(portMapping.internalClient)
    trimString(portMapping.internalPort)
    trimString(portMapping.description)
    trimString(enabledStr)
    portMapping.enabled = bool(parseInt(enabledStr))
    trimString(leaseDurationStr)
    portMapping.leaseDuration = parseBiggestUInt(leaseDurationStr)
    result.ok(portMapping)
  else:
    result.err(upnpError(res))

proc getGenericPortMapping*(self: Miniupnp,
                            index: int): Result[PortMappingRes, cstring] =
  var
    portMapping: PortMappingRes
    protocolStr = newString(4)
    enabledStr = newString(4)
    leaseDurationStr = newString(16)

  portMapping.externalPort.setLen(6)
  portMapping.internalClient.setLen(40)
  portMapping.internalPort.setLen(6)
  portMapping.description.setLen(80)
  portMapping.remoteHost.setLen(64)
  let res = UPNP_GetGenericPortMappingEntry(self.urls.controlURL,
                                            addr(self.data.first.servicetype),
                                            cstring($index),
                                            portMapping.externalPort.cstring,
                                            portMapping.internalClient.cstring,
                                            portMapping.internalPort.cstring,
                                            protocolStr.cstring,
                                            portMapping.description.cstring,
                                            enabledStr.cstring,
                                            portMapping.remoteHost.cstring,
                                            leaseDurationStr.cstring)
  if res == UPNPCOMMAND_SUCCESS:
    trimString(portMapping.externalPort)
    trimString(portMapping.internalClient)
    trimString(portMapping.internalPort)
    trimString(protocolStr)
    portMapping.protocol = parseEnum[UPNPProtocol](protocolStr)
    trimString(portMapping.description)
    trimString(enabledStr)
    portMapping.enabled = bool(parseInt(enabledStr))
    trimString(portMapping.remoteHost)
    trimString(leaseDurationStr)
    portMapping.leaseDuration = parseBiggestUInt(leaseDurationStr)
    result.ok(portMapping)
  else:
    result.err(upnpError(res))

