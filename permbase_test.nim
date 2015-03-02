import perm, permbase, unittest

suite "permbase":
  test "basic":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase
    check(base.sign == -1)
    check(base.size == 2)
    check(base.printBase == data)

  test "normalize 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase.normalize
    check(base.sign == -1)
    check(base.size == 3)
    check(base[2].name == "A'")
    check(base[2].inverse == 0)

  test "normalize 1":
    let data = "A: (1, 2)\nB: (3, 4)"
    let base = data.parseBase.normalize
    check(base.size == 2)
    check(base[0].inverse == 0)
    check(base[1].inverse == 1)

  test "multiply 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase
    var list = newSeq[Perm](4)
    for perm, i in base.toSeq.multiply(base):
      list[i] = perm
    check(list[0].printCycles == "(1, 3, 2)")
    check(list[1].printCycles == "(1, 2, 4, 3)")
    check(list[2].printCycles == "(1, 2, 3, 4)")
    check(list[3].printCycles == "()")
