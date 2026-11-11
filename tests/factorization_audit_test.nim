import unittest
import kalka as k
include "../minkwitz.nim"

# White-box tests here cover table maintenance as well as the public contract.
suite "factorization audit":
  test "identity decompositions and trivial groups":
    check splitCycles(4.identity, 3).len == 0
    let empty: GroupGens[4] = @[]
    check k.factorizeK(empty, 4.identity).len == 0
    let gs = 4.parseGens("A: ()").normalize
    let bs: GroupBase = @[Point(3)]
    let tt = buildShortWordsSGS(gs, bs, 10, 1, 10)
    check isCompleteSGS(gs, bs, tt)
    check factorizeM(gs, bs, tt, 4.identity).len == 0
    check k.factorizeK(gs, 4.identity).len == 0
    check gs.factorNames(@[], concise=true) == ""

  test "short-word traversal exhausts cyclic group without empty word-tree slots":
    let gs = 3.parseGens("A: (1 2 3)").normalize
    var count = 0
    for p, word in gs.shortWords(3000):
      inc count
      check word.len == 1
      check gs.composeSeq(word) == p
    check count == 2
    count = 0
    for p, word in gs.shortWords(1): inc count
    check count == 1

  test "singleton generator and repeated cycle targets":
    let gs = 4.parseGens("A: (1 2)").normalize
    check k.factorizeK(gs, gs[0].perm) == @[0]
    let c = 4.newCycle(@[0, 1])
    check k.coverCycles(gs, @[c], @[c, c]).len == 2
    let noCycles: seq[Cycle[4]] = @[]
    check k.coverCycles(gs, noCycles, noCycles).len == 0

  test "A4 needs both 3-cycle conjugacy classes":
    let gs = 4.parseGens("A: (1 2 3)\nB: (1 2 4)").normalize
    for p, word in gs.shortWords(12):
      check gs.composeSeq(k.factorizeK(gs, p)) == p

  test "nonempty relation word represents identity":
    let pw: PermWord[4] = (perm: 4.identity, word: @[0, 0], news: false)
    check pw.isIdentity

  test "one round really processes one word":
    let gs = 4.parseGens("A: (1 2)").normalize
    let bs: GroupBase = @[Point(0)]
    let tt = buildShortWordsSGS(gs, bs, 1, 10, 10)
    check tt[0][1].isSome
    check isCompleteSGS(gs, bs, tt)

  test "nonstandard base and incomplete table distinction":
    let gs = 4.parseGens("A: (1 2 3 4)\nB: (1 2)").normalize
    let bs: GroupBase = @[Point(3), Point(2), Point(1)]
    let tt = buildShortWordsSGS(gs, bs, 200, 9, 30)
    check tt.isValidSGS(bs)
    check isCompleteSGS(gs, bs, tt)
    let partial = buildShortWordsSGS(gs, bs, 0, 9, 30)
    check partial.isValidSGS(bs)
    check not isCompleteSGS(gs, bs, partial)
    expect FactorizeError:
      discard factorizeM(gs, bs, partial, gs[0].perm)
    let shortBase: GroupBase = @[Point(0)]
    let shortTable = buildShortWordsSGS(gs, shortBase, 200, 9, 30)
    check not isCompleteSGS(gs, shortBase, shortTable)

  test "consumed improvement flags are cleared":
    let gs = 4.parseGens("A: (1 2)").normalize
    let bs: GroupBase = @[Point(0)]
    var tt: TransTable[4]
    tt[0][0] = some(4.identityPW)
    tt[0][1] = some((perm: gs[0].perm, word: @[0], news: true))
    oneImprove(gs, bs, 10, tt)
    check not tt[0][1].get.news

  test "orbit fill uses column labels and preserves inverse direction":
    let gs = 4.parseGens("A: (1 3 2)\nB: (3 4)").normalize
    let bs: GroupBase = @[Point(0), Point(1), Point(2)]
    var tt: TransTable[4]
    for i in 0..2: tt[i][i] = some(4.identityPW)
    tt[0][1] = some((perm: gs[0].perm, word: @[0], news: true))
    tt[2][3] = some((perm: gs[1].perm, word: @[1], news: true))
    fillOrbits(gs, bs, 30, tt)
    check tt.isValidSGS(bs)
    # Add a genuine route from column2 to column3.
    tt[0][2] = some((perm: gs[2].perm, word: @[2], news: false))
    fillOrbits(gs, bs, 30, tt)
    check tt[0][3].isSome
    check tt[0][3].get.perm[3] == Point(0)
    check composeSeq(gs, tt[0][3].get.word) == tt[0][3].get.perm
    check tt[0][3].get.news

  test "certificate rejects missing entries and forged word provenance":
    let gs = 4.parseGens("A: (1 2)").normalize
    let bs: GroupBase = @[Point(0)]
    let tt = buildShortWordsSGS(gs, bs, 1, 10, 10)
    var bad = tt
    bad[0][1] = none(PermWord[4])
    check not isCompleteSGS(gs, bs, bad)
    bad = tt
    var entry = bad[0][1].get
    entry.word = @[]
    bad[0][1] = some(entry)
    check bad.isValidSGS(bs)
    check not isCompleteSGS(gs, bs, bad)
    expect FactorizeError:
      discard factorizeM(gs, bs, bad, gs[0].perm)
    bad = tt
    entry.word = @[-1]
    bad[0][1] = some(entry)
    check not isCompleteSGS(gs, bs, bad)
    expect FactorizeError:
      discard factorizeM(gs, bs, bad, gs[0].perm)

  test "invalid base, parameters and inverse links are rejected":
    let gs = 4.parseGens("A: (1 2 3)")
    let bs: GroupBase = @[Point(0)]
    expect ValueError:
      discard buildShortWordsSGS(gs, bs, 10, 1, 10)
    expect ValueError:
      discard k.factorizeK(gs, gs[0].perm)
    expect ValueError:
      discard buildShortWordsSGS(gs.normalize, bs, 10, 0, 10)
    expect ValueError:
      discard buildShortWordsSGS(gs.normalize, @[Point(4)], 10, 1, 10)
    expect ValueError:
      discard buildShortWordsSGS(gs.normalize, @[Point(0), Point(0)], 10, 1, 10)

  test "nonmember and proper subgroup limitations are explicit":
    let gs = 4.parseGens("A: (1 2)(3 4)\nB: (1 3)(2 4)").normalize
    expect k.FactorizeError:
      discard k.factorizeK(gs, 4.parsePerm("(1 4)(2 3)"))
    expect k.FactorizeError:
      discard k.factorizeK(gs, 4.parsePerm("(1 2)"))
    let bs: GroupBase = @[Point(0)]
    let tt = buildShortWordsSGS(gs, bs, 20, 2, 10)
    check isCompleteSGS(gs, bs, tt)
    expect FactorizeError:
      discard factorizeM(gs, bs, tt, 4.parsePerm("(1 2)"))

  test "bounded cycle power checks the lcm as well as coprimality":
    let p = 17.parsePerm("(1 2)(3 4 5)(6 7 8 9 10)(11 12 13 14 15 16 17)")
    check p.orderToCycle(2) == 105
    check p.orderToCycle(2, 17) == -1
    check p.power(105) == 17.parsePerm("(1 2)")

  test "full-size random cycle uses valid zero-based points":
    for i in 0..9:
      let c = 4.randomCycle(4)
      check c.toPerm.isValid
      check c.toPerm.signature[4] == 1
