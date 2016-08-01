import algorithm, math, perm, nre, strutils

var debug = isMainModule

type BaseItem = tuple
  name: string
  perm: Perm
  inverse: int

type PermBase* = seq[BaseItem]


proc parseBase*(data: string): PermBase =
  result = newSeq[BaseItem]()
  for line in splitLines(data):
    let m = line.match(re"^(\w+):\s+(.+)")
    result.add((m.get.captures[0], parsePerm(m.get.captures[1]), -1))


proc printBase*(base: PermBase): string =
  result = ""
  for i, item in base:
    if i > 0:
      result.add "\n"
    result.add "$#: $#" % [item.name, printCycles(item.perm)]


proc randomBase*(size: int): PermBase =
  result = newSeq[BaseItem](size)
  for i in 0 .. <size:
    let name = $('A'.succ(i))
    result[i] = (name, randomPerm(), -1)


proc perms*(base: PermBase): seq[Perm] =
  result = newSeq[Perm](base.len)
  for i, item in base:
    result[i] = item.perm


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


proc composeSeq*(base: PermBase, list: seq[int]): Perm =
  result = identity()
  for i in list:
    result = result * base[i].perm


proc factorNames*(base: PermBase, list: seq[int], sep = ""): string =
  result = ""
  for i, it in list:
    if i > 0:
      result.add(sep)
    result.add(base[it].name)


proc decompose(i, level, k: int): seq[int] =
  var val = i
  result = newSeq[int](level)
  for i in countdown(level-1, 0):
    result[i] = val mod k
    val = val div k


iterator multiply*(list: seq[Perm], base: PermBase): tuple[p: Perm, k: int] =
  let n = base.len
  var k: int
  for i, p in list:
    for j, it in base:
      k = i * n + j
      if p.isZero:
        yield (p, k)
      else:
        yield (p * it.perm, k)


iterator multiSearch(base: PermBase, levels: int): tuple[p: Perm; i, level: int] =
  let k = base.len
  var list: seq[Perm] = @[identity()]
  var mult: seq[Perm]

  for level in 1 .. levels:
    if debug: echo "--- ", level
    mult = newSeq[Perm](list.len * k)
    for p, i in list.multiply(base):
      if p.isZero or p.isIdentity:
        continue
      yield (p, i, level)
      mult[i] = p
      if debug: echo i, ": ", printCycles(p)
    swap(list, mult)


proc searchCycle*(base: PermBase; target, levels: int; max = 0; full = false): tuple[c: seq[Cycle], s: seq[seq[int]]] =
  result.c = newSeq[Cycle]()
  result.s = newSeq[seq[int]]()
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
    raise PermError.newException("failed to cover all targets")


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


proc factorize*(base: PermBase, target: Perm, full = false): seq[int] =
  let sign = base.sign
  # stage 1
  let length = (5 + sign) div 2 # 2 or 3
  let levels = nextPowerOver(base.len, N*N)
  let (seed, meta) = base.searchCycle(length, levels, N, full)
  # stage 2
  let cycles = target.splitCycles(length)
  let covers = base.coverCycles(seed, cycles)
  # finalize
  result = calcFactors(base, meta, covers)


when isMainModule:
  # C2 x C2
  let invo = parseBase("A: (1 2)(3 4)\nB: (1 3)(2 4)")
  discard invo.searchCycle(4, 2)
  echo "---------"
  # (C3 x C3) : C4
  let base = parseBase("A: (1 2 3 4)(5 6)\nB: (1 3 5)") # [0 1 2 3][4 5], [0 2 4]
  let seed = @[newCycle(@[1, 3])]
  let target = @[newCycle(@[0, 4]), newCycle(@[1, 5])]
  discard base.coverCycles(seed, target)
