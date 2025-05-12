# Copyright (c) 2019-2024 Status Research & Development GmbH
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

import std/strutils,
      ./utils

when defined(miniupnpcUseSystemLibs):
  {.passc: staticExec("pkg-config --cflags miniupnpc").}
  {.passl: staticExec("pkg-config --libs miniupnpc").}
else:
  import os
  const
    rootPath = currentSourcePath.parentDir().parentDir().replace('\\', '/')
    miniupnpcPath = rootPath & "/vendor/miniupnp/miniupnpc"
    includeFlag = "-I" & miniupnpcPath & "/include"
    # The Makefiles of the miniupnp library have an inconsistency
    # where the output path is different on Windows:
    buildOutputDir = when defined(windows): ""
                      else: "/build"
    libraryPath = miniupnpcPath & buildOutputDir & "/libminiupnpc.a"
  {.passc: includeFlag.}
  # We can't use the {.link.} pragma in here, because it would place the static
  # library archive as the first object to be linked, which would lead to all
  # its exported symbols being ignored. We move it into the last position with {.passL.}.
  {.passl: libraryPath.}

when defined(windows):
  import nativesockets # for that wsaStartup() call at the end
  {.passc: "-DMINIUPNP_STATICLIB".}
  {.passl: "-lws2_32 -liphlpapi".}

################
# upnperrors.h #
################

##  convert error code to string
##
##  Work for both MiniUPnPc specific errors and UPnP standard defined
##  errors.
##
##  \param[in] err numerical error code
##  \return a string description of the error code
##          or NULL for undefinded errors
proc upnpError*(err: cint): cstring {.importc: "strupnperror",
                                     header: "upnperrors.h".}

######################
# portlistingparse.h #
######################

type
  ##  enum of all XML elements
  portMappingElt* {.size: sizeof(cint).} = enum
    PortMappingEltNone, PortMappingEntry, NewRemoteHost, NewExternalPort,
    NewProtocol, NewInternalPort, NewInternalClient, NewEnabled, NewDescription,
    NewLeaseTime

  ##  linked list of port mappings
  PortMapping* {.importc: "struct PortMapping",
                header: "portlistingparse.h", bycopy.} = object
    l_next* {.importc: "l_next".}: ptr PortMapping
      ##  next list element
    leaseTime* {.importc: "leaseTime".}: culonglong
      ##  in seconds
      ## assume the used C version is at lead C99 (see miniupnpctypes.h
      ## for the definition of UNSIGNED_INTEGER)
    externalPort* {.importc: "externalPort".}: cushort
      ##  external port
    internalPort* {.importc: "internalPort".}: cushort
      ##  internal port
    remoteHost* {.importc: "remoteHost".}: array[64, char]
      ##  empty for wildcard
    internalClient* {.importc: "internalClient".}: array[64, char]
      ##  internal IP address
    description* {.importc: "description".}: array[64, char]
      ##  description
    protocol* {.importc: "protocol".}: array[4, char]
      ##  `TCP` or `UDP`
    enabled* {.importc: "enabled".}: uint8
      ##  0 (false) or 1 (true)

  ##  structure for ParsePortListing()
  PortMappingParserData* {.importc: "struct PortMappingParserData",
                          header: "portlistingparse.h", bycopy.} = object
    l_head* {.importc: "l_head".}: ptr PortMapping
      ##  list head
    curelt* {.importc: "curelt".}: portMappingElt
      ##  currently parsed element

##################
# upnpcommands.h #
##################

##  MiniUPnPc return codes :
const
  UPNPCOMMAND_SUCCESS* = cint(0)
    ##  value for success
  UPNPCOMMAND_UNKNOWN_ERROR* = cint(-1)
    ##  value for unknown error
  UPNPCOMMAND_INVALID_ARGS* = cint(-2)
    ##  error while checking the arguments
  UPNPCOMMAND_HTTP_ERROR* = cint(-3)
    ##  HTTP communication error
  UPNPCOMMAND_INVALID_RESPONSE* = cint(-4)
    ##  The response contains invalid values
  UPNPCOMMAND_MEM_ALLOC_ERROR* = cint(-5)
    ##  Memory allocation error

##  WANCommonInterfaceConfig:GetTotalBytesSent
##
##  Note: this is a 32bits unsigned value and rolls over to 0 after reaching
##  the maximum value
##
##  \param[in] controlURL controlURL of the WANCommonInterfaceConfig of
##             a WANDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
proc UPNP_GetTotalBytesSent*(
    controlURL: cstring; servicetype: cstring
): culonglong {.importc: "UPNP_GetTotalBytesSent", header: "upnpcommands.h".}

##  WANCommonInterfaceConfig:GetTotalBytesReceived
##
##  Note: this is a 32bits unsigned value and rolls over to 0 after reaching
##  the maximum value
##
##  \param[in] controlURL controlURL of the WANCommonInterfaceConfig of a WANDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
proc UPNP_GetTotalBytesReceived*(
    controlURL: cstring; servicetype: cstring
): culonglong {.
    importc: "UPNP_GetTotalBytesReceived", header: "upnpcommands.h".}

##  WANCommonInterfaceConfig:GetTotalPacketsSent
##
##  Note: this is a 32bits unsigned value and rolls over to 0 after reaching
##  the maximum value
##
##  \param[in] controlURL controlURL of the WANCommonInterfaceConfig of a WANDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
proc UPNP_GetTotalPacketsSent*(
    controlURL: cstring; servicetype: cstring
): culonglong {.importc: "UPNP_GetTotalPacketsSent", header: "upnpcommands.h".}

