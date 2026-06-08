# Copyright (c) 2019-2022 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

################################
# headers and library location #
################################

import os, strutils
import results
export results

when defined(windows):
  import winlean
else:
  import posix

when defined(libpcpnatpmpUseSystemLibs):
  {.passl: "-lpcpnatpmp".}
else:
  const vendorPath = currentSourcePath.parentDir().parentDir().replace('\\', '/') & "/vendor/libpcpnatpmp"
  {.passc: "-I" & vendorPath & "/lib/include".}
  {.passl: vendorPath & "/build/lib/libpcpnatpmp.a".}

when defined(windows):
  {.passl: "-lws2_32 -liphlpapi".}

{.push raises: [Defect].}

###############
# pcpnatpmp.h #
###############

const PCP_HDR = "pcpnatpmp.h"

## Error codes returned by the library
type PcpErrno* {.importc: "pcp_errno", header: PCP_HDR.} = cint

const
  PCP_ERR_SUCCESS*            = PcpErrno(0)
  PCP_ERR_MAX_SIZE*           = PcpErrno(-1)
  PCP_ERR_OPT_ALREADY_PRESENT* = PcpErrno(-2)
  PCP_ERR_BAD_AFINET*         = PcpErrno(-3)
  PCP_ERR_SEND_FAILED*        = PcpErrno(-4)
  PCP_ERR_RECV_FAILED*        = PcpErrno(-5)
  PCP_ERR_UNSUP_VERSION*      = PcpErrno(-6)
  PCP_ERR_NO_MEM*             = PcpErrno(-7)
  PCP_ERR_BAD_ARGS*           = PcpErrno(-8)
  PCP_ERR_UNKNOWN*            = PcpErrno(-9)
  PCP_ERR_SHORT_LIFETIME_ERR* = PcpErrno(-10)
  PCP_ERR_TIMEOUT*            = PcpErrno(-11)
  PCP_ERR_NOT_FOUND*          = PcpErrno(-12)
  PCP_ERR_WOULDBLOCK*         = PcpErrno(-13)
  PCP_ERR_ADDRINUSE*          = PcpErrno(-14)

## Log levels
type PcpLoglvlE* {.importc: "pcp_loglvl_e", header: PCP_HDR.} = cint

const
  PCP_LOGLVL_NONE*  = PcpLoglvlE(0)
  PCP_LOGLVL_ERR*   = PcpLoglvlE(1)
  PCP_LOGLVL_WARN*  = PcpLoglvlE(2)
  PCP_LOGLVL_INFO*  = PcpLoglvlE(3)
  PCP_LOGLVL_PERR*  = PcpLoglvlE(4)
  PCP_LOGLVL_DEBUG* = PcpLoglvlE(5)

## Flow state returned by pcp_wait / pcp_eval_flow_state
type PcpFstateE* {.importc: "pcp_fstate_e", header: PCP_HDR.} = cint

const
  pcp_state_processing*           = PcpFstateE(0)
  pcp_state_succeeded*            = PcpFstateE(1)
  pcp_state_partial_result*       = PcpFstateE(2)
  pcp_state_short_lifetime_error* = PcpFstateE(3)
  pcp_state_failed*               = PcpFstateE(4)

## Opaque context and flow types
type
  PcpCtxT* {.importc: "pcp_ctx_t", header: PCP_HDR, incompleteStruct.} = object
  PcpFlowT* {.importc: "pcp_flow_t", header: PCP_HDR, incompleteStruct.} = object

## Flow info structure returned by pcp_flow_get_info.
## ext_port and int_port are in *network* byte order; use ntohs() to convert.
type PcpFlowInfoT* {.importc: "pcp_flow_info_t", header: PCP_HDR, bycopy.} = object
  flowResult*      {.importc: "result".}:           PcpFstateE
  pcpServerIp*     {.importc: "pcp_server_ip".}:   In6Addr
  extIp*           {.importc: "ext_ip".}:           In6Addr
  extPort*         {.importc: "ext_port".}:         uint16
  recvLifetimeEnd* {.importc: "recv_lifetime_end".}: clong
  lifetimeRenewS*  {.importc: "lifetime_renew_s".}: clong
  pcpResultCode*   {.importc: "pcp_result_code".}:  uint8
  intIp*           {.importc: "int_ip".}:           In6Addr
  intPort*         {.importc: "int_port".}:         uint16
  intScopeId*      {.importc: "int_scope_id".}:     uint32
  dstIp*           {.importc: "dst_ip".}:           In6Addr
  dstPort*         {.importc: "dst_port".}:         uint16
  protocol*        {.importc: "protocol".}:         uint8
  learnedDscp*     {.importc: "learned_dscp".}:     uint8

