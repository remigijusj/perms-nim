import perm, re, strutils

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


# TODO: in-place?
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


# TODO: pruning by i,j and base
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


proc search*(base: PermBase; levels: int; filter: proc(p: Perm): bool): tuple[p: Perm, s: seq[int]] =
  let k = base.len
  var list: seq[Perm] = @[identity()]
  var mult: seq[Perm]

  for level in 1 .. levels:
    mult = newSeq[Perm](list.len * k)
    if debug: echo "--- ", level
    for p, i in list.multiply(base):
      if p.isZero or p.isIdentity:
        continue
      if filter(p):
        return (p, decompose(i, level, k))
      mult[i] = p
      if debug: echo i, ": ", printCycles(p)
    swap(list, mult)

  return (identity(), @[])


proc searchCycle*(base: PermBase; target, levels: int; max = 0): tuple[p: Perm, s: seq[int]] =
  base.search(levels, proc(p: Perm): bool = p.orderToCycle(target, max) > -1)


when isMainModule:
  debug = true
  let base = parseBase("A: (1 2)(3 4)\nB: (1 3)(2 4)")
  discard base.searchCycle(4, 2)
