import permbase, unittest

suite "permbase":
  test "basic":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase
    check(base.sign == -1)
    check(base.size == 2)
    check(base.printBase == data)

  test "normalize":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let base = data.parseBase.normalize
    check(base.sign == -1)
    check(base.size == 3)
    check(base[2].name == "A'")
