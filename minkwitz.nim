import permgroup, options

from algorithm import reversed 
from sequtils import mapIt

## Minkwitz algorithm for short word transversal system and factorization.

type PermWord[N: static[int]] = tuple[perm: Perm[N], word: seq[int], news: bool]

# Actual dimensions: base.len x N
type TransTable*[N: static[int]] = array[N, array[N, Option[PermWord[N]]]]

# Distinct point indices; a redundant base may have length N.
type GroupBase* = seq[Point]

type FactorizeError* = object of CatchableError

var debugM* {.global.} = false

# Generating set is presumed to be normalized
# -----------------------------------------------------------------

proc identityPW(N: static[int]): PermWord[N] =
  result = (perm: N.identity, word: newSeq[int](), news: false)


proc isIdentity[N: static[int]](p: PermWord[N]): bool = p.perm.isIdentity


proc inverse[N: static[int]](word: seq[int], gens: GroupGens[N]): seq[int] =
  result = word.reversed.mapIt(gens[it].inverse)


proc inverse[N: static[int]](p: PermWord[N], gens: GroupGens[N], news: bool = false): PermWord[N] =
  result = (perm: p.perm.inverse, word: p.word.inverse(gens), news: news)


proc `*`[N: static[int]](p: PermWord[N], q: PermWord[N]): PermWord[N] =
  result = (perm: p.perm * q.perm, word: p.word & q.word, news: false)


proc validBase(base: GroupBase; degree: int): bool =
  if base.len > degree: return false
  var seen = newSeq[bool](degree)
  for point in base:
    if point < 0 or point >= degree or seen[point]: return false
    seen[point] = true
  return true


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
  for j in 0 ..< base.len:
    # Process a snapshot; replacements made during this pass remain new.
    let previous = nu[j]
    for col in 0 ..< N:
      if nu[j][col].isSome:
        var pw = nu[j][col].get
        pw.news = false
        nu[j][col] = some(pw)
    for x in previous:
      for y in previous:
        if x.isSome and y.isSome and (x.get.news or y.get.news):
          t = x.get * y.get
          oneRound(gens, base, lim, j, nu, t)

proc fillOrbits[N: static[int]](gens: GroupGens[N]; base: GroupBase; lim: float; nu: var TransTable[N]): void =
  for i in 0 ..< base.len:
    var orbit = newSeq[Point]()
    for col, entry in nu[i]:
      if entry.isSome: orbit.add(Point(col))

    for j in i+1 ..< base.len:
      for x in nu[j]:
        if x.isSome:
          let x1 = x.get.inverse(gens)
          for q in orbit:
            let p = x.get.perm[q]
            if nu[i][p].isNone:
              var t1 = x1 * nu[i][q].get
              if float(t1.word.len) < lim:
                t1.news = true
                nu[i][p] = some(t1)


# Options:
#   n: maximum number of distinct nonidentity input elements (not a time cap)
#   s: reset each s rounds
#   w: limit for word size
# Returns a possibly incomplete table. Call isCompleteSGS separately to certify it.
proc buildShortWordsSGS*[N: static[int]](gens: GroupGens[N]; base: GroupBase; n, s, w: int): TransTable[N] =
  if not validBase(base, N) or not gens.isNormalized or n < 0 or s <= 0 or w <= 0:
    raise ValueError.newException("valid base, normalized generators, n >= 0 and s,w > 0 required")
  var nu: TransTable[N]
  for i in 0 ..< base.len:
    nu[i][base[i]] = some(N.identityPW)

  if n == 0 or base.len == 0:
    return nu
  var lim = float(w)
  var cnt: int = 0
  for perm, word in gens.shortWords(n):
    cnt.inc
    var pw = (perm: perm, word: word, news: false)
    oneRound(gens, base, lim, 0, nu, pw)

    if cnt mod s == 0:
      oneImprove(gens, base, lim, nu)
      fillOrbits(gens, base, lim, nu)
      lim = lim * 5/4
    if cnt >= n:
      break

  result = nu


