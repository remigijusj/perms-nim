import sequtils, perm, permbase, unittest

suite "permbase":
  test "basics":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = parseBase(data)
    check(base.sign == -1)
    check(base.len == 2)
    check(base.printBase == data)

  test "random":
    let base = randomBase(3)
    check(base.len == 3)
    check(base[0].name == "A")
    check(base[1].name == "B")
    check(base[2].name == "C")

  test "perms":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = parseBase(data)
    check(base.perms == @[parsePerm("(1, 2, 3)"), parsePerm("(3, 4)")])

  test "sign 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = parseBase(data)
    check(base.sign == -1)

  test "sign 1":
    let data = "A: (1, 2, 3)\nB: (2, 3)(4, 5)"
    let base = parseBase(data)
    check(base.sign == 1)

  test "normalize 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = parseBase(data).normalize
    check(base.sign == -1)
    check(base.len == 3)
    check(base[2].name == "A'")
    check(base[2].inverse == 0)

  test "normalize 1":
    let data = "A: (1, 2)\nB: (3, 4)"
    let base = parseBase(data).normalize
    check(base.len == 2)
    check(base[0].inverse == 0)
    check(base[1].inverse == 1)

  test "normalize 2":
    let data = "A: (1, 2, 4)\nB: (3, 1)\nX: (5, 4, 3, 2, 1)"
    let base = parseBase(data).normalize
    check(base.len == 5)
    check(base[0].inverse == 3)
    check(base[1].inverse == 1)
    check(base[2].inverse == 4)
    check(base[3].inverse == 0)
    check(base[4].inverse == 2)
    check(base[3].name == "A'")
    check(base[4].name == "X'")
    check(base[3].perm.inverse == base[0].perm)
    check(base[4].perm.inverse == base[2].perm)

  test "composeSeq":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let base = parseBase(data)
    check(base.composeSeq(newSeq[int]()) == identity())
    check(base.composeSeq(@[0]) == base[0].perm)
    check(base.composeSeq(@[1]) == base[1].perm)
    check(base.composeSeq(@[0, 1, 0]) == [0, 1, 2, 7, 3, 4, 5, 6])
    check(base.composeSeq(@[1, 0, 1]) == [6, 5, 0, 4, 7, 3, 2, 1])

  test "factorNames":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let base = parseBase(data).normalize
    check(base.factorNames(newSeq[int]()) == "")
    check(base.factorNames(@[0]) == "A")
    check(base.factorNames(@[1]) == "B")
    check(base.factorNames(@[0, 1, 2]) == "ABB'")
    check(base.factorNames(@[1, 0, 1], ",") == "B,A,B")


suite "stage 1":
  test "multiply":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = parseBase(data)
    var list = newSeq[Perm](4)
    for perm, i in base.perms.multiply(base):
      list[i] = perm
    check(list[0].printCycles == "(1, 3, 2)")
    check(list[1].printCycles == "(1, 2, 4, 3)")
    check(list[2].printCycles == "(1, 2, 3, 4)")
    check(list[3].printCycles == "()")

  test "searchCycle 0":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let base = parseBase(data)
    let norm = base.normalize
    let (list, meta) = norm.searchCycle(3, 8)
    check(list.len == 1)
    check(meta.len == 1)
    check(list[0] == newCycle(@[1, 3, 6]))
    check(meta[0] == @[0, 1, 1, 5]) # 5 is order

  test "searchCycle 1":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let base = parseBase(data)
    let norm = base.normalize
    let (list, meta) = norm.searchCycle(3, 4, 8, true)
    check(list.len == 10)
    check(meta.len == 10)
    check(list[9] == newCycle(@[0, 6, 3]))
    check(meta[9] == @[2, 2, 0, 2, 5]) # 5 is order
    let reps = list.mapIt(string, $it)
    check(reps.deduplicate.len == 10)

  test "searchCycle 2":
    let data = "A: (1 2)(3 4)\nB: (1 3)(2 4)"
    let base = parseBase(data)
    let (list, meta) = base.searchCycle(3, 4)
    check(list.len == 0)
    check(meta.len == 0)


suite "stage 2":
  test "conjugate":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = parseBase(data)
    var seed = parsePerm("(1, 4)(2, 3)").cycles
    check(seed[0] == newCycle(@[0, 3]))
    check(seed[1] == newCycle(@[1, 2]))
    var list = newSeq[tuple[c: Cycle; i, j: int]]()
    for c, i, j in seed.conjugate(base):
      list.add((c, i, j))
    check(list.len == 4)
    check(list[0] == (newCycle(@[1, 3]), 0, 0))
    check(list[1] == (newCycle(@[0, 2]), 0, 1))
    check(list[2] == (newCycle(@[0, 2]), 1, 0))
    check(list[3] == (newCycle(@[1, 3]), 1, 1))

  test "coverCycles 0":
    let base = parseBase("A: (1 2 3 4)(5 6)\nB: (1 3 5)")
    let seed = @[newCycle(@[1, 3])]
    let target = @[newCycle(@[0, 4]), newCycle(@[1, 5])]
    let covers = base.coverCycles(seed, target)
    check(covers.len == 2)
    check(covers[0] == @[0, 0, 1, 1])
    check(covers[1] == @[0, 0, 1, 1, 0])

  test "coverCycles 1":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let base = parseBase(data)
    let norm = base.normalize
    let seed = @[newCycle(@[1, 3, 6])]
    let target = @[newCycle(@[2, 4, 6]), newCycle(@[5, 3, 1])]
    let covers = norm.coverCycles(seed, target)
    check(covers == @[@[0, 1], @[0, 1, 0]])

  test "coverCycles 2":
    let data = "A: (1 2)(3 4)\nB: (1 3)(2 4)"
    let base = parseBase(data)
    let seed = @[newCycle(@[0, 2])]
    let target = @[newCycle(@[1, 3]), newCycle(@[1, 2])]
    expect PermError:
      discard base.coverCycles(seed, target)

suite "final":
  test "factorize 0":
    let base = parseBase("A: (1 2 3 4)(5 6)\nB: (1 3 5)").normalize
    let perm = parsePerm("(1 3 5)(2 4 6)")
    let list = base.factorize(perm)
    check(base.composeSeq(list) == perm)
    check(base.factorNames(list) == "BA'BA")

  test "factorize 0a":
    let base = parseBase("A: (1 2 3 4)(5 6)\nB: (1 3 5)").normalize
    let perm = parsePerm("(1 3 5)(2 4 6)")
    let list = base.factorize(perm, true)
    check(base.composeSeq(list) == perm)
    check(base.factorNames(list) == "BAB'A'")
