import perm, unittest

# const N = 8
# type P = uint8

suite "basic tests":
  test "constructor":
    let p: Perm = [1'u8, 0'u8, 2'u8, 3'u8, 4'u8, 5'u8, 6'u8, 7'u8]
    check($ p == "[1 0 2 3 4 5 6 7]")

  test "newPerm invalid":
    var p: Perm
    expect PermErr:
      p = newPerm(@[1, 2, 3, 4, 5, 6, 7])
    expect PermErr:
      p = newPerm(@[0, 0, 1])
    expect PermErr:
      p = newPerm(@[-2, 0, 1])
    expect PermErr:
      p = newPerm(@[0, 2, 3])
    expect PermErr:
      p = newPerm(@[3, 2, 3])

  test "identity valid":
    let p = identity()
    check(p.size == 8)
    check($ p == "[0 1 2 3 4 5 6 7]")

  test "randomPerm":
    let p = randomPerm()
    check(p.size == 8)


  test "size":
    let p = newPerm(@[1, 3, 2, 0])
    check(p.size == 8)


  test "inverse":
    let p = newPerm(@[1, 2, 3, 4, 0])
    check($ p.inverse == "[4 0 1 2 3 5 6 7]")


  test "compose":
    let p = newPerm(@[1, 2, 0])
    let q = newPerm(@[0, 3, 4, 1, 2])
    check($ p.compose(q) == "[3 4 0 1 2 5 6 7]")


  test "power":
    let p = newPerm(@[1, 2, 3, 4, 5, 0])
    check($ p.power(2) == "[2 3 4 5 0 1 6 7]")


  test "conjugate 0":
    let p = identity()
    let q = randomPerm()
    check(p.conjugate(q).isIdentity == true)

  test "conjugate 0a":
    let p = randomPerm()
    let q = identity()
    check(p.conjugate(q) == p)

  test "conjugate 1":
    let p = newPerm(@[1, 2, 0])
    let q = newPerm(@[0, 3, 4, 1, 2])
    check($ p.conjugate(q) == "[3 1 2 4 0 5 6 7]")

  test "conjugate 2":
    let p = newPerm(@[4, 2, 0, 1, 3])
    let q = newPerm(@[1, 2, 0])
    check($ p.conjugate(q) == "[1 4 0 2 3 5 6 7]")


  test "isIdentity 0":
    let p = newPerm(@[])
    check(p.isIdentity == true)

  test "isIdentity 1":
    let p = newPerm(@[0, 1])
    check(p.isIdentity == true)

  test "isIdentity 2":
    let p = newPerm(@[0, 1, 2])
    check(p.isIdentity == true)

  test "isIdentity 3":
    let p = newPerm(@[1, 0])
    check(p.isIdentity == false)

  test "isIdentity 4":
    let p = newPerm(@[0, 1, 3, 2])
    check(p.isIdentity == false)


  test "isEqual 0":
    let p = newPerm(@[])
    check(p == p)

  test "isEqual 1":
    let p = newPerm(@[0])
    check(p == p)

  test "isEqual 2":
    let p = newPerm(@[0, 1])
    let q = newPerm(@[0, 1, 2])
    check(p == q)
    check(q == p)


  test "signature 0":
    let p = newPerm(@[])
    check(p.signature == @[0, 8, 0, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 1)

  test "signature 1":
    let p = newPerm(@[0])
    check(p.signature == @[0, 8, 0, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 1)

  test "signature 2":
    let p = newPerm(@[1, 0])
    check(p.signature == @[0, 6, 1, 0, 0, 0, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 2)
    check(p.orderToCycle(2) == 1)

  test "signature 4":
    let p = newPerm(@[1, 0, 3, 2])
    check(p.signature == @[0, 4, 2, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 2)
    check(p.orderToCycle(2) == -1)

  test "signature 5a":
    let p = newPerm(@[1, 0, 3, 2, 4])
    check(p.signature == @[0, 4, 2, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 2)

  test "signature 5c":
    let p = newPerm(@[1, 0, 3, 4, 2])
    check(p.signature == @[0, 3, 1, 1, 0, 0, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)
    check(p.orderToCycle(2) == 3)
    check(p.orderToCycle(3) == 2)

  test "signature 5d":
    let p = newPerm(@[0, 1, 3, 4, 2])
    check(p.signature == @[0, 5, 0, 1, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 3)
    check(p.orderToCycle(3) == 1)

  test "signature 6a":
    let p = newPerm(@[1, 2, 3, 4, 5, 0])
    check(p.signature == @[0, 2, 0, 0, 0, 0, 1, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)

  test "signature 6b":
    let p = newPerm(@[0, 2, 1, 4, 5, 3])
    check(p.signature == @[0, 3, 1, 1, 0, 0, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)

  test "signature 6c":
    let p = newPerm(@[5, 4, 1, 2, 3, 0])
    check(p.signature == @[0, 2, 1, 0, 1, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 4)
    check(p.orderToCycle(4) == -1)


  test "parseCycles invalid 0":
    expect PermErr:
      discard parseCycles("(1 2 3 0)")

  test "parseCycles invalid 1":
    expect PermErr:
      discard parseCycles("(1 2)(2, 3)")

  test "parseCycles invalid 2":
    expect PermErr:
      discard parseCycles("(1, 2, 65537)")


  test "parseCycles 0":
    let p = parseCycles("")
    check($ p == "[0 1 2 3 4 5 6 7]")

  test "parseCycles 1":
    let p = parseCycles("")
    check($ p == "[0 1 2 3 4 5 6 7]")

  test "parseCycles 2":
    let p = parseCycles("( )( ( )(")
    check($ p == "[0 1 2 3 4 5 6 7]")

  test "parseCycles 3":
    let p = parseCycles("(1)")
    check($ p == "[0 1 2 3 4 5 6 7]")

  test "parseCycles 4":
    let p = parseCycles("(1,2)")
    check($ p == "[1 0 2 3 4 5 6 7]")

  test "parseCycles 5":
    let p = parseCycles("(3,5)")
    check($ p == "[0 1 4 3 2 5 6 7]")

  test "parseCycles 6":
    let p = parseCycles("(1, 2) (3, 4) ")
    check($ p == "[1 0 3 2 4 5 6 7]")

  test "parseCycles 7":
    let p = parseCycles("(1 2)(3 8)(7 4)")
    check($ p == "[1 0 7 6 4 5 3 2]")

  test "parseCycles 8":
    let p = parseCycles("(1 2 ; 3, 8 ; 7 4 )")
    check($ p == "[1 0 7 6 4 5 3 2]")

  test "parseCycles 9":
    let p = parseCycles("1 2 3 4)(5 6 7 8")
    check($ p == "[1 2 3 0 5 6 7 4]")


  test "printCycles 1":
    let p = newPerm(@[])
    check(p.printCycles == "()")

  test "printCycles 2":
    let p = newPerm(@[0])
    check(p.printCycles == "()")

  test "printCycles 3":
    let p = identity()
    check(p.printCycles == "()")

  test "printCycles 4":
    let p = newPerm(@[1, 2, 3, 4, 5, 0])
    check(p.printCycles == "(1, 2, 3, 4, 5, 6)")

  test "printCycles 5":
    let p = newPerm(@[1, 2, 0, 4, 5, 3])
    check(p.printCycles == "(1, 2, 3)(4, 5, 6)")

  test "printCycles 6":
    let p = newPerm(@[5, 4, 3, 2, 1, 0])
    check(p.printCycles == "(1, 6)(2, 5)(3, 4)")

  test "printCycles 7":
    let p = newPerm(@[0, 1, 4, 3, 2, 5])
    check(p.printCycles == "(3, 5)")