# Local permutation invariants only; does NOT certify completeness or word provenance.
proc isValidSGS*[N: static[int]](nu: TransTable[N]; base: GroupBase): bool =
  if not validBase(base, N): return false
  result = true
  for i in 0 ..< base.len:
    # diagonal identities
    if nu[i][base[i]].isNone: return false
    let p = nu[i][base[i]].get.perm
    if not p.isIdentity:
      result = false

    for j in 0 ..< N:
      if nu[i][j].isSome:
        let p = nu[i][j].get.perm
        if not p.isValid: return false

        # stabilizes points upto i
        for k in 0 ..< i:
          if p[base[k]] != base[k]:
            result = false
        # correct transversal at i
        if p[j] != base[i]:
          result = false


proc siftsToIdentity[N: static[int]](nu: TransTable[N]; base: GroupBase;
                                    target: Perm[N]; start: int): bool =
  var residual = target
  for i in start ..< base.len:
    let col = residual[base[i]]
    if nu[i][col].isNone: return false
    residual = residual * nu[i][col].get.perm
  return residual.isIdentity


proc isCompleteSGS*[N: static[int]](gens: GroupGens[N]; base: GroupBase;
                                  nu: TransTable[N]): bool =
  ## Exact optional certificate: word provenance, orbit closure, Schreier sifting,
  ## and trivial terminal stabilizer. Does not enumerate the group or assume its order.
  if not gens.isNormalized or not nu.isValidSGS(base): return false
  for i in 0 ..< base.len:
    for entry in nu[i]:
      if entry.isSome:
        for letter in entry.get.word:
          if letter < 0 or letter >= gens.len: return false
        if gens.composeSeq(entry.get.word) != entry.get.perm: return false
  if base.len == 0:
    for gen in gens:
      if not gen.perm.isIdentity: return false
    return true
  for i in countdown(base.high, 0):
    var strong: seq[Perm[N]] = @[]
    if i == 0:
      for gen in gens: strong.add(gen.perm)
    for j in i ..< base.len:
      for entry in nu[j]:
        if entry.isSome and not entry.get.perm.isIdentity:
          strong.add(entry.get.perm)
    for col, entry in nu[i]:
      if entry.isSome:
        let rep = entry.get.perm.inverse
        for gen in strong:
          let next = gen[col]
          if nu[i][next].isNone: return false
          let schreier = rep * gen * nu[i][next].get.perm
          if not nu.siftsToIdentity(base, schreier, i+1): return false
  return true


# TODO: tests
proc quality*[N: static[int]](nu: TransTable[N]; base: GroupBase): int =
  for i in 0 ..< base.len:
    var maxlen = 0
    for j in 0 ..< N:
      if nu[i][j].isSome:
        let wordlen = nu[i][j].get.word.len
        if wordlen > maxlen:
          maxlen = wordlen

    result += maxlen


proc factorizeM*[N: static[int]](gens: GroupGens[N]; base: GroupBase; nu: TransTable[N]; target: Perm[N]): seq[int] =
  if not validBase(base, N) or not gens.isNormalized or not target.isValid:
    raise ValueError.newException("valid base/permutations and normalized generators required")
  if target.isIdentity: return @[]
  var list = newSeq[int]()
  var perm = target
  for i in 0 ..< base.len:
    let omega = perm[base[i]]
    if nu[i][omega].isNone:
      raise FactorizeError.newException("missing transversal entry: incomplete table or nonmember target")
    let entry = nu[i][omega].get
    if not entry.perm.isValid:
      raise FactorizeError.newException("invalid transversal permutation")
    for letter in entry.word:
      if letter < 0 or letter >= gens.len:
        raise FactorizeError.newException("invalid transversal word index")
    perm = perm * entry.perm
    list.add(entry.word)

  if not perm.isIdentity:
    raise FactorizeError.newException("failed to reach identity")

  result = list.inverse(gens)
  if gens.composeSeq(result) != target:
    raise FactorizeError.newException("transversal words do not evaluate to target")