##  WANCommonInterfaceConfig:GetTotalBytesReceived
##
##  Note: this is a 32bits unsigned value and rolls over to 0 after reaching
##  the maximum value
##
##  \param[in] controlURL controlURL of the WANCommonInterfaceConfig of a WANDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
proc UPNP_GetTotalPacketsReceived*(
    controlURL: cstring; servicetype: cstring
): culonglong {.
    importc: "UPNP_GetTotalPacketsReceived", header: "upnpcommands.h".}

##  WANIPConnection:GetStatusInfo()
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[out] status 64 bytes buffer : `Unconfigured`, `Connecting`,
##              `Connected`, `PendingDisconnect`, `Disconnecting`, `Disconnected`
##  \param[out] uptime time in seconds
##  \param[out] lastconnerror 64 bytes buffer : `ERROR_NONE`,
##              `ERROR_COMMAND_ABORTED`, `ERROR_NOT_ENABLED_FOR_INTERNET`,
##              `ERROR_USER_DISCONNECT`, `ERROR_ISP_DISCONNECT`,
##              `ERROR_IDLE_DISCONNECT`, `ERROR_FORCED_DISCONNECT`,
##              `ERROR_NO_CARRIER`, `ERROR_IP_CONFIGURATION`, `ERROR_UNKNOWN`
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP Error code
proc UPNP_GetStatusInfo*(
    controlURL: cstring; servicetype: cstring; status: cstring;
    uptime: ptr cuint; lastconnerror: cstring
): cint {.importc: "UPNP_GetStatusInfo", header: "upnpcommands.h".}

##  WANIPConnection:GetConnectionTypeInfo()
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[out] connectionType 64 characters buffer : `Unconfigured`,
##              `IP_Routed`, `IP_Bridged`
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP Error code
proc UPNP_GetConnectionTypeInfo*(
    controlURL: cstring; servicetype: cstring;
    connectionType: cstring
): cint {.importc: "UPNP_GetConnectionTypeInfo", header: "upnpcommands.h".}

##  WANIPConnection:GetExternalIPAddress()
##
##  possible UPnP Errors :
##  - 402 Invalid Args - See UPnP Device Architecture section on Control.
##  - 501 Action Failed - See UPnP Device Architecture section on Control.
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[out] extIpAdd 16 bytes buffer
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_UNKNOWN_ERROR,
##          #UPNPCOMMAND_INVALID_ARGS, #UPNPCOMMAND_HTTP_ERROR or an
##          UPnP error code
proc UPNP_GetExternalIPAddress*(
    controlURL: cstring; servicetype: cstring;
    extIpAdd: cstring
): cint {.importc: "UPNP_GetExternalIPAddress", header: "upnpcommands.h".}

##  UPNP_GetLinkLayerMaxBitRates()
##  call `WANCommonInterfaceConfig:GetCommonLinkProperties`
##
##  \param[in] controlURL controlURL of the WANCommonInterfaceConfig of a WANDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
##  \param[out] bitrateDown bits per second
##  \param[out] bitrateUp bits per second
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP Error Code.
proc UPNP_GetLinkLayerMaxBitRates*(
    controlURL: cstring; servicetype: cstring;
    bitrateDown: ptr cuint; bitrateUp: ptr cuint
): cint {.importc: "UPNP_GetLinkLayerMaxBitRates", header: "upnpcommands.h".}

##  WANIPConnection:AddPortMapping()
##
##  List of possible UPnP errors for AddPortMapping :
##  errorCode errorDescription (short) | Description (long)
##  ---------------------------------- | -----------------
##  402 Invalid Args | See UPnP Device Architecture section on Control.
##  501 Action Failed | See UPnP Device Architecture section on Control.
##  606 Action not authorized | The action requested REQUIRES authorization and the sender was not authorized.
##  715 WildCardNotPermittedInSrcIP | The source IP address cannot be wild-carded
##  716 WildCardNotPermittedInExtPort | The external port cannot be wild-carded
##  718 ConflictInMappingEntry | The port mapping entry specified conflicts with a mapping assigned previously to another client
##  724 SamePortValuesRequired | Internal and External port values must be the same
##  725 OnlyPermanentLeasesSupported | The NAT implementation only supports permanent lease times on port mappings
##  726 RemoteHostOnlySupportsWildcard | RemoteHost must be a wildcard and cannot be a specific IP address or DNS name
##  727 ExternalPortOnlySupportsWildcard | ExternalPort must be a wildcard and cannot be a specific port value
##  728 NoPortMapsAvailable | There are not enough free ports available to complete port mapping.
##  729 ConflictWithOtherMechanisms | Attempted port mapping is not allowed due to conflict with other mechanisms.
##  732 WildCardNotPermittedInIntPort | The internal port cannot be wild-carded
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[in] extPort External port
##  \param[in] inPort Internal port
##  \param[in] inClient IP of Internal client.
##  \param[in] desc Port Mapping description. if NULL, defaults to
##             "libminiupnpc"
##  \param[in] proto `TCP` or `UDP`
##  \param[in] remoteHost IP or empty string for wildcard. Most IGD don't
##             support it
##  \param[in] leaseDuration between 0 and 604800
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_MEM_ALLOC_ERROR, #UPNPCOMMAND_HTTP_ERROR,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP error code.
proc UPNP_AddPortMapping*(
    controlURL: cstring; servicetype: cstring;
    extPort: cstring; inPort: cstring; inClient: cstring;
    desc: cstring; proto: cstring; remoteHost: cstring;
    leaseDuration: cstring
): cint {.importc: "UPNP_AddPortMapping", header: "upnpcommands.h".}

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
proc UPNP_AddAnyPortMapping*(
    controlURL: cstring; servicetype: cstring;
    extPort: cstring; inPort: cstring; inClient: cstring;
    desc: cstring; proto: cstring; remoteHost: cstring;
    leaseDuration: cstring; reservedPort: cstring
): cint {.importc: "UPNP_AddAnyPortMapping", header: "upnpcommands.h".}

