import perm, nre
from algorithm import reverse
from math      import ceil, ln
from sequtils  import mapIt, anyIt
from strutils  import join, splitLines, `%`

var debug* {.global.} = false

type BaseItem = tuple
  name: string
  perm: Perm
  inverse: int

type PermBase* = tuple
  deg: int
  list: seq[BaseItem]

type FactorizeError* = object of Exception


proc parseBase*(N: int, data: string): PermBase =
  result.deg = N
  result.list = newSeq[BaseItem]()
  for line in splitLines(data):
    let m = line.match(re"^(\w+):\s+(.+)")
    if m.isSome:
      result.list.add((m.get.captures[0], N.parsePerm(m.get.captures[1]), -1))


proc printBase*(base: PermBase): string =
  result = ""
  for i, item in base.list:
    if i > 0:
      result.add "\n"
    result.add "$#: $#" % [item.name, printCycles(item.perm)]


proc randomBase*(N: int, size: int; dist = true): PermBase =
  result.deg = N
  result.list = newSeq[BaseItem](size)
  for i in 0 .. <size:
    let name = $('A'.succ(i))
    var perm = N.randomPerm
    if dist:
      while anyIt(result.list[0..i-1], it.perm == perm):
        perm = N.randomPerm
    result.list[i] = (name, perm, -1)


proc permByName*(base: PermBase, name: string): Option[Perm] =
  for item in base.list:
    if item.name == name:
      return some(item.perm)


proc perms*(base: PermBase): seq[Perm] =
  result = base.list.mapIt(it.perm)


proc sign*(base: PermBase): int =
  for item in base.list:
    if item.perm.sign == -1:
      return -1
  return 1


proc normalize*(base: PermBase): PermBase =
  result = base
  for i, item in base.list:
    if item.perm.isInvolution:
      result.list[i].inverse = i
    else:
      result.list[i].inverse = result.list.len
      result.list.add((name: item.name & "'", perm: item.perm.inverse, inverse: i))


proc isTransitive*(base: PermBase): bool =
  let N = base.deg
  var members = newSeq[int](N)

  var old_level: seq[int]
  var new_level: seq[int] = @[0]
  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for i, x in old_level:
      for item in base.list:
        let y = int(item.perm[x])
        if members[y] == 0:
          members[y] = 1
          new_level.add(y)

  result = not anyIt(members, it == 0)


# TODO: support negatives by meaning inverse of base item
proc composeSeq*(base: PermBase, list: seq[int]): Perm =
  let N = base.deg
  result = N.identity
  for i in list:
    result = result * base.list[i].perm


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


proc factorNames*(base: PermBase, list: seq[int], sep = "", concise = false): string =
  if concise:
    result = grouped(list).mapIt(base.list[it.n].name & it.s).join(sep)
  else:
    result = list.mapIt(base.list[it].name).join(sep)


proc decompose(i, level, k: int): seq[int] =
  var val = i
  result = newSeq[int](level)
  for i in countdown(level-1, 0):
    result[i] = val mod k
    val = val div k


iterator multiply*(list: seq[Perm], base: PermBase): tuple[p: Perm, k: int] =
  let n = base.list.len
  var k: int
  for i, p in list:
    for j, it in base.list:
      k = i * n + j
      if p.isZero:
        yield (p, k)
      else:
        yield (p * it.perm, k)


iterator multiSearch*(base: PermBase, levels: int): tuple[p: Perm; i, level: int] =
  let k = base.list.len
  let N = base.deg
  var list: seq[Perm] = @[N.identity]

  for level in 1 .. levels:
    if debug: echo "--- ", level
    var mult = newSeq[Perm](list.len * k)
    for p, i in list.multiply(base):
      if p.isZero or p.isIdentity:
        continue
      yield (p, i, level)
      mult[i] = p
      if debug: echo i, ": ", printCycles(p)
    swap(list, mult)


proc searchCycle*(base: PermBase; target, levels: int; max = 0; full = false): tuple[c: seq[Cycle], s: seq[seq[int]]] =
  result.c = @[]
  result.s = @[]
  for p, i, level in base.multiSearch(levels):
    let o = p.orderToCycle(target, max)
    if o > -1:
      let c = p.power(o).cycles[0]
      if not result.c.contains(c):
        var s = decompose(i, level, base.list.len)
        s.add(o) # push residual order on top
        result.c.add(c)
        result.s.add(s)
        if not full:
          return


iterator conjugate*(list: seq[Cycle], base: PermBase): tuple[c: Cycle; i, j: int] =
  for i, c in list:
    for j, it in base.list:
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
      result.add(base.list[cov[k]].inverse)

    let root = meta[cov[0]]
    let times = root[root.high]
    for i in 1 .. times:
      for j in 0 .. <root.high:
        result.add(root[j])

    for k in countup(1, cov.high):
      result.add(cov[k])


proc factorize*(base: PermBase, target: Perm, full = false, minlevels = 0): seq[int] =
  let N = base.deg
  # - stage 0
  let sign = base.sign
  let length = (5 + sign) div 2 # 2 or 3
  let levels = max(minlevels, nextPowerOver(base.list.len, N*N))
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


# breadth-first search to determine the orbit of alpha, and return transversal
# for each point it gives an optional perm moving alpha to that point
proc orbitTransversal*(base: PermBase, alpha: int): seq[Option[Perm]] =
  var old_level: seq[int]
  var new_level: seq[int] = @[alpha]

  let N = base.deg
  result = newSeq[Option[Perm]](N)
  result[alpha] = some(N.identity)

  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for x in old_level:
      for item in base.list:
        let y = int(item.perm[x])
        if result[y].isNone:
          result[y] = some(result[x].get * item.perm)
          new_level.add(y)


# breadth-first search to determine the orbit of alpha, and transversal
#   for each point it gives:
#   a tuple (belongs to orbit, index of base element, preimage under that perm)
proc schreierVector*(base: PermBase, alpha: int): seq[tuple[orb: bool, idx: int, pre: int]] =
  var old_level: seq[int]
  var new_level: seq[int] = @[alpha]

  let N = base.deg
  result = newSeq[tuple[orb: bool, idx: int, pre: int]](N)
  result[alpha] = (orb: true, idx: -1, pre: -1)

  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for x in old_level:
      for i, item in base.list:
        let y = int(item.perm[x])
        if not result[y].orb:
          result[y] = (orb: true, idx: i, pre: x)
          new_level.add(y)


# yields stabilizator generators by Schreier lemma
# TODO: along with transversal / schreier vector? -> orbitTransversalStabilizer
# TODO: deduplicate (keep dict)
iterator stabilizator*(base: PermBase, alpha: int): Perm =
  let cosetReps = orbitTransversal(base, alpha)
  for i, rep in cosetReps:
    if rep.isSome:
      for item in base.list:
        let rep1 = cosetReps[int(item.perm[i])]
        let perm = rep.get * item.perm * rep1.get.inverse
        if not perm.isIdentity:
          yield perm
