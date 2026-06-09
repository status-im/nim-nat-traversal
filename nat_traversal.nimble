mode = ScriptMode.Verbose

packageName   = "nat_traversal"
version       = "0.0.1"
author        = "Status Research & Development GmbH"
description   = "miniupnpc and libnatpmp wrapper"
license       = "Apache License 2.0 or MIT"
installDirs   = @["vendor"]

### Dependencies
requires "nim >= 1.6.0",
         "results"

proc compileStaticLibraries() =
  var cc = getEnv("CC", "")
  if cc.len == 0:
    cc = "gcc"
    putEnv("CC", cc)

  withDir "vendor/miniupnp/miniupnpc":
    when defined(windows):
      exec("mingw32-make CFLAGS=\"-Os -fPIC\" -f Makefile.mingw libminiupnpc.a")
    else:
      exec("make CFLAGS=\"-Os -fPIC\" build/libminiupnpc.a")
  withDir "vendor/libnatpmp-upstream":
    when defined(windows):
      # We really need to override CC on the Make command line, here, because of:
      # https://github.com/miniupnp/libnatpmp/blob/4536032ae32268a45c073a4d5e91bbab4534773a/Makefile#L51
      exec("mingw32-make OS=mingw CC=\"" & cc & "\" CFLAGS=\"-Wall -Os -fPIC -DWIN32 -DNATPMP_STATICLIB -DENABLE_STRNATPMPERR -DNATPMP_MAX_RETRIES=4\" libnatpmp.a")
    else:
      exec("make CFLAGS=\"-Wall -Os -fPIC -DENABLE_STRNATPMPERR -DNATPMP_MAX_RETRIES=4\" libnatpmp.a")

  withDir "vendor/libpcpnatpmp":
    when defined(windows):
      # _WIN32_WINNT=0x0600 (Vista+) is required: the library uses socket
      # ancillary-data APIs (cmsghdr, CMSG_FIRSTHDR, GetIpForwardTable2 ...)
      # that are only available from Vista onwards.
      exec("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -G \"MinGW Makefiles\"" &
           " -DCMAKE_C_FLAGS=\"-D_WIN32_WINNT=0x0600\"")
      exec("cmake --build build --target pcpnatpmp -- -j2")
    else:
      exec("cmake -S . -B build -DCMAKE_BUILD_TYPE=Release")
      exec("cmake --build build --target pcpnatpmp -- -j2")

task buildBundledLibs, "build bundled libraries":
  compileStaticLibraries()

before install:
  compileStaticLibraries()