##  WANIPConnection:DeletePortMapping()
##
##  Use same argument values as what was used for UPNP_AddPortMapping()
##
##  List of possible UPnP errors for UPNP_DeletePortMapping() :
##  errorCode errorDescription (short) | Description (long)
##  ---------------------------------- | ------------------
##  402 Invalid Args | See UPnP Device Architecture section on Control.
##  606 Action not authorized | The action requested REQUIRES authorization and the sender was not authorized.
##  714 NoSuchEntryInArray | The specified value does not exist in the array
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[in] extPort External port
##  \param[in] proto `TCP` or `UDP`
##  \param[in] remoteHost IP or empty string for wildcard. Most IGD don't
##             support it
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_MEM_ALLOC_ERROR, #UPNPCOMMAND_HTTP_ERROR,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP error code.
proc UPNP_DeletePortMapping*(
    controlURL: cstring; servicetype: cstring;
    extPort: cstring; proto: cstring; remoteHost: cstring
): cint {.importc: "UPNP_DeletePortMapping", header: "upnpcommands.h".}

##  WANIPConnection:DeletePortRangeMapping()
##
##  Only in WANIPConnection:2
##  Use same argument values as what was used for AddPortMapping().
##  remoteHost is usually NULL because IGD don't support it.
##  Return Values :
##  0 : SUCCESS
##  NON ZERO : error. Either an UPnP error code or an undefined error.
##
##  List of possible UPnP errors for DeletePortMapping :
##  errorCode errorDescription (short) | Description (long)
##  ---------------------------------- | ------------------
##  606 Action not authorized | The action requested REQUIRES authorization and the sender was not authorized.
##  730 PortMappingNotFound | This error message is returned if no port mapping is found in the specified range.
##  733 InconsistentParameters | NewStartPort and NewEndPort values are not consistent.
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:2
##  \param[in] extPortStart External port range start
##  \param[in] extPortEnd External port range end
##  \param[in] proto `TCP` or `UDP`
##  \param[in] manage `0` to remove only the port mappings of this IGD,
##             `1` to remove port mappings also for other clients
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_MEM_ALLOC_ERROR, #UPNPCOMMAND_HTTP_ERROR,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP error code.
proc UPNP_DeletePortMappingRange*(
    controlURL: cstring; servicetype: cstring;
    extPortStart: cstring; extPortEnd: cstring;
    proto: cstring; manage: cstring
): cint {.importc: "UPNP_DeletePortMappingRange", header: "upnpcommands.h".}

##  WANIPConnection:GetPortMappingNumberOfEntries()
##
##  not supported by all routers
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[out] numEntries Port mappings count
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_HTTP_ERROR,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP error code.
proc UPNP_GetPortMappingNumberOfEntries*(
    controlURL: cstring; servicetype: cstring;
    numEntries: ptr cuint
): cint {.
    importc: "UPNP_GetPortMappingNumberOfEntries", header: "upnpcommands.h".}

##  retrieves an existing port mapping for a port:protocol
##
##  List of possible UPnP errors for UPNP_GetSpecificPortMappingEntry() :
##  errorCode errorDescription (short) | Description (long)
##  ---------------------------------- | ------------------
##  402 Invalid Args | See UPnP Device Architecture section on Control.
##  501 Action Failed | See UPnP Device Architecture section on Control.
##  606 Action not authorized | The action requested REQUIRES authorization and the sender was not authorized.
##  714 NoSuchEntryInArray | The specified value does not exist in the array.
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[in] extPort External port
##  \param[in] proto `TCP` or `UDP`
##  \param[in] remoteHost IP or empty string for wildcard. Most IGD don't
##             support it
##  \param[out] intClient 16 bytes buffer
##  \param[out] intPort 6 bytes buffer
##  \param[out] desc 80 bytes buffer
##  \param[out] enabled 4 bytes buffer
##  \param[out] leaseDuration 16 bytes
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP Error Code.
proc UPNP_GetSpecificPortMappingEntry*(
    controlURL: cstring; servicetype: cstring;
    extPort: cstring; proto: cstring;
    remoteHost: cstring; intClient: cstring;
    intPort: cstring; desc: cstring;
    enabled: cstring; leaseDuration: cstring
): cint {.
    importc: "UPNP_GetSpecificPortMappingEntry", header: "upnpcommands.h".}

