import perm, nre
from algorithm import reverse
from math      import ceil, ln
from sequtils  import mapIt, anyIt
from strutils  import join, splitLines, `%`

export perm

var debug* {.global.} = false

type Generator*[N: static[int]] = tuple
  name: string
  perm: Perm[N]
  inverse: int

type GroupGens*[N: static[int]] = seq[Generator[N]]

type FactorizeError* = object of Exception


# Parse generators with names. Recognizes the format produced by printGens.
proc parseGens*(N: static[int], data: string): GroupGens[N] =
  result = newSeq[Generator[N]]()
  for line in splitLines(data):
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
      while anyIt(result[0..i-1], it.perm == perm):
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


# Calc the sign of the generating set: -1 if any element is odd, 1 otherwise.
proc sign*(gens: GroupGens): int =
  for item in gens:
    if item.perm.sign == -1:
      return -1
  return 1


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


# Return true if the generated group is transitive (has single orbit)
proc isTransitive*[N: static[int]](gens: GroupGens[N]): bool =
  var members: array[N, int]

  var old_level: seq[int]
  var new_level: seq[int] = @[0]
  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for i, x in old_level:
      for item in gens:
        let y = int(item.perm[x])
        if members[y] == 0:
          members[y] = 1
          new_level.add(y)

  result = not anyIt(members, it == 0)


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


# Decode an index from the given level, get a sequence of generator indices
# Using composeSeq on the result gives the perm which was produced with this index.
# k: number of generators
proc decodeIndex*(index, level, k: int): seq[int] =
  var val = index
  result = newSeq[int](level)
  for i in countdown(level-1, 0):
    result[i] = val mod k
    val = val div k


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
      if debug: echo i, ": " #, printCycles(p) # BUG: Error: ordinal type expected
    swap(list, mult)


# Perform `multiSearch` until a cycle of desired length is found, or upto # of levels (full search).
# Produce 2 lists:
# c: cycles found
# s: sequences of generator indices leading to the corresponding cycle.
#    Residual order is pushed as the last element of the list.
proc searchCycle*[N: static[int]](gens: GroupGens[N]; length, levels: int; max = 0; full = false): tuple[c: seq[Cycle[N]], s: seq[seq[int]]] =
  result.c = @[]
  result.s = @[]
  for p, i, level in gens.multiSearch(levels):
    let o = p.orderToCycle(length, max)
    if o > -1:
      let c = p.power(o).cycles[0]
      if not result.c.contains(c):
        var s = decodeIndex(i, level, gens.len)
        s.add(o) # push residual order on top
        result.c.add(c)
        result.s.add(s)
        if not full:
          return


# Conjugate the given list of perms with each of the generators.
# Produce a perm, index of original perm  in the list, index of conjugating perm in the generating set.
# Similar to `multiply`.
iterator conjugate*(list: seq[Cycle], gens: GroupGens): tuple[c: Cycle; i, j: int] =
  for i, c in list:
    for j, it in gens:
      yield (conjugate(c, it.perm), i, j)


# Perform Breadth-First Search by conjugating seed (list of cycles) with the generators.
# Ensures unique yielded cycles.
iterator conjuSearch(gens: GroupGens, seed: seq[Cycle]): tuple[c: Cycle, meta: seq[tuple[i, j: int]]] =
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

    for c, i, j in list[prev .. list.high].conjugate(gens):
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


# Perform search by conjugation from the seed trying to cover all given cycles (target).
proc coverCycles*(gens: GroupGens; seed, target: seq[Cycle]): seq[seq[int]] =
  result = newSeq[seq[int]](target.len)
  var cnt = 0
  for c, meta in gens.conjuSearch(seed):
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


proc calcFactors(gens: GroupGens; meta, covers: seq[seq[int]]): seq[int] =
  result = newSeq[int]()
  for cov in covers:
    for k in countdown(cov.high, 1):
      result.add(gens[cov[k]].inverse)

    let root = meta[cov[0]]
    let times = root[root.high]
    for i in 1 .. times:
      for j in 0 .. <root.high:
        result.add(root[j])

    for k in countup(1, cov.high):
      result.add(cov[k])


# Factorize given target perm to a sequence of generators using Kalka algorithm.
# Return sequence of generator indices. Use factorNames to obtain a nicer format.
# Optional params:
# - full: performs full search upto minlevels even after 2,3-cycle is already found
# - minlevels: (optional) number of levels to search for small cycle
proc factorize*[N: static[int]](gens: GroupGens[N], target: Perm[N], full = false, minlevels = 0): seq[int] =
  # - stage 0
  let sign = gens.sign
  let length = (5 + sign) div 2 # 2 or 3
  let levels = max(minlevels, nextPowerOver(gens.len, N*N))
  # - stage 1
  let (seed, meta) = gens.searchCycle(length, levels, N, full)
  if debug: echo("SEED: ", seed, "\nMETA: ", meta)
  if seed.len == 0:
    raise FactorizeError.newException("failed to find short cycle")
  # - stage 2
  let cycles = target.splitCycles(length)
  let covers = gens.coverCycles(seed, cycles)
  # - finalize
  result = calcFactors(gens, meta, covers)


# Breadth-first search to determine the orbit of point alpha, and return transversal
# For each point it gives an optional perm moving alpha to that point.
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
  let cosetReps = orbitTransversal(gens, alpha)
  for i, rep in cosetReps:
    if rep.isSome:
      for item in gens:
        let rep1 = cosetReps[item.perm[i]]
        let perm = rep.get * item.perm * rep1.get.inverse
        if not perm.isIdentity:
          yield perm
