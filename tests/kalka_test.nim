import permgroup, kalka, unittest

from sequtils import mapIt, deduplicate

const W = 8

suite "kalka":
  test "sign 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    check(gens.sign == -1)

  test "sign 1":
    let data = "A: (1, 2, 3)\nB: (2, 3)(4, 5)"
    let gens = W.parseGens(data)
    check(gens.sign == 1)

  test "searchCycle 0":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let gens = W.parseGens(data)
    let norm = gens.normalize
    let (list, meta) = norm.searchCycle(3, 8)
    check(list.len == 1)
    check(meta.len == 1)
    check(list[0] == W.newCycle(@[1, 3, 6]))
    check(meta[0] == @[0, 1, 1, 5]) # 5 is order

  test "searchCycle 1":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let gens = W.parseGens(data)
    let norm = gens.normalize
    let (list, meta) = norm.searchCycle(3, 4, 8, true)
    check(list.len == 10)
    check(meta.len == 10)
    check(list[9] == W.newCycle(@[0, 6, 3]))
    check(meta[9] == @[2, 2, 0, 2, 5]) # 5 is order
    let reps = list.mapIt($it)
    check(reps.deduplicate.len == 10)

  test "searchCycle 2":
    let data = "A: (1 2)(3 4)\nB: (1 3)(2 4)"
    let gens = W.parseGens(data)
    let (list, meta) = gens.searchCycle(3, 4)
    check(list.len == 0)
    check(meta.len == 0)

  test "coverCycles 0":
    let gens = W.parseGens("A: (1 2 3 4)(5 6)\nB: (1 3 5)")
    let seed = @[W.newCycle(@[1, 3])]
    let target = @[W.newCycle(@[0, 4]), W.newCycle(@[1, 5])]
    let covers = gens.coverCycles(seed, target)
    check(covers.len == 2)
    check(covers[0] == @[0, 0, 1, 1])
    check(covers[1] == @[0, 0, 1, 1, 0])

  test "coverCycles 1":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let gens = W.parseGens(data)
    let norm = gens.normalize
    let seed = @[W.newCycle(@[1, 3, 6])]
    let target = @[W.newCycle(@[2, 4, 6]), W.newCycle(@[5, 3, 1])]
    let covers = norm.coverCycles(seed, target)
    check(covers == @[@[0, 1], @[0, 1, 0]])

  test "coverCycles 2":
    let data = "A: (1 2)(3 4)\nB: (1 3)(2 4)"
    let gens = W.parseGens(data)
    let seed = @[W.newCycle(@[0, 2])]
    let target = @[W.newCycle(@[1, 3]), W.newCycle(@[1, 2])]
    expect FactorizeError:
      discard gens.coverCycles(seed, target)

  test "factorize 0":
    let gens = W.parseGens("A: (1 2 3 4)(5 6)\nB: (1 3 5)").normalize
    let perm = W.parsePerm("(1 3 5)(2 4 6)")
    let list = gens.factorizeK(perm)
    check(gens.composeSeq(list) == perm)
    check(gens.factorNames(list) == "BA'BA")

  test "factorize 0a":
    let gens = W.parseGens("A: (1 2 3 4)(5 6)\nB: (1 3 5)").normalize
    let perm = W.parsePerm("(1 3 5)(2 4 6)")
    let list = gens.factorizeK(perm, full=true)
    check(gens.composeSeq(list) == perm)
    check(gens.factorNames(list) == "BAB'A'")