## Auto-discovery flag constants
const
  ENABLE_AUTODISCOVERY*  = uint8(1)
  DISABLE_AUTODISCOVERY* = uint8(0)

## Raw C proc bindings

proc pcp_init*(autodiscovery: uint8; socket_vt: pointer): ptr PcpCtxT
  {.importc: "pcp_init", header: PCP_HDR.}

proc pcp_terminate*(ctx: ptr PcpCtxT; close_flows: cint)
  {.importc: "pcp_terminate", header: PCP_HDR.}

proc pcp_add_server*(ctx: ptr PcpCtxT; pcp_server: ptr SockAddr; pcp_version: uint8): cint
  {.importc: "pcp_add_server", header: PCP_HDR.}

proc pcp_new_flow*(ctx: ptr PcpCtxT;
                   src_addr: ptr SockAddr;
                   dst_addr: ptr SockAddr;
                   ext_addr: ptr SockAddr;
                   protocol: uint8;
                   lifetime: uint32;
                   userdata: pointer): ptr PcpFlowT
  {.importc: "pcp_new_flow", header: PCP_HDR.}

proc pcp_flow_set_lifetime*(f: ptr PcpFlowT; lifetime: uint32)
  {.importc: "pcp_flow_set_lifetime", header: PCP_HDR.}

proc pcp_flow_set_user_data*(f: ptr PcpFlowT; userdata: pointer)
  {.importc: "pcp_flow_set_user_data", header: PCP_HDR.}

proc pcp_flow_get_user_data*(f: ptr PcpFlowT): pointer
  {.importc: "pcp_flow_get_user_data", header: PCP_HDR.}

proc pcp_close_flow*(f: ptr PcpFlowT)
  {.importc: "pcp_close_flow", header: PCP_HDR.}

proc pcp_delete_flow*(f: ptr PcpFlowT)
  {.importc: "pcp_delete_flow", header: PCP_HDR.}

proc pcp_flow_get_info*(f: ptr PcpFlowT; info_count: ptr csize_t): ptr PcpFlowInfoT
  {.importc: "pcp_flow_get_info", header: PCP_HDR.}

proc pcp_eval_flow_state*(flow: ptr PcpFlowT; fstate: ptr PcpFstateE): cint
  {.importc: "pcp_eval_flow_state", header: PCP_HDR.}

proc pcp_wait*(flow: ptr PcpFlowT; timeout: cint; exit_on_partial_res: cint): PcpFstateE
  {.importc: "pcp_wait", header: PCP_HDR.}

proc pcp_set_loggerfn*(ext_log: pointer)
  {.importc: "pcp_set_loggerfn", header: PCP_HDR.}

###################
# custom wrappers #
###################

# We need inet_ntop to render in6_addr as a human-readable string.
# Emit a small C helper so the platform-specific include is handled in C,
# not in Nim (avoiding the windows/posix conditional for just this one call).
{.emit: """
#ifdef _WIN32
#  include <winsock2.h>
#  include <ws2tcpip.h>
#else
#  include <arpa/inet.h>
#endif
#include <string.h>

static void nim_pcp_in6_to_str(const struct in6_addr *addr, char *buf, int buflen) {
  if (!inet_ntop(AF_INET6, addr, buf, (socklen_t)buflen)) {
    buf[0] = '\0';
  }
}
""".}

proc nimPcpIn6ToStr(addr6: ptr In6Addr; buf: cstring; buflen: cint)
  {.importc: "nim_pcp_in6_to_str", nodecl.}

proc in6AddrToString(a: In6Addr): string =
  var buf = newString(64)  # INET6_ADDRSTRLEN = 46, 64 is safe
  var tmp = a
  nimPcpIn6ToStr(addr tmp, buf.cstring, 64)
  buf.setLen(len(buf.cstring))
  buf

# pcp_flow_get_info returns a malloc'd buffer that we must free.
# We declare free() here rather than pulling in os or system internals.
proc c_free(p: pointer) {.importc: "free", header: "<stdlib.h>".}

type
  PcpNatPmp* = ref object
    ## Handle for a PCP/NAT-PMP client session.
    ctx*: ptr PcpCtxT

  PcpNatPmpProtocol* = enum
    UDP = 17  ## IPPROTO_UDP
    TCP = 6   ## IPPROTO_TCP

  PcpPortMapping* = object
    ## Result of a successful port mapping request.
    externalPort*: uint16   ## Assigned external port (host byte order)
    externalHost*: string   ## External IP address (IPv6 notation)
    lifetime*: clong        ## Seconds until the mapping expires (recv_lifetime_end)

