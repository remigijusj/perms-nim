import permgroup

from algorithm import reverse
from math      import ceil, ln

type FactorizeError* = object of Exception


# Calc the sign of the generating set: -1 if any element is odd, 1 otherwise.
proc sign*(gens: GroupGens): int =
  for item in gens:
    if item.perm.sign == -1:
      return -1
  return 1


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
proc factorizeK*[N: static[int]](gens: GroupGens[N], target: Perm[N], full = false, minlevels = 0): seq[int] =
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
