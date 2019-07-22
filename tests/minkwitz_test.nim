import permgroup, minkwitz, unittest

from options import get, isNone, isSome
from sequtils import mapIt
from strutils import `format`

const
  W4 = 4
  W8 = 8

# debugM = true


iterator eachEntry[N: static[int]](tt: TransTable[N]): string =
  for i in 0 ..< N:
    for j in 0 ..< N:
      if tt[i][j].isSome:
        yield "$1.$2 -> $3".format(i, j, tt[i][j].get)


proc printInfo[N: static[int]](gens: GroupGens[N]; base: GroupBase; tt: TransTable[N]): void =
  echo gens.printGens
  for it in eachEntry(tt): echo it
  echo "Quality: ", quality(tt, base)


suite "minkwitz":
  test "transversal table 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W4.parseGens(data).normalize
    let base = @[0, 1, 2, 3].mapIt(it.Point)
    let tt = buildShortWordsSGS(gens, base, n=26, s=4*4, w=10)
    check(isValidSGS(tt, base))
    if debugM: printInfo(gens, base, tt)

  test "transversal table 1":
    let data = "A: (1, 2)(3, 4)\nB: (1, 3)(2, 4)" # Klein group
    let gens = W4.parseGens(data).normalize
    let base = @[0].mapIt(it.Point)
    let tt = buildShortWordsSGS(gens, base, n=10, s=2, w=6)
    check(isValidSGS(tt, base))
    if debugM: printInfo(gens, base, tt)

  test "factorize 0":
    let data = "A: (1, 2)\nB: (1, 3)\nC: (1, 4)" # S_4, standard
    let gens = W4.parseGens(data).normalize
    let base = @[0, 1, 2].mapIt(it.Point)
    let tt = buildShortWordsSGS(gens, base, n=26, s=3*3, w=10)
    if debugM: printInfo(gens, base, tt)
    let perm = W4.parsePerm("(1, 3, 2, 4)")
    let fact = factorizeM(gens, base, tt, perm)
    if debugM: echo "Fact: ", fact, " - ", fact.len
    check(composeSeq(gens, fact) == perm)

  test "factorize 1":
    let data = "A: (1, 3, 5, 6)\nB: (1, 3)\nC: (7, 8)"
    let gens = W8.parseGens(data).normalize
    let base = @[0, 1, 2, 3, 4, 5, 6, 7].mapIt(it.Point)
    let tt = buildShortWordsSGS(gens, base, n=26, s=3*3, w=10)
    if debugM: printInfo(gens, base, tt)
    let perm = composeSeq(gens, @[0, 1, 2, 1, 0])
    let fact = factorizeM(gens, base, tt, perm)
    if debugM: echo "Fact: ", fact, " - ", fact.len
    check(composeSeq(gens, fact) == perm)
