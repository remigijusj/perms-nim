import perm, nre
from algorithm import reverse
from math      import ceil, ln
from sequtils  import mapIt, anyIt
from strutils  import join, splitLines, `%`

var debug* {.global.} = false

type BaseItem[N: static[int]] = tuple
  name: string
  perm: Perm[N]
  inverse: int

type PermBase*[N: static[int]] = seq[BaseItem[N]]

type FactorizeError* = object of Exception


proc parseBase*(N: static[int], data: string): PermBase[N] =
  result = newSeq[BaseItem[N]]()
  for line in splitLines(data):
    let m = line.match(re"^(\w+):\s+(.+)")
    if m.isSome:
      result.add((m.get.captures[0], N.parsePerm(m.get.captures[1]), -1))


proc printBase*(base: PermBase): string =
  result = ""
  for i, item in base:
    if i > 0:
      result.add "\n"
    result.add "$#: $#" % [item.name, printCycles(item.perm)]


proc randomBase*(N: static[int], size: int; dist = true): PermBase[N] =
  result = newSeq[BaseItem[N]](size)
  for i in 0 .. <size:
    let name = $('A'.succ(i))
    var perm = N.randomPerm
    if dist:
      while anyIt(result[0..i-1], it.perm == perm):
        perm = N.randomPerm
    result[i] = (name, perm, -1)


proc permByName*[N: static[int]](base: PermBase[N], name: string): Option[Perm[N]] =
  for item in base:
    if item.name == name:
      return some(item.perm)


proc perms*[N: static[int]](base: PermBase[N]): seq[Perm[N]] =
  result = base.mapIt(it.perm)


proc sign*(base: PermBase): int =
  for item in base:
    if item.perm.sign == -1:
      return -1
  return 1


proc normalize*(base: PermBase): PermBase =
  result = base
  for i, item in base:
    if item.perm.isInvolution:
      result[i].inverse = i
    else:
      result[i].inverse = result.len
      result.add((name: item.name & "'", perm: item.perm.inverse, inverse: i))


proc isTransitive*[N: static[int]](base: PermBase[N]): bool =
  var members: array[N, int]

  var old_level: seq[int]
  var new_level: seq[int] = @[0]
  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for i, x in old_level:
      for item in base:
        let y = int(item.perm[x])
        if members[y] == 0:
          members[y] = 1
          new_level.add(y)

  result = not anyIt(members, it == 0)


proc composeSeq*[N: static[int]](base: PermBase[N], list: seq[int]): Perm[N] =
  result = N.identity
  for i in list:
    result = result * base[i].perm


# warning: assumes list does not start with -1
proc grouped(list: seq[int]): seq[tuple[n: int, s: string]] =
  result = @[]
  var prev = -1
  var count = 0
  for this in list:
    if this == prev:
      count.inc
    else:
      if count > 0:
        let suffix = if count == 1: "" else: $count
        result.add((n: prev, s: suffix))
      count = 1
      prev = this
  let suffix = if count == 1: "" else: $count
  result.add((n: prev, s: suffix))


proc factorNames*[N: static[int]](base: PermBase[N], list: seq[int], sep = "", concise = false): string =
  if concise:
    result = grouped(list).mapIt(base[it.n].name & it.s).join(sep)
  else:
    result = list.mapIt(base[it].name).join(sep)


proc decompose(i, level, k: int): seq[int] =
  var val = i
  result = newSeq[int](level)
  for i in countdown(level-1, 0):
    result[i] = val mod k
    val = val div k


iterator multiply*[N: static[int]](list: seq[Perm[N]], base: PermBase[N]): tuple[p: Perm[N], k: int] =
  let n = base.len
  var k: int
  for i, p in list:
    for j, it in base:
      k = i * n + j
      if p.isZero:
        yield (p, k)
      else:
        yield (p * it.perm, k)


