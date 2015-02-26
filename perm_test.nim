import unittest, perm

suite "basic tests":
  test "newPerm invalid":
    expect PError:
      discard newPerm(@[1, 2, 3])
    expect PError:
      discard newPerm(@[0, 0, 1])
    expect PError:
      discard newPerm(@[-2, 0, 1])
    expect PError:
      discard newPerm(@[0, 2, 3])
    expect PError:
      discard newPerm(@[3, 2, 3, 0])


  test "identity invalid":
    expect PError:
      discard identity(-1)
    expect PError:
      discard identity(1 shl 16 + 1)


  test "identity valid":
    let p = identity(3)
    check(p.size == 3)
    check($ p == "[0 1 2]")


  test "randomPerm":
    let p = randomPerm(128)
    check(p.size == 128)


  test "toString":
    let p = newPerm(@[1, 0, 2])
    check($ p == "[1 0 2]")


  test "size":
    let p = newPerm(@[1, 3, 2, 0])
    check(p.size == 4)


  test "on":
    let p = newPerm(@[1, 4, 2, 0, 3])
    check(p.on(0) == 1)
    check(p.on(1) == 4)
    check(p.on(2) == 2)
    check(p.on(3) == 0)
    check(p.on(4) == 3)
    check(p.on(5) == 5)


  test "inverse":
    let p = newPerm(@[1, 2, 3, 4, 0])
    check($ p.inverse == "[4 0 1 2 3]")


  test "compose":
    let p = newPerm(@[1, 2, 0])
    let q = newPerm(@[0, 3, 4, 1, 2])
    check($ p.compose(q) == "[3 4 0 1 2]")


  test "power":
    let p = newPerm(@[1, 2, 3, 4, 5, 0])
    check($ p.power(2) == "[2 3 4 5 0 1]")


  test "conjugate 0":
    let p = identity(6)
    let q = randomPerm(12)
    check(p.conjugate(q).isIdentity == true)

  test "conjugate 0a":
    let p = randomPerm(6)
    let q = identity(8)
    check(p.conjugate(q) == p)

  test "conjugate 1":
    let p = newPerm(@[1, 2, 0])
    let q = newPerm(@[0, 3, 4, 1, 2])
    check($ p.conjugate(q) == "[3 1 2 4 0]")

  test "conjugate 2":
    let p = newPerm(@[4, 2, 0, 1, 3])
    let q = newPerm(@[1, 2, 0])
    check($ p.conjugate(q) == "[1 4 0 2 3]")


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
    check(p.signature == @[0])
    check(p.sign == 1)
    check(p.order == 1)

  test "signature 1":
    let p = newPerm(@[0])
    check(p.signature == @[0, 1])
    check(p.sign == 1)
    check(p.order == 1)

  test "signature 2":
    let p = newPerm(@[1, 0])
    check(p.signature == @[0, 0, 1])
    check(p.sign == -1)
    check(p.order == 2)
    check(p.orderToCycle(2) == 1)

  test "signature 4":
    let p = newPerm(@[1, 0, 3, 2])
    check(p.signature == @[0, 0, 2, 0, 0])
    check(p.sign == 1)
    check(p.order == 2)
    check(p.orderToCycle(2) == -1)

  test "signature 5a":
    let p = newPerm(@[1, 0, 3, 2, 4])
    check(p.signature == @[0, 1, 2, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 2)

  test "signature 5c":
    let p = newPerm(@[1, 0, 3, 4, 2])
    check(p.signature == @[0, 0, 1, 1, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)
    check(p.orderToCycle(2) == 3)
    check(p.orderToCycle(3) == 2)

  test "signature 5d":
    let p = newPerm(@[0, 1, 3, 4, 2])
    check(p.signature == @[0, 2, 0, 1, 0, 0])
    check(p.sign == 1)
    check(p.order == 3)
    check(p.orderToCycle(3) == 1)

  test "signature 6a":
    let p = newPerm(@[1, 2, 3, 4, 5, 0])
    check(p.signature == @[0, 0, 0, 0, 0, 0, 1])
    check(p.sign == -1)
    check(p.order == 6)

  test "signature 6b":
    let p = newPerm(@[0, 2, 1, 4, 5, 3])
    check(p.signature == @[0, 1, 1, 1, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)

  test "signature 6c":
    let p = newPerm(@[5, 4, 1, 2, 3, 0])
    check(p.signature == @[0, 0, 1, 0, 1, 0, 0])
    check(p.sign == 1)
    check(p.order == 4)
    check(p.orderToCycle(4) == -1)

  test "signature 7":
    let p = newPerm(@[1, 0, 3, 4, 2, 6, 7, 8, 9, 5])
    check(p.signature == @[0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 30)
    check(p.orderToCycle(2) == 15)
    check(p.orderToCycle(2, 10) == -1)


  test "parseCycles invalid":
    expect PError:
      discard parseCycles("(1 2 3 0)")
    expect PError:
      discard parseCycles("(1 2)(2, 3)")
    expect PError:
      discard parseCycles("(1, 2, 65537)")


  test "parseCycles 0":
    let p = parseCycles("")
    check($ p == "[]")

  test "parseCycles 1":
    let p = parseCycles("")
    check($ p == "[]")

  test "parseCycles 2":
    let p = parseCycles("( )( ( )(")
    check($ p == "[]")

  test "parseCycles 3":
    let p = parseCycles("(1)")
    check($ p == "[0]")

  test "parseCycles 4":
    let p = parseCycles("(1,2)")
    check($ p == "[1 0]")

  test "parseCycles 5":
    let p = parseCycles("(3,5)")
    check($ p == "[0 1 4 3 2]")

  test "parseCycles 6":
    let p = parseCycles("(1, 2) (3, 4) ")
    check($ p == "[1 0 3 2]")

  test "parseCycles 7":
    let p = parseCycles("(1 2)(3 12)(7 16)")
    check($ p == "[1 0 11 3 4 5 15 7 8 9 10 2 12 13 14 6]")

  test "parseCycles 8":
    let p = parseCycles("(1 2 ; 3, 8 ; 7 4 )")
    check($ p == "[1 0 7 6 4 5 3 2]")

  test "parseCycles 9":
    let p = parseCycles("7 9 11 13)(6 10 12 8")
    check($ p == "[0 1 2 3 4 9 8 5 10 11 12 7 6]")


  test "printCycles 0":
    let p = Perm(@[])
    check(p.printCycles == "()")

  test "printCycles 1":
    let p = newPerm(@[])
    check(p.printCycles == "()")

  test "printCycles 2":
    let p = newPerm(@[0])
    check(p.printCycles == "()")

  test "printCycles 3":
    let p = identity(7)
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
