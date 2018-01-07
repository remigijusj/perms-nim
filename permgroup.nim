import perm, nre

from random    import random, randomize
from sequtils  import mapIt, anyIt, allIt
from strutils  import join, splitLines, `%`

export perm

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
  for i in 0 .. <size:
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
    for p, i in list.multiply(gens):
      if p.isZero or p.isIdentity:
        continue
      yield (p, i, level)
      mult[i] = p
      if debug: echo i, ": ", printCycles(p)
    swap(list, mult)


# Decode an index from the given level, get a sequence of generator indices
# Using composeSeq on the result gives the perm which was produced with this index.
# k: number of generators
proc decodeIndex*(index, level, k: int): seq[int] =
  var val = index
  result = newSeq[int](level)
  for i in countdown(level-1, 0):
    result[i] = val mod k
    val = val div k


# Breadth-first search to determine the orbit of point alpha, and return transversal.
# For each point it gives an optional perm moving alpha to that point: coset representative.
proc orbitTransversal*[N: static[int]](gens: GroupGens[N], alpha: int): array[N, Option[Perm[N]]] =
  var old_level: seq[int]
  var new_level: seq[int] = @[alpha]

  result[alpha] = some(N.identity)

  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for x in old_level:
      for item in gens:
        let y = int(item.perm[x])
        if result[y].isNone:
          result[y] = some(result[x].get * item.perm)
          new_level.add(y)


# Breadth-first search to determine the orbit of alpha, and transversal.
# For each point it gives:
#   a tuple (belongs to orbit, index of generator, preimage under that perm)
proc schreierVector*[N: static[int]](gens: GroupGens[N], alpha: int): array[N, tuple[orb: bool, idx: int, pre: int]] =
  var old_level: seq[int]
  var new_level: seq[int] = @[alpha]

  result[alpha] = (orb: true, idx: -1, pre: -1)

  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for x in old_level:
      for i, item in gens:
        let y = int(item.perm[x])
        if not result[y].orb:
          result[y] = (orb: true, idx: i, pre: x)
          new_level.add(y)


# Yields stabilizator generators by Schreier lemma.
# TODO: along with transversal / schreier vector? -> orbitTransversalStabilizer
# TODO: deduplicate (keep dict)
iterator stabilizator*[N: static[int]](gens: GroupGens[N], alpha: int): Perm[N] =
  let reps = orbitTransversal(gens, alpha)
  for i, rep in reps:
    if rep.isSome:
      for item in gens:
        let rep1 = reps[item.perm[i]]
        let perm = rep.get * item.perm * rep1.get.inverse
        if not perm.isIdentity:
          yield perm


# Return true if the generated group is transitive (has single orbit)
proc isTransitive*[N: static[int]](gens: GroupGens[N]): bool =
  result = orbitTransversal(gens, 0).allIt(it.isSome)


# Make a random element of permutation group using the Product Replacement Algorithm,
# see p.27 in Seress' book. It is recommended to normalize generators before use.
proc randomPerm*[N: static[int]](gens: GroupGens[N], iterations: int): Perm[N] =
  if gens.len < 2:
    raise Exception.newException("must have at least two generators")

  var base = gens.perms
  var m, k: int
  for i in 0 .. <iterations:
    m = random(base.len)
    k = random(base.len - 1)
    if k >= m: k.inc # avoids same element
    base[m] = base[m] * base[k]    

  result = base[m]
