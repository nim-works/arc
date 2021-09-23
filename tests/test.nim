import balls

import arc

proc main =
  ## work around scope worries
  suite "testing atomic reference counter":

    block:
      ## we can read the rc of a ref
      var r: ref string
      new r
      r[] = "goats"
      check atomicRC(r) == 0, "should have no references"
      check r.isIsolated, "should be isolated"
      block:
        var v: ref string
        v = r
        check atomicRC(r) == 1, "should have a reference"
        check not r.isIsolated, "shouldn't be isolated"

        check atomicIncRef(r) == 1, "should have read 1"
        check atomicRC(r) == 2, "counter should read 2"

      check atomicRC(r) == 1, "should have a reference"
      check not r.isIsolated, "shouldn't be isolated"

      check atomicDecRef(r) == 1, "should have read 1"

      check atomicRC(r) == 0, "should have no references"
      check r.isIsolated, "should be isolated"

when isMainModule:
  main()
