import algorithm, perm, re, strutils, tables

var debug = false

type BaseItem = tuple
  name: string
  perm: Perm
  inverse: int

type PermBase* = seq[BaseItem]


proc parseBase*(data: string): PermBase =
  result = newSeq[BaseItem]()
  for line in splitLines(data):
    if line =~ re"^(\w+):\s+(.+)":
      result.add((matches[0], parseCycles(matches[1]), -1))


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


proc toSeq*(base: PermBase): seq[Perm] =
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


proc searchCycle*(base: PermBase; target, levels: int; max = 0): tuple[p: Perm, s: seq[int]] =
  for p, i, level in base.multiSearch(levels):
    if p.orderToCycle(target, max) > -1:
      let s = decompose(i, level, base.len)
      return (p, s)

  return (identity(), @[])


iterator conjugate*(list: seq[Cycle], base: PermBase): tuple[c: Cycle; i, j: int] =
  for i, c in list:
    for j, it in base:
      yield (conjugate(c, it.perm), i, j)


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
  while i > 0:
    result.add(meta[i].j)
    i = meta[i].i
  result.add(i)
  reverse(result)


# TODO: WIP, use tables
proc coverCycles(base: PermBase; seed, target: seq[Cycle]): bool =
  for c, meta in base.conjuSearch(seed):
    let t = traceBack(meta)
    let m = meta[meta.high]
    if debug: echo(cnt, ": ", c, " <- ", m.i, ":", m.j, " <- ", t)


when isMainModule:
  debug = true
  let norm = parseBase("A: (1 2)(3 4)\nB: (1 3)(2 4)")
  discard norm.searchCycle(4, 2)
  echo "---------"
  let base = parseBase("A: (1 2 3 4)(5 6)\nB: (1 3 5)") # [0 1 2 3][4 5], [0 2 4]
  let seed = @[newCycle(@[1, 3])]
  let target = newSeq[Cycle]()
  discard base.coverCycles(seed, target)