##  WANIPConnection:GetGenericPortMappingEntry()
##
##  errorCode errorDescription (short) | Description (long)
##  ---------------------------------- | ------------------
##  402 Invalid Args | See UPnP Device Architecture section on Control.
##  606 Action not authorized | The action requested REQUIRES authorization and the sender was not authorized.
##  713 SpecifiedArrayIndexInvalid | The specified array index is out of bounds
##
##  \param[in] controlURL controlURL of the WANIPConnection of a WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:1
##  \param[in] index
##  \param[out] extPort 6 bytes buffer
##  \param[out] intClient 16 bytes buffer
##  \param[out] intPort 6 bytes buffer
##  \param[out] protocol 4 bytes buffer
##  \param[out] desc 80 bytes buffer
##  \param[out] enabled 4 bytes buffer
##  \param[out] rHost 64 bytes buffer
##  \param[out] duration 16 bytes buffer
##  \return #UPNPCOMMAND_SUCCESS, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_UNKNOWN_ERROR or a UPnP Error Code.
proc UPNP_GetGenericPortMappingEntry*(
    controlURL: cstring; servicetype: cstring;
    index: cstring; extPort: cstring;
    intClient: cstring; intPort: cstring;
    protocol: cstring; desc: cstring;
    enabled: cstring; rHost: cstring;
    duration: cstring
): cint {.importc: "UPNP_GetGenericPortMappingEntry", header: "upnpcommands.h".}

##   retrieval of a list of existing port mappings
##
##  Available in IGD v2 : WANIPConnection:GetListOfPortMappings()
##
##  errorCode errorDescription (short) | Description (long)
##  ---------------------------------- | ------------------
##  606 Action not authorized | The action requested REQUIRES authorization and the sender was not authorized.
##  730 PortMappingNotFound | no port mapping is found in the specified range.
##  733 InconsistantParameters | NewStartPort and NewEndPort values are not consistent.
##
##  \param[in] controlURL controlURL of the WANIPConnection of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPConnection:2
##  \param[in] startPort port interval start
##  \param[in] endPort port interval end
##  \param[in] protocol `TCP` or `UDP`
##  \param[in] numberOfPorts size limit of the list returned. `0` to request
##             all port mappings
##  \param[out] data port mappings list
proc UPNP_GetListOfPortMappings*(
    controlURL: cstring; servicetype: cstring;
    startPort: cstring; endPort: cstring;
    protocol: cstring; numberOfPorts: cstring;
    data: ptr PortMappingParserData
): cint {.importc: "UPNP_GetListOfPortMappings", header: "upnpcommands.h".}

##  GetFirewallStatus() retrieves whether the firewall is enabled
##  and pinhole can be created through UPnP
##
##  IGD:2, functions for service WANIPv6FirewallControl:1
##
##  \param[in] controlURL controlURL of the WANIPv6FirewallControl of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPv6FirewallControl:1
##  \param[out] firewallEnabled false (0) or true (1)
##  \param[out] inboundPinholeAllowed false (0) or true (1)
##  \return #UPNPCOMMAND_UNKNOWN_ERROR, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_HTTP_ERROR, #UPNPCOMMAND_SUCCESS or an UPnP error code
proc UPNP_GetFirewallStatus*(
    controlURL: cstring; servicetype: cstring;
    firewallEnabled: ptr cint;
    inboundPinholeAllowed: ptr cint
): cint {.importc: "UPNP_GetFirewallStatus", header: "upnpcommands.h".}

##  retrieve default value after which automatically created pinholes
##  expire
##
##  The returned value may be specific to the \p proto, \p remoteHost,
##  \p remotePort, \p intClient and \p intPort, but this behavior depends
##  on the implementation of the firewall.
##
##  \param[in] controlURL controlURL of the WANIPv6FirewallControl of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPv6FirewallControl:1
##  \param[in] remoteHost
##  \param[in] remotePort
##  \param[in] intClient
##  \param[in] intPort
##  \param[in] proto `TCP` or `UDP`
##  \param[out] opTimeout lifetime in seconds of an inbound "automatic"
##              firewall pinhole created by an outbound traffic initiation.
##  \return #UPNPCOMMAND_UNKNOWN_ERROR, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_HTTP_ERROR, #UPNPCOMMAND_SUCCESS or an UPnP error code
proc UPNP_GetOutboundPinholeTimeout*(
    controlURL: cstring; servicetype: cstring;
    remoteHost: cstring; remotePort: cstring;
    intClient: cstring; intPort: cstring;
    proto: cstring; opTimeout: ptr cint
): cint {.importc: "UPNP_GetOutboundPinholeTimeout", header: "upnpcommands.h".}

##  create a new pinhole that allows incoming traffic to pass
##  through the firewall
##
##  \param[in] controlURL controlURL of the WANIPv6FirewallControl of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPv6FirewallControl:1
##  \param[in] remoteHost literal presentation of IPv6 address or domain name.
##             empty string for wildcard
##  \param[in] remotePort remote host port. Likely 0 (for wildcard)
##  \param[in] intClient IP address of internal client. cannot be wildcarded
##  \param[in] intPort client port. 0 for wildcard
##  \param[in] proto IP protocol integer (6 for TCP, 17 for UDP, etc.)
##             65535 for wildcard.
##  \param[in] leaseTime in seconds
##  \param[out] uniqueID 8 bytes buffer
##  \return #UPNPCOMMAND_UNKNOWN_ERROR, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_HTTP_ERROR, #UPNPCOMMAND_SUCCESS or an UPnP error code
proc UPNP_AddPinhole*(
    controlURL: cstring; servicetype: cstring; remoteHost: cstring;
    remotePort: cstring; intClient: cstring; intPort: cstring;
    proto: cstring; leaseTime: cstring; uniqueID: cstring
): cint {.importc: "UPNP_AddPinhole", header: "upnpcommands.h".}

