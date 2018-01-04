import permgroup, options

from algorithm import reversed 
from sequtils import mapIt, filterIt

type PermWord[N: static[int]] = tuple[perm: Perm[N], word: seq[int], news: bool]

# Actual dimensions: base.len x N
type TransTable*[N: static[int]] = array[N, array[N, Option[PermWord[N]]]]

# Must be: len < N
type GroupBase* = seq[Point]

var debugM* {.global.} = false

# Generating set is presumed to be normalized
# -----------------------------------------------------------------

proc identityPW(N: static[int]): PermWord[N] =
  result = (perm: N.identity, word: newSeq[int](), news: false)


proc isIdentity[N: static[int]](p: PermWord[N]): bool = p.word.len == 0


proc inverse[N: static[int]](word: seq[int], gens: GroupGens[N]): seq[int] =
  result = word.reversed.mapIt(gens[it].inverse)


proc inverse[N: static[int]](p: PermWord[N], gens: GroupGens[N], news: bool = false): PermWord[N] =
  result = (perm: p.perm.inverse, word: p.word.inverse(gens), news: news)


proc `*`[N: static[int]](p: PermWord[N], q: PermWord[N]): PermWord[N] =
  result = (perm: p.perm * q.perm, word: p.word & q.word, news: false)


# TODO: implement when we have BSGS and group order
proc isTableFull[N: static[int]](gens: GroupGens[N]; nu: TransTable[N]): bool =
  false


proc oneStep[N: static[int]](gens: GroupGens[N]; base: GroupBase; i: int; t: PermWord[N]; nu: var TransTable[N]): PermWord[N] =
  let j = t.perm[base[i]] # b_i ^ t
  let t1 = t.inverse(gens, news=true)
  if nu[i][j].isSome:
    result = t * nu[i][j].get
    if t.word.len < nu[i][j].get.word.len:
      nu[i][j] = some(t1)
      discard oneStep(gens, base, i, t1, nu)
  else:
    nu[i][j] = some(t1)
    discard oneStep(gens, base, i, t1, nu)
    result = N.identityPW


proc oneRound[N: static[int]](gens: GroupGens[N]; base: GroupBase; lim: float; c: int; nu: var TransTable[N]; t: var PermWord[N]): void =
  var i = c
  while (i < base.len) and (not t.isIdentity) and (float(t.word.len) < lim):
    t = oneStep(gens, base, i, t, nu)
    i.inc


proc oneImprove[N: static[int]](gens: GroupGens[N]; base: GroupBase; lim: float; nu: var TransTable[N]): void =
  var t: PermWord[N]
  for j in 0 .. <base.len:
    for x in nu[j]: # Image
      for y in nu[j]: # Image
        if x.isSome and y.isSome and (x.get.news or y.get.news):
          t = x.get * y.get
          oneRound(gens, base, lim, j, nu, t)

    for x in nu[j]:
      if x.isSome:
        var pw = x.get
        pw.news = false


proc fillOrbits[N: static[int]](gens: GroupGens[N]; base: GroupBase; lim: float; nu: var TransTable[N]): void =
  for i in 0 .. <base.len:
    var orbit = newSeq[Point]() # partial orbit already found
    for y in nu[i]:
      if y.isSome:
        let j = y.get.perm[base[i]]
        if j notin orbit: orbit.add(j)

    for j in i+1 .. <base.len:
      for u, x in nu[j]:
        if x.isSome:
          let x1 = x.get.inverse(gens)
          let orbit_x = orbit.mapIt(x.get.perm[it])
          let new_pts = orbit_x.filterIt(it notin orbit)

          for p in new_pts:
            let t1 = x1 * nu[i][x1.perm[p]].get
            if float(t1.word.len) < lim: 
              nu[i][p] = some(t1)


# Options:
#   n: max number of rounds
#   s: reset each s rounds
#   w: limit for word size
proc buildShortWordsSGS*[N: static[int]](gens: GroupGens[N]; base: GroupBase; n, s, w: int): TransTable[N] =
  var nu: TransTable[N]
  for i in 0 .. <base.len:
    nu[i][base[i]] = some(N.identityPW)

  let max = n
  var lim = float(w)
  var cnt: int = 0
  for perm, i, level in gens.multiSearch(-1):
    cnt.inc
    if cnt >= max or isTableFull(gens, nu):
      break

    let word = decodeIndex(i, level, gens.len)
    var pw = (perm: perm, word: word, news: false)
    oneRound(gens, base, lim, 0, nu, pw)

    if cnt mod s == 0:
      oneImprove(gens, base, lim, nu)
      if not isTableFull(gens, nu):
        fillOrbits(gens, base, lim, nu)
        lim = lim * 5/4

  result = nu


# Performs 3 basic checks if the constructed transversal table is valid.
proc isValidSGS*[N: static[int]](nu: TransTable[N]; base: GroupBase): bool =
  result = true
  for i in 0 .. <base.len:
    # diagonal identities
    let p = nu[i][i].get.perm
    if not p.isIdentity:
      result = false

    for j in 0 .. <N:
      if nu[i][j].isSome:
        let p = nu[i][j].get.perm

        # stabilizes points upto i
        for k in 0 .. <i:
          if p[base[k]] != base[k]:
            result = false
        # correct transversal at i
        if p[j] != base[i]:
          result = false


# TODO: tests
proc quality*[N: static[int]](nu: TransTable[N]; base: GroupBase): int =
  for i in 0 .. <base.len:
    var maxlen = 0
    for j in 0 .. <N:
      if nu[i][j].isSome:
        let wordlen = nu[i][j].get.word.len
        if wordlen > maxlen:
          maxlen = wordlen

    result += maxlen


# TODO: tests
proc factorizeM*[N: static[int]](gens: GroupGens[N]; base: GroupBase; nu: TransTable[N]; target: Perm[N]): seq[int] =
  var list = newSeq[int]()
  var perm = target
  for i in 0 .. <base.len:
    let omega = perm[base[i]]
    perm = perm * nu[i][omega].get.perm
    list.add(nu[i][omega].get.word)

  if not perm.isIdentity:
    raise FactorizeError.newException("failed to reach identity")

  result = list.inverse(gens)
