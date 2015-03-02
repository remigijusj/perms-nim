import perm, re, strutils


type BaseItem = tuple[name: string, perm: Perm, inverse: int]

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


proc size*(base: PermBase): int = base.len


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


# TODO: pruning by i,j and base
iterator multiply*(list: seq[Perm], base: PermBase): tuple[p: Perm, i: int] =
  let n = base.len
  for i, p in list:
    for j, it in base:
      yield (p * it.perm, i * n + j)


proc search*(base: PermBase; target, levels: int; max = 0; debug = false): tuple[p: Perm; i, size: int] =
  let k = base.size
  var list: seq[Perm] = @[identity()]
  var mult: seq[Perm]

  for level in 1 .. levels:
    mult = newSeq[Perm](list.len * k)
    for perm, i in list.multiply(base):
      if perm.orderToCycle(target, max) > -1:
        return (perm, i, level) # <<< mult.len
      mult[i] = perm
      if debug:
        echo i, " ", printCycles(perm)
    swap(list, mult)
    if debug:
      echo "---"

  return (identity(), -1, -1)


when isMainModule:
  let base = parseBase("A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)")
  let norm = base.normalize
  let (p, i, s) = norm.search(3, 8, 0, false)
  echo i, "/", s, " ", p.printCycles

  let x = norm.toSeq
  let r = compose(x[0], x[1], x[1])
  echo r.printCycles
