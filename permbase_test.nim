import perm, permbase, unittest

suite "permbase":
  test "basic":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase
    check(base.sign == -1)
    check(base.len == 2)
    check(base.printBase == data)

  test "random":
    let base = randomBase(3)
    check(base.len == 3)
    check(base[0].name == "A")
    check(base[1].name == "B")
    check(base[2].name == "C")

  test "normalize 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase.normalize
    check(base.sign == -1)
    check(base.len == 3)
    check(base[2].name == "A'")
    check(base[2].inverse == 0)

  test "normalize 1":
    let data = "A: (1, 2)\nB: (3, 4)"
    let base = data.parseBase.normalize
    check(base.len == 2)
    check(base[0].inverse == 0)
    check(base[1].inverse == 1)

  test "multiply":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase
    var list = newSeq[Perm](4)
    for perm, i in base.toSeq.multiply(base):
      list[i] = perm
    check(list[0].printCycles == "(1, 3, 2)")
    check(list[1].printCycles == "(1, 2, 4, 3)")
    check(list[2].printCycles == "(1, 2, 3, 4)")
    check(list[3].printCycles == "()")

  test "search 0":
    let base = parseBase("A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)")
    let norm = base.normalize
    let (p, s) = norm.searchCycle(3, 8)
    check(p == norm.composeSeq(s))
    check(s == @[0, 1, 1])
    let o = p.orderToCycle(3)
    check(o == 5)

  test "search 1":
    let base = parseBase("A: (1 2)(3 4)\nB: (1 3)(2 4)")
    let (p, s) = base.searchCycle(3, 4)
    check(p.isIdentity == true)
    check(s.len == 0)
    let o = p.orderToCycle(3)
    check(o == -1)