iterator multiSearch*[N: static[int]](base: PermBase[N], levels: int): tuple[p: Perm[N]; i, level: int] =
  let k = base.len
  var list: seq[Perm[N]] = @[N.identity]

  for level in 1 .. levels:
    if debug: echo "--- ", level
    var mult = newSeq[Perm[N]](list.len * k)
    for p, i in list.multiply(base):
      if p.isZero or p.isIdentity:
        continue
      yield (p, i, level)
      mult[i] = p
      if debug: echo i, ": ", printCycles(p)
    swap(list, mult)


proc searchCycle*[N: static[int]](base: PermBase[N]; target, levels: int; max = 0; full = false): tuple[c: seq[Cycle[N]], s: seq[seq[int]]] =
  result.c = @[]
  result.s = @[]
  for p, i, level in base.multiSearch(levels):
    let o = p.orderToCycle(target, max)
    if o > -1:
      let c = p.power(o).cycles[0]
      if not result.c.contains(c):
        var s = decompose(i, level, base.len)
        s.add(o) # push residual order on top
        result.c.add(c)
        result.s.add(s)
        if not full:
          return


iterator conjugate*(list: seq[Cycle], base: PermBase): tuple[c: Cycle; i, j: int] =
  for i, c in list:
    for j, it in base:
      yield (conjugate(c, it.perm), i, j)


# ensures unique yielded cycles
iterator conjuSearch(base: PermBase, seed: seq[Cycle]): tuple[c: Cycle, meta: seq[tuple[i, j: int]]] =
  var list = newSeq[Cycle]()
  var meta = newSeq[tuple[i, j: int]]()
  var prev, next: int

  for i, c in seed:
    let m = (-1, -1)
    list.add(c)
    meta.add(m)
    yield (c, meta)

  while true:
    if prev == list.len:
      break
    next = list.len

    for c, i, j in list[prev .. list.high].conjugate(base):
      if list.contains(c):
        continue
      let m = (prev+i, j)
      list.add(c)
      meta.add(m)
      yield (c, meta)

    prev = next


proc traceBack(meta: seq[tuple[i, j: int]]): seq[int] =
  result = newSeq[int]()
  var i = meta.high
  while meta[i].i >= 0:
    result.add(meta[i].j)
    i = meta[i].i
  result.add(i)
  reverse(result)


proc coverCycles*(base: PermBase; seed, target: seq[Cycle]): seq[seq[int]] =
  result = newSeq[seq[int]](target.len)
  var cnt = 0
  for c, meta in base.conjuSearch(seed):
    if debug: echo(c, " <- ", meta[meta.high].i, ":", meta[meta.high].j)
    let i = target.find(c)
    if i >= 0:
      result[i] = meta.traceBack
      cnt.inc
      if cnt >= target.len:
        return

  if cnt < target.len:
    raise FactorizeError.newException("failed to cover all targets")


proc nextPowerOver(k, size: int): int = ceil(ln(size.float) / ln(k.float)).int


proc calcFactors(base: PermBase; meta, covers: seq[seq[int]]): seq[int] =
  result = newSeq[int]()
  for cov in covers:
    for k in countdown(cov.high, 1):
      result.add(base[cov[k]].inverse)

    let root = meta[cov[0]]
    let times = root[root.high]
    for i in 1 .. times:
      for j in 0 .. <root.high:
        result.add(root[j])

    for k in countup(1, cov.high):
      result.add(cov[k])


proc factorize*[N: static[int]](base: PermBase[N], target: Perm[N], full = false, minlevels = 0): seq[int] =
  # - stage 0
  let sign = base.sign
  let length = (5 + sign) div 2 # 2 or 3
  let levels = max(minlevels, nextPowerOver(base.len, N*N))
  # - stage 1
  let (seed, meta) = base.searchCycle(length, levels, N, full)
  if debug: echo("SEED: ", seed, "\nMETA: ", meta)
  if seed.len == 0:
    raise FactorizeError.newException("failed to find short cycle")
  # - stage 2
  let cycles = target.splitCycles(length)
  let covers = base.coverCycles(seed, cycles)
  # - finalize
  result = calcFactors(base, meta, covers)