proc newPcpNatPmp*(): PcpNatPmp =
  ## Create a new (uninitialised) PCP/NAT-PMP client handle.
  new(result)

proc init*(self: PcpNatPmp): Result[bool, string] =
  ## Initialise the PCP client and start auto-discovery of PCP servers on the
  ## local network.  Must be called before any mapping operations.
  self.ctx = pcp_init(ENABLE_AUTODISCOVERY, nil)
  if self.ctx == nil:
    result.err("pcp_init returned NULL")
  else:
    result.ok(true)

proc close*(self: PcpNatPmp) =
  ## Shut down the PCP client, signalling removal of all active flows to the
  ## PCP server before freeing resources.
  if self.ctx != nil:
    pcp_terminate(self.ctx, 1)
    self.ctx = nil

proc `=deepCopy`(x: PcpNatPmp): PcpNatPmp =
  doAssert(false, "not implemented")

proc doMapping(self: PcpNatPmp,
               iport: uint16,
               protocol: PcpNatPmpProtocol,
               lifetime: uint32,
               timeoutMs: cint): Result[PcpPortMapping, string] =
  ## Internal helper: create a flow with the given lifetime and wait for a result.
  ## lifetime=0 sends a delete (revocation) request.

  # Build a sockaddr_in for the local source address (0.0.0.0:<iport>).
  # libpcpnatpmp will promote it to an IPv4-mapped IPv6 address internally.
  var src: Sockaddr_in
  when defined(windows):
    src.sin_family = winlean.AF_INET.uint16
  else:
    src.sin_family = posix.AF_INET.TSa_Family
  src.sin_port = htons(iport)
  # sin_addr is zero-initialised (INADDR_ANY)

  let flow = pcp_new_flow(
    self.ctx,
    cast[ptr SockAddr](addr src),
    nil,             # dst_addr: nil = no peer restriction (MAP opcode)
    nil,             # ext_addr: nil = let the server choose external port
    protocol.uint8,
    lifetime,
    nil              # userdata: not needed for synchronous wrapper
  )

  if flow == nil:
    result.err("pcp_new_flow returned NULL")
    return

  let state = pcp_wait(flow, timeoutMs, 1)

  if state == pcp_state_succeeded or state == pcp_state_partial_result:
    var infoCount: csize_t
    let infoPtr = pcp_flow_get_info(flow, addr infoCount)

    if infoPtr == nil or infoCount == 0:
      pcp_delete_flow(flow)
      result.err("pcp_flow_get_info returned no entries")
      return

    # infoPtr points to a malloc'd array; read the first entry then free it.
    let extPort = ntohs(infoPtr[].extPort)
    let extHost = in6AddrToString(infoPtr[].extIp)
    let mappingLifetime = infoPtr[].recvLifetimeEnd

    c_free(infoPtr)
    pcp_delete_flow(flow)

    result.ok(PcpPortMapping(
      externalPort: extPort,
      externalHost: extHost,
      lifetime: mappingLifetime
    ))

  elif state == pcp_state_processing:
    pcp_delete_flow(flow)
    result.err("pcp_wait timed out (no response from PCP server)")

  else:
    pcp_delete_flow(flow)
    result.err("pcp_wait failed with state: " & $state.int)

proc addPortMapping*(self: PcpNatPmp,
                     iport: uint16,
                     protocol: PcpNatPmpProtocol,
                     lifetime: uint32 = 3600,
                     timeoutMs: cint = 5000): Result[PcpPortMapping, string] =
  ## Request a port mapping via PCP (falling back to NAT-PMP automatically).
  ##
  ## `iport`     — local (internal) port to map.
  ## `protocol`  — TCP or UDP.
  ## `lifetime`  — requested lease in seconds (default: 1 hour).
  ## `timeoutMs` — server reply deadline in milliseconds (default: 5 s).
  ##
  ## Returns the assigned external port and address on success.
  return self.doMapping(iport, protocol, lifetime, timeoutMs)

proc deletePortMapping*(self: PcpNatPmp,
                        iport: uint16,
                        protocol: PcpNatPmpProtocol,
                        timeoutMs: cint = 5000): Result[bool, string] =
  ## Remove a previously created port mapping (sends lifetime=0 to the server).
  let r = self.doMapping(iport, protocol, 0, timeoutMs)
  if r.isOk:
    result.ok(true)
  else:
    result.err(r.error)