##  update a pinhole’s lease time
##
##  \param[in] controlURL controlURL of the WANIPv6FirewallControl of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPv6FirewallControl:1
##  \param[in] uniqueID value obtained through UPNP_AddPinhole()
##  \param[in] leaseTime in seconds
##  \return #UPNPCOMMAND_UNKNOWN_ERROR, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_HTTP_ERROR, #UPNPCOMMAND_SUCCESS or an UPnP error code
proc UPNP_UpdatePinhole*(
    controlURL: cstring; servicetype: cstring;
    uniqueID: cstring; leaseTime: cstring
): cint {.importc: "UPNP_UpdatePinhole", header: "upnpcommands.h".}

##  remove a pinhole
##
##  \param[in] controlURL controlURL of the WANIPv6FirewallControl of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPv6FirewallControl:1
##  \param[in] uniqueID value obtained through UPNP_AddPinhole()
##  \return #UPNPCOMMAND_UNKNOWN_ERROR, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_HTTP_ERROR, #UPNPCOMMAND_SUCCESS or an UPnP error code
proc UPNP_DeletePinhole*(
    controlURL: cstring; servicetype: cstring; uniqueID: cstring
): cint {.importc: "UPNP_DeletePinhole", header: "upnpcommands.h".}

##  checking if a certain pinhole allows traffic to pass through the firewall
##
##  \param[in] controlURL controlURL of the WANIPv6FirewallControl of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPv6FirewallControl:1
##  \param[in] uniqueID value obtained through UPNP_AddPinhole()
##  \param[out] isWorking `0` for false, `1` for true
##  \return #UPNPCOMMAND_UNKNOWN_ERROR, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_HTTP_ERROR, #UPNPCOMMAND_SUCCESS or an UPnP error code
proc UPNP_CheckPinholeWorking*(
    controlURL: cstring; servicetype: cstring;
    uniqueID: cstring; isWorking: ptr cint
): cint {.importc: "UPNP_CheckPinholeWorking", header: "upnpcommands.h".}

##  get the total number of IP packets which have been going through
##  the specified pinhole
##  \todo \p packets should be #UNSIGNED_INTEGER
##  \param[in] controlURL controlURL of the WANIPv6FirewallControl of a
##             WANConnectionDevice
##  \param[in] servicetype urn:schemas-upnp-org:service:WANIPv6FirewallControl:1
##  \param[in] uniqueID value obtained through UPNP_AddPinhole()
##  \param[out] packets how many IP packets have been going through the
##              specified pinhole
##  \return #UPNPCOMMAND_UNKNOWN_ERROR, #UPNPCOMMAND_INVALID_ARGS,
##          #UPNPCOMMAND_HTTP_ERROR, #UPNPCOMMAND_SUCCESS or an UPnP error code
proc UPNP_GetPinholePackets*(
    controlURL: cstring; servicetype: cstring;
    uniqueID: cstring; packets: ptr cint
): cint {.importc: "UPNP_GetPinholePackets", header: "upnpcommands.h".}

####################
# igd_desc_parse.h #
####################

const
  MINIUPNPC_URL_MAXSIZE* = (128)
    ##  maximum lenght of URLs

type
  ##  Structure to store the result of the parsing of UPnP
  ##  descriptions of Internet Gateway Devices services
  IGDdatas_service* {.importc: "struct IGDdatas_service",
                     header: "igd_desc_parse.h", bycopy.} = object
    controlurl* {.importc: "controlurl".}: array[MINIUPNPC_URL_MAXSIZE, char]
      ##  controlURL for the service
    eventsuburl* {.importc: "eventsuburl".}: array[MINIUPNPC_URL_MAXSIZE, char]
      ##  eventSubURL for the service
    scpdurl* {.importc: "scpdurl".}: array[MINIUPNPC_URL_MAXSIZE, char]
      ##  SCPDURL for the service
    servicetype* {.importc: "servicetype".}: array[MINIUPNPC_URL_MAXSIZE, char]
      ##  serviceType
      ##  char devicetype[MINIUPNPC_URL_MAXSIZE];

  ## Structure to store the result of the parsing of UPnP
  ## descriptions of Internet Gateway Devices
  IGDdatas* {.importc: "struct IGDdatas",
             header: "igd_desc_parse.h", bycopy.} = object
    cureltname* {.importc: "cureltname".}: array[MINIUPNPC_URL_MAXSIZE, char]
      ##  current element name
    urlbase* {.importc: "urlbase".}: array[MINIUPNPC_URL_MAXSIZE, char]
      ##  URLBase
    presentationurl* {.importc: "presentationurl".}:
        array[MINIUPNPC_URL_MAXSIZE, char]
      ##  presentationURL
    level* {.importc: "level".}: cint
      ##  depth into the XML tree
    CIF* {.importc: "CIF".}: IGDdatas_service
      ##  "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1"
    first* {.importc: "first".}: IGDdatas_service
      ##  first of "urn:schemas-upnp-org:service:WANIPConnection:1"
      ##  or "urn:schemas-upnp-org:service:WANPPPConnection:1"
    second* {.importc: "second".}: IGDdatas_service
      ##  second of "urn:schemas-upnp-org:service:WANIPConnection:1"
      ##  or "urn:schemas-upnp-org:service:WANPPPConnection:1"
    IPv6FC* {.importc: "IPv6FC".}: IGDdatas_service
      ##  "urn:schemas-upnp-org:service:WANIPv6FirewallControl:1"
    tmp* {.importc: "tmp".}: IGDdatas_service
      ##  currently parsed service

#############
# upnpdev.h #
#############

