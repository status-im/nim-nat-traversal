mode = ScriptMode.Verbose

packageName   = "nat_traversal"
version       = "0.0.1"
author        = "Status Research & Development GmbH"
description   = "miniupnpc and libnatpmp wrapper"
license       = "Apache License 2.0 or MIT"
installDirs   = @["vendor"]

### Dependencies
requires "nim >= 0.19.0", "stew"

proc compileStaticLibraries() =
  var cc = getEnv("CC", "")
  if cc.len == 0:
    cc = "gcc"
    putEnv("CC", cc)

  withDir "vendor/miniupnp/miniupnpc":
    when defined(windows):
      exec("mingw32-make -f Makefile.mingw init libminiupnpc.a")
    else:
      exec("make libminiupnpc.a")
  withDir "vendor/libnatpmp":
    when defined(windows):
      # We really need to override CC on the Make command line, here, because of:
      # https://github.com/status-im/libnatpmp/blob/976d2c3b5e7022e7292f0170d0dba7ed492da216/Makefile#L51
      exec("mingw32-make CC=\"" & cc & "\" CFLAGS=\"-Wall -Os -DWIN32 -DNATPMP_STATICLIB -DENABLE_STRNATPMPERR -DNATPMP_MAX_RETRIES=4\" libnatpmp.a")
    else:
      exec("make CFLAGS=\"-Wall -Os -DENABLE_STRNATPMPERR -DNATPMP_MAX_RETRIES=4\" libnatpmp.a")

task buildBundledLibs, "build bundled libraries":
  compileStaticLibraries()

before install:
  compileStaticLibraries()

