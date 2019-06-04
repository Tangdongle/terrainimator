# Package

version       = "0.1.0"
author        = "ryancotter"
description   = "Procedural terrain generator"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["terrain"]


# Dependencies

requires "nim >= 0.19.6"

task run, "Execute the binary":
  exec("nim c -r --out:terrain src/terrain.nim")