type
  ##  UPnP device linked-list
  UPNPDev* {.importc: "struct UPNPDev", header: "upnpdev.h", bycopy.} = object
    pNext* {.importc: "pNext".}: ptr UPNPDev
      ##  pointer to the next element
    descURL* {.importc: "descURL".}: cstring
      ##  root description URL
    st* {.importc: "st".}: cstring
      ##  ST: as advertised
    usn* {.importc: "usn".}: cstring
      ##  USN: as advertised
    scope_id* {.importc: "scope_id".}: cuint
      ##  IPv6 scope id of the network interface
    buffer* {.importc: "buffer".}: array[3, char]
      ##  C99 flexible array member
      ##  buffer for descURL, st and usn

##  free list returned by upnpDiscover()
##  \param[in] devlist linked list to free
proc freeUPNPDevlist*(
    devlist: ptr UPNPDev) {.importc: "freeUPNPDevlist", header: "upnpdev.h".}

###############
# miniupnpc.h #
###############

##  error codes :
const
  UPNPDISCOVER_SUCCESS* = cint(0)
    ##  value for success
  UPNPDISCOVER_UNKNOWN_ERROR* = cint(-1)
    ##  value for unknown error
  UPNPDISCOVER_SOCKET_ERROR* = cint(-101)
    ##  value for a socket error
  UPNPDISCOVER_MEMORY_ERROR* = cint(-102)
    ##  value for a memory allocation error

# We use importConst here because when a system header is used, we want the
# number from the actual header file.

##  software version
importConst(MINIUPNPC_VERSION, "miniupnpc.h", cstring)

##  C API version
importConst(MINIUPNPC_API_VERSION, "miniupnpc.h", cint)

const
  UPNP_LOCAL_PORT_ANY* = cint(0)
    ##  any (ie system chosen) port
  UPNP_LOCAL_PORT_SAME* = cint(1)
    ##  Use as an alias for 1900 for backwards compatibility

type
  ##  UPnP method argument
  UPNParg* {.importc: "struct UPNParg", header: "miniupnpc.h", bycopy.} = object
    elt* {.importc: "elt".}: cstring
      ##  UPnP argument name
    val* {.importc: "val".}: cstring
      ##  UPnP argument value

##  execute a UPnP method (SOAP action)
##
##  \param[in] url Control URL for the service
##  \param[in] service service to use
##  \param[in] action action to call
##  \param[in] args action arguments
##  \param[out] bufsize the size of the returned buffer
##  \return NULL in case of error or the raw XML response
proc simpleUPnPcommand*(
    url: cstring,
    service: cstring,
    action: cstring,
    args: ptr UPNParg,
    bufsize: ptr cint
): cstring {.importc: "simpleUPnPcommand", header: "miniupnpc.h".}

##  Discover UPnP IGD on the network.
##
##  The discovered devices are returned as a chained list.
##  It is up to the caller to free the list with freeUPNPDevlist().
##  If available, device list will be obtained from MiniSSDPd.
##
##  \param[in] delay (in millisecond) maximum time for waiting any device
##             response
##  \param[in] multicastif If not NULL, used instead of the default
##             multicast interface for sending SSDP discover packets
##  \param[in] minissdpdsock Path to minissdpd socket, default is used if
##             NULL
##  \param[in] localport Source port to send SSDP packets.
##             #UPNP_LOCAL_PORT_SAME for 1900 (same as destination port)
##             #UPNP_LOCAL_PORT_ANY to let system assign a source port
##  \param[in] ipv6 0 for IPv4, 1 of IPv6
##  \param[in] ttl should default to 2 as advised by UDA 1.1
##  \param[out] error error code when NULL is returned
##  \return NULL or a linked list
proc upnpDiscover*(
    delay: cint; multicastif: cstring; minissdpdsock: cstring;
    localport: cint; ipv6: cint; ttl: uint8; error: ptr cint
): ptr UPNPDev {.importc: "upnpDiscover", header: "miniupnpc.h".}

##  Discover all UPnP devices on the network
##
##  search for "ssdp:all"
##  \param[in] delay (in millisecond) maximum time for waiting any device
##             response
##  \param[in] multicastif If not NULL, used instead of the default
##             multicast interface for sending SSDP discover packets
##  \param[in] minissdpdsock Path to minissdpd socket, default is used if
##             NULL
##  \param[in] localport Source port to send SSDP packets.
##             #UPNP_LOCAL_PORT_SAME for 1900 (same as destination port)
##             #UPNP_LOCAL_PORT_ANY to let system assign a source port
##  \param[in] ipv6 0 for IPv4, 1 of IPv6
##  \param[in] ttl should default to 2 as advised by UDA 1.1
##  \param[out] error error code when NULL is returned
##  \return NULL or a linked list
proc upnpDiscoverAll*(
    delay: cint; multicastif: cstring; minissdpdsock: cstring;
    localport: cint; ipv6: cint; ttl: uint8; error: ptr cint
): ptr UPNPDev {.importc: "upnpDiscoverAll", header: "miniupnpc.h".}

