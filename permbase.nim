import perm, re, strutils


type BaseItem = tuple[name: string, perm: Perm]

type PermBase* = seq[BaseItem]


proc parseBase*(data: string): PermBase =
  result = newSeq[BaseItem]()
  for line in splitLines(data):
    if line =~ re"^(\w+):\s+(.+)":
      result.add((matches[0], parseCycles(matches[1])))


proc printBase*(base: PermBase): string =
  result = ""
  for i, item in base:
    if i > 0:
      result.add "\n"
    result.add "$#: $#" % [item.name, printCycles(item.perm)]


proc size*(base: PermBase): int = base.len


proc sign*(base: PermBase): int =
  for item in base:
    if item.perm.sign == -1:
      return -1

  return 1


# TODO: in-place?
proc normalize*(base: PermBase): PermBase =
  result = base
  for item in base:
    if not item.perm.isInvolution():
      result.add((name: item.name & "'", perm: item.perm.inverse))
