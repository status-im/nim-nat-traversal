packageName   = "nat_traversal"
version       = "0.0.1"
author        = "Status Research & Development GmbH"
description   = "miniupnpc and libnatpmp wrapper"
license       = "Apache License 2.0 or MIT"
skipDirs      = @["examples"]

### Dependencies
requires "nim >= 0.19.0", "result"

proc compileStaticLibraries() =
  withDir "vendor/miniupnp/miniupnpc":
    exec("make libminiupnpc.a")
  withDir "vendor/libnatpmp":
    exec("make libnatpmp.a")

task buildBundledLibs, "build bundled libraries":
  compileStaticLibraries()

task installWithBundledLibs, "install with bundled libs":
  compileStaticLibraries()
  exec("nimble install -y")