##  Discover one type of UPnP devices
##
##  \param[in] device device type to search
##  \param[in] delay (in millisecond) maximum time for waiting any device
##             response
##  \param[in] multicastif If not NULL, used instead of the default
##             multicast interface for sending SSDP discover packets
##  \param[in] minissdpdsock Path to minissdpd socket, default is used if
##             NULL
##  \param[in] localport Source port to send SSDP packets.
##             #UPNP_LOCAL_PORT_SAME for 1900 (same as destination port)
##             #UPNP_LOCAL_PORT_ANY to let system assign a source port
##  \param[in] ipv6 0 for IPv4, 1 of IPv6
##  \param[in] ttl should default to 2 as advised by UDA 1.1
##  \param[out] error error code when NULL is returned
##  \return NULL or a linked list
proc upnpDiscoverDevice*(
    device: cstring; delay: cint; multicastif: cstring;
    minissdpdsock: cstring; localport: cint; ipv6: cint;
    ttl: uint8; error: ptr cint
): ptr UPNPDev {.importc: "upnpDiscoverDevice", header: "miniupnpc.h".}

##  Discover one or several type of UPnP devices
##
##  \param[in] deviceTypes array of device types to search (ending with NULL)
##  \param[in] delay (in millisecond) maximum time for waiting any device
##             response
##  \param[in] multicastif If not NULL, used instead of the default
##             multicast interface for sending SSDP discover packets
##  \param[in] minissdpdsock Path to minissdpd socket, default is used if
##             NULL
##  \param[in] localport Source port to send SSDP packets.
##             #UPNP_LOCAL_PORT_SAME for 1900 (same as destination port)
##             #UPNP_LOCAL_PORT_ANY to let system assign a source port
##  \param[in] ipv6 0 for IPv4, 1 of IPv6
##  \param[in] ttl should default to 2 as advised by UDA 1.1
##  \param[out] error error code when NULL is returned
##  \param[in] searchalltypes 0 to stop with the first type returning results
##  \return NULL or a linked list
proc upnpDiscoverDevices*(
    deviceTypes: ptr cstring; delay: cint; multicastif: cstring;
    minissdpdsock: cstring; localport: cint; ipv6: cint;
    ttl: uint8; error: ptr cint; searchalltypes: cint
): ptr UPNPDev {.importc: "upnpDiscoverDevices", header: "miniupnpc.h".}

type
  ##  structure used to get fast access to urls
  UPNPUrls* {.importc: "struct UPNPUrls", header: "miniupnpc.h", bycopy.} = object
    controlURL* {.importc: "controlURL".}: cstring
      ##  controlURL of the WANIPConnection
    ipcondescURL* {.importc: "ipcondescURL".}: cstring
      ##  url of the description of the WANIPConnection
    controlURL_CIF* {.importc: "controlURL_CIF".}: cstring
      ##  controlURL of the WANCommonInterfaceConfig
    controlURL_6FC* {.importc: "controlURL_6FC".}: cstring
      ##  controlURL of the WANIPv6FirewallControl
    rootdescURL* {.importc: "rootdescURL".}: cstring
      ##  url of the root description

const
  UPNP_NO_IGD* = cint(0)
    ##  NO IGD found
  UPNP_CONNECTED_IGD* = cint(1)
    ##  valid and connected IGD
  UPNP_PRIVATEIP_IGD* = cint(2)
    ##  valid and connected IGD but with a reserved address
    ##  (non routable)
  UPNP_DISCONNECTED_IGD* = cint(3)
    ##  valid but not connected IGD
  UPNP_UNKNOWN_DEVICE* = cint(4)
    ##  UPnP device not recognized as an IGD

##  look for a valid and possibly connected IGD in the list
##
##  In any non zero return case, the urls and data structures
##  passed as parameters are set. Donc forget to call FreeUPNPUrls(urls) to
##  free allocated memory.
##  \param[in] devlist A device list obtained with upnpDiscover() /
##             upnpDiscoverAll() / upnpDiscoverDevice() / upnpDiscoverDevices()
##  \param[out] urls Urls for the IGD found
##  \param[out] data datas for the IGD found
##  \param[out] lanaddr buffer to copy the local address of the host to reach the IGD
##  \param[in] lanaddrlen size of the lanaddr buffer
##  \param[out] wanaddr buffer to copy the public address of the IGD
##  \param[in] wanaddrlen size of the wanaddr buffer
##  \return #UPNP_NO_IGD / #UPNP_CONNECTED_IGD / #UPNP_PRIVATEIP_IGD /
##          #UPNP_DISCONNECTED_IGD / #UPNP_UNKNOWN_DEVICE
proc UPNP_GetValidIGD*(
    devlist: ptr UPNPDev; urls: ptr UPNPUrls; data: ptr IGDdatas;
    lanaddr: cstring; lanaddrlen: cint;
    wanaddr: cstring; wanaddrlen: cint
): cint {.importc: "UPNP_GetValidIGD", header: "miniupnpc.h".}

##  Get IGD URLs and data for URL
##
##  Used when skipping the discovery process.
##  \param[in] rootdescurl Root description URL of the device
##  \param[out] urls Urls for the IGD found
##  \param[out] data datas for the IGD found
##  \param[out] lanaddr buffer to copy the local address of the host to reach the IGD
##  \param[in] lanaddrlen size of the lanaddr buffer
##  \return 0 Not ok / 1 OK
proc UPNP_GetIGDFromUrl*(
    rootdescurl: cstring; urls: ptr UPNPUrls; data: ptr IGDdatas;
    lanaddr: cstring; lanaddrlen: cint
): cint {.importc: "UPNP_GetIGDFromUrl", header: "miniupnpc.h".}

##  free the members of a UPNPUrls struct
##
##  All URLs buffers are freed and zeroed
##  \param[out] urls
proc freeUPNPUrls*(
    a1: ptr UPNPUrls) {.importc: "FreeUPNPUrls", header: "miniupnpc.h".}

