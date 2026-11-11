import perm, nre, sets

from random    import rand, randomize
from sequtils  import mapIt, anyIt, allIt
from strutils  import join, splitLines, `%`

export perm

## Permutation groups given by generators. Data structures and basic algorithms.

randomize()

var debug* {.global.} = false

type Generator*[N: static[int]] = tuple
  name: string
  perm: Perm[N]
  inverse: int

type GroupGens*[N: static[int]] = seq[Generator[N]]


# Parse generators with names. Recognizes the format produced by printGens.
proc parseGens*(N: static[int], data: string): GroupGens[N] =
  result = newSeq[Generator[N]]()
  for line in data.splitLines:
    let m = line.match(re"^(\w+):\s+(.+)")
    if m.isSome:
      result.add((m.get.captures[0], N.parsePerm(m.get.captures[1]), -1))


# Print generators in cycle notation, with names. One per line.
proc printGens*(gens: GroupGens): string =
  result = ""
  for i, item in gens:
    if i > 0:
      result.add "\n"
    result.add "$#: $#" % [item.name, printCycles(item.perm)]


# Generate random generating set of desired size. Possibly enforce distinct elements.
proc randomGens*(N: static[int], size: int; dist = true): GroupGens[N] =
  result = newSeq[Generator[N]](size)
  for i in 0 ..< size:
    let name = $('A'.succ(i))
    var perm = N.randomPerm
    if dist:
      while result[0..i-1].anyIt(it.perm == perm):
        perm = N.randomPerm
    result[i] = (name, perm, -1)


# Find generator by name. Return None if not found.
proc permByName*[N: static[int]](gens: GroupGens[N], name: string): Option[Perm[N]] =
  for item in gens:
    if item.name == name:
      return some(item.perm)


# Return sequence of plain perms of generating set.
proc perms*[N: static[int]](gens: GroupGens[N]): seq[Perm[N]] =
  result = gens.mapIt(it.perm)


# "Normalize" generating set by adding inverses (except for involutions).
# Store links to the inverse for each element. Inverses are named with ' sign (A -> A').
proc normalize*(gens: GroupGens): GroupGens =
  result = gens
  for i, item in gens:
    if item.perm.isInvolution:
      result[i].inverse = i
    else:
      result[i].inverse = result.len
      result.add((name: item.name & "'", perm: item.perm.inverse, inverse: i))


proc isNormalized*(gens: GroupGens): bool =
  ## Validate permutations and the inverse links used by word algorithms.
  for item in gens:
    if not item.perm.isValid:
      return false
  for item in gens:
    if item.inverse < 0 or item.inverse >= gens.len:
      return false
    if not (item.perm * gens[item.inverse].perm).isIdentity:
      return false
  return true


# Compose a sequence of generators given by indices
# TODO: support negative numbers meaning inverse generators
proc composeSeq*[N: static[int]](gens: GroupGens[N], list: seq[int]): Perm[N] =
  result = N.identity
  for i in list:
    result = result * gens[i].perm


# Helper to group indices for `factorNames` concise format.
# warning: assumes list does not start with -1
proc grouped(list: seq[int]): seq[tuple[n: int, s: string]] =
  result = @[]
  if list.len == 0:
    return
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


# Produce human-readable format of a factorization from a sequence of generator indices.
# Example:
#   ABAAC (not concise), ABA2C (concise)
proc factorNames*[N: static[int]](gens: GroupGens[N], list: seq[int], sep = "", concise = false): string =
  if concise:
    result = grouped(list).mapIt(gens[it.n].name & it.s).join(sep)
  else:
    result = list.mapIt(gens[it].name).join(sep)


# Make a random element of permutation group using the Product Replacement Algorithm,
# see p.27 in Seress' book. It is recommended to normalize generators before use.
proc randomPerm*[N: static[int]](gens: GroupGens[N], iterations: int): Perm[N] =
  if gens.len < 2:
    raise Exception.newException("must have at least two generators")

  var base = gens.perms
  var m, k: int
  for i in 0 ..< iterations:
    m = rand(base.len - 1)
    k = rand(base.len - 2)
    if k >= m: k.inc # avoids same element
    base[m] = base[m] * base[k]    

  result = base[m]


# Multiply the given list of perms with each of the generators.
# Produce both a perm and index useful for reconstructing it back from the generating set.
# Tolerate fake (zero) perms.
iterator multiply*[N: static[int]](list: seq[Perm[N]], gens: GroupGens[N]): tuple[p: Perm[N], k: int] =
  let n = gens.len
  var k: int
  for i, p in list:
    for j, it in gens:
      k = i * n + j
      if p.isZero:
        yield (p, k)
      else:
        yield (p * it.perm, k)


# Conjugate the given list of perms with each of the generators.
# Produce a perm, index of original perm  in the list, index of conjugating perm in the generating set.
# Similar to `multiply`.
iterator conjugate*(list: seq[Cycle], gens: GroupGens): tuple[c: Cycle; i, j: int] =
  for i, c in list:
    for j, it in gens:
      yield (conjugate(c, it.perm), i, j)


# Perform Breadth-First Search by composing generators up to given # of levels.
# Produce: the perm, it's index at the current level, level number.
iterator multiSearch*[N: static[int]](gens: GroupGens[N], levels: int): tuple[p: Perm[N]; i, level: int] =
  let k = gens.len
  var list: seq[Perm[N]] = @[N.identity]

  let max_level = if levels >= 0: levels else: int.high

  for level in 1 .. max_level:
    if debug: echo "--- ", level
    var mult = newSeq[Perm[N]](list.len * k)
    var active = false
    for p, i in list.multiply(gens):
      if p.isZero or p.isIdentity:
        continue
      yield (p, i, level)
      mult[i] = p
      active = true
      if debug: echo i, ": ", printCycles(p)
    swap(list, mult)
    if not active:
      break


# Decode an index from the given level, get a sequence of generator indices
# Using composeSeq on the result gives the perm which was produced with this index.
# k: number of generators
proc decodeIndex*(index, level, k: int): seq[int] =
  var val = index
  result = newSeq[int](level)
  for i in countdown(level-1, 0):
    result[i] = val mod k
    val = val div k


iterator shortWords*[N: static[int]](gens: GroupGens[N]; maxWords: int): tuple[p: Perm[N], word: seq[int]] =
  ## Breadth-first traversal of distinct elements. Each yielded word is shortest
  ## in this generator list; include inverses in the list for the symmetric metric.
  ## At most maxWords nonidentity elements are stored/yielded. Finite groups exhaust.
  var seen = initHashSet[Perm[N]]()
  var queue: seq[tuple[p: Perm[N], word: seq[int]]] = @[(N.identity, newSeq[int]())]
  seen.incl(N.identity)
  var head = 0
  var count = 0
  while head < queue.len and count < maxWords:
    let parent = queue[head]
    inc head
    for i, gen in gens:
      let p = parent.p * gen.perm
      if p notin seen:
        seen.incl(p)
        let word = parent.word & @[i]
        queue.add((p, word))
        inc count
        yield (p, word)
        if count >= maxWords: break
