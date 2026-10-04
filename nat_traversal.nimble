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

let nimc = getEnv("NIMC", "nim") # Which nim compiler to use
let lang = getEnv("NIMLANG", "c") # Which backend (c/cpp/js)
let flags = getEnv("NIMFLAGS", "") # Extra flags for the compiler
let verbose = getEnv("V", "") notin ["", "0"]
let platform = getEnv("PLATFORM", "")
let testArguments = [
  "-d:debug",
  "-d:release",
]

from std/os import quoteShell

let cfg =
  " --styleCheck:usages --styleCheck:error" &
  (if verbose: "" else: " --verbosity:0") &
  " --skipParentCfg --skipUserCfg --outdir:build -f " &
  quoteShell("--nimcache:build/nimcache/$projectName")

proc build(args, path: string) =
  exec nimc & " " & lang & " " & cfg & " " & flags & " " & args & " " & path

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

task buildBundledLibs, "build bundled libraries":
  compileStaticLibraries()

before install:
  compileStaticLibraries()

task test, "Run all tests":
  compileStaticLibraries()
  for args in testArguments:
    for example in ["examples/miniupnpc_test", "examples/natpmp_test"]:
      build args & " --mm:refc", example
      build args & " --mm:orc", example

task test_asan, "Run all tests with ASAN":
  if platform != "x86":
    try:
      exec "echo '#if __clang_major__ < 20\n#error\n#endif' | clang -E - >/dev/null"
    except OSError:
      return

    compileStaticLibraries()
    let asanArgs =
      " --mm:orc -d:useMalloc --cc:clang --debugger:native" &
      " --passC:-fsanitize=address,undefined" &
      " --passL:-fsanitize=address,undefined" &
      " --passC:-fno-sanitize-recover=undefined" &
      " --passC:-fno-sanitize-merge" &
      " --passC:-fno-omit-frame-pointer"
    for args in testArguments:
      for example in ["examples/miniupnpc_test", "examples/natpmp_test"]:
        build args & asanArgs, example