##  check the current connection status of an IGD
##
##  it uses UPNP_GetStatusInfo()
##  \param[in] urls IGD URLs
##  \param[in] data IGD data
##  \return 1 Connected / 0 Disconnected
proc UPNPIGD_IsConnected*(
    a1: ptr UPNPUrls; a2: ptr IGDdatas
): cint {.importc: "UPNPIGD_IsConnected", header: "miniupnpc.h".}

###################
# custom wrappers #
###################

import results
export results

type Miniupnp* = ref object
  devList*: ptr UPNPDev
  urls*: UPNPUrls
  data*: IGDdatas
  discoverDelay*: cint # in ms, the delay defaults to 1000ms if this is left 0
  multicastIF*: string
  miniSsdpdSocket*: string
  localPort*: cint
  ipv6*: cint
  ttl*: uint8
  error*: cint
  lanAddr*: string
  wanAddr*: string

proc close*(x: Miniupnp) =
  if x.devList != nil:
    freeUPNPDevlist(x.devList)
    x.devList = nil
    freeUPNPUrls(addr(x.urls))

proc newMiniupnp*(): Miniupnp =
  doAssert MINIUPNPC_API_VERSION == 20
  new(result)
  result.ttl = 2.uint8

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
  IGDNotFound = UPNP_NO_IGD.int
  IGDFound = UPNP_CONNECTED_IGD.int
  IGDIpNotRoutable = UPNP_PRIVATEIP_IGD.int
  IGDNotConnected = UPNP_DISCONNECTED_IGD.int
  NotAnIGD = UPNP_UNKNOWN_DEVICE.int

proc selectIGD*(self: Miniupnp): SelectIGDResult =
  let addrLen = 40.cint
  self.lanAddr.setLen(40)
  self.wanAddr.setLen(40)
  let res = UPNP_GetValidIGD(
    self.devList, addr(self.urls), addr(self.data), self.lanAddr.cstring,
    addrLen, self.wanAddr.cstring, addrLen)
  trimString(self.lanAddr)
  trimString(self.wanAddr)
  if res >= low(SelectIGDResult).int and res <= high(SelectIGDResult).int:
    res.SelectIGDResult
  else:
    IGDNotFound  # treat internal error as not found

type SentReceivedResult = Result[culonglong, cstring]

proc totalBytesSent*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalBytesSent(self.urls.controlURL_CIF, cast[cstring](addr(self.data.CIF.servicetype)))
  if res == cast[culonglong](UPNPCOMMAND_HTTP_ERROR):
    result.err(upnpError(res.cint))
  else:
    result.ok(res)

proc totalBytesReceived*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalBytesReceived(self.urls.controlURL_CIF, cast[cstring](addr(self.data.CIF.servicetype)))
  if res == cast[culonglong](UPNPCOMMAND_HTTP_ERROR):
    result.err(upnpError(res.cint))
  else:
    result.ok(res)

proc totalPacketsSent*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalPacketsSent(self.urls.controlURL_CIF, cast[cstring](addr(self.data.CIF.servicetype)))
  if res == cast[culonglong](UPNPCOMMAND_HTTP_ERROR):
    result.err(upnpError(res.cint))
  else:
    result.ok(res)

proc totalPacketsReceived*(self: Miniupnp): SentReceivedResult =
  let res = UPNP_GetTotalPacketsReceived(self.urls.controlURL_CIF, cast[cstring](addr(self.data.CIF.servicetype)))
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
                                cast[cstring](addr(self.data.first.servicetype)),
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
                                        cast[cstring](addr(self.data.first.servicetype)),
                                        connType.cstring)
  if res == UPNPCOMMAND_SUCCESS:
    trimString(connType)
    result.ok(connType)
  else:
    result.err(upnpError(res))

proc externalIPAddress*(self: Miniupnp): Result[string, cstring] =
  var externalIP = newString(40)
  let res = UPNP_GetExternalIPAddress(self.urls.controlURL,
                                      cast[cstring](addr(self.data.first.servicetype)),
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
                                cast[cstring](addr(self.data.first.servicetype)),
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
                                cast[cstring](addr(self.data.first.servicetype)),
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
                                    cast[cstring](addr(self.data.first.servicetype)),
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
                                    cast[cstring](addr(self.data.first.servicetype)),
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
                                                cast[cstring](addr(self.data.first.servicetype)),
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
                                              cast[cstring](addr(self.data.first.servicetype)),
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
    portMapping.enabled = try:
        bool(parseInt(enabledStr))
      except ValueError: # shouldn't happen..
        false
    trimString(leaseDurationStr)
    portMapping.leaseDuration =
      try:
        parseBiggestUInt(leaseDurationStr)
      except ValueError:
        return err("upnp: cannot parsse lease duration")
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
                                            cast[cstring](addr(self.data.first.servicetype)),
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
    portMapping.protocol =
      try:
        parseEnum[UPNPProtocol](protocolStr)
      except ValueError:
        return err("upnp: cannot parse upnp protocol")
    trimString(portMapping.description)
    trimString(enabledStr)
    portMapping.enabled =
      try:
        bool(parseInt(enabledStr))
      except ValueError:
        false
    trimString(portMapping.remoteHost)
    trimString(leaseDurationStr)
    portMapping.leaseDuration =
      try:
        parseBiggestUInt(leaseDurationStr)
      except ValueError:
        return err("upnp: cannot parse duration")
    result.ok(portMapping)
  else:
    result.err(upnpError(res))
