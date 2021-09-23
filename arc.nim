#[

Some types and constants copied from stdlib so we can mimic rc against the
standard ref header.

]#

when defined(gcOrc):
  const
    rcIncrement = 0b10000 # so that lowest 4 bits are not touched
    rcMask = 0b1111
    rcShift = 4           # shift by rcShift to get the reference counter
else:
  const
    rcIncrement = 0b1000 # so that lowest 3 bits are not touched
    rcMask = 0b111
    rcShift = 3          # shift by rcShift to get the reference counter

template shit(n: int): int = n shl rcShift
template unshit(n: int): int = n shr rcShift

type
  RefHeader = object
    rc: int
    when defined(gcOrc):
      rootIdx: int
    when defined(nimArcDebug) or defined(nimArcIds):
      refId: int

  Cell = ptr RefHeader

template head(p: ref): Cell =
  cast[Cell](cast[int](p) -% sizeof(RefHeader))

template rcPtr(p: ref): ptr int = addr head(p)[].rc

proc atomicRC*(p: ref): int =
  ## returns the current rc
  atomicLoad(rcPtr(p), addr result, ATOMIC_SEQ_CST)
  result = unshit result

proc atomicRC*(p: ref; n: int) =
  ## sets the rc to the provided value
  let old = atomicFetchAnd(rcPtr(p), rcMask, ATOMIC_SEQ_CST)
  let n = (shit n) and old
  atomicStore(rcPtr(p), unsafeAddr n, ATOMIC_SEQ_CST)

proc atomicIncRef*(p: ref): int =
  ## returns the old value
  unshit atomicFetchAdd(rcPtr(p), rcIncrement, ATOMIC_SEQ_CST)

proc atomicDecRef*(p: ref): int =
  ## returns the old value
  unshit atomicFetchSub(rcPtr(p), rcIncrement, ATOMIC_SEQ_CST)

template isIsolated*(p: ref): bool =
  ## true if the ref is the sole owner
  atomicRC(p) == 0
