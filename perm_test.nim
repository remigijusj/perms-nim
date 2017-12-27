import perm, unittest

const W = 8

suite "constructors":
  test "direct":
    let p: Perm[W] = (W, [1'u8, 0'u8, 2'u8, 3'u8, 4'u8, 5'u8, 6'u8, 7'u8])
    check(p == [1, 0, 2, 3, 4, 5, 6, 7])

  test "newPerm invalid":
    var p: Perm[W]
    expect PermError:
      p = W.newPerm(@[1, 2, 3, 4, 5, 6, 7])
    expect PermError:
      p = W.newPerm(@[0, 0, 1])
    expect PermError:
      p = W.newPerm(@[-2, 0, 1])
    expect PermError:
      p = W.newPerm(@[0, 2, 3])
    expect PermError:
      p = W.newPerm(@[3, 2, 3])

  test "identity valid":
    let p = W.identity
    check(p.p.len == 8)
    check(p == [0, 1, 2, 3, 4, 5, 6, 7])

  test "randomPerm":
    let p = W.randomPerm
    check(p.p.len == 8)

  test "randomCycle":
    let c = W.randomCycle(6)
    check(c.c.len == 6)
    check(c.toPerm.signature.s[6] == 1)

  test "toPerm 0":
    let c = W.newCycle(@[1, 2, 3])
    check(c.toPerm == [0, 2, 3, 1, 4, 5, 6, 7])

  test "toPerm 1":
    expect PermError:
      discard W.newCycle(@[3])


suite "basics":
  test "isZero 0":
    let p = W.newPerm(@[])
    check(p.isZero == false)

  test "isZero 1":
    let p = W.newPerm(@[0, 1])
    check(p.isZero == false)

  test "isZero 2":
    var p: Perm[W] # = [0, 0, 0, 0, 0, 0, 0, 0]
    check(p.isZero == true)


  test "isIdentity 0":
    let p = W.newPerm(@[])
    check(p.isIdentity == true)

  test "isIdentity 1":
    let p = W.newPerm(@[0, 1])
    check(p.isIdentity == true)

  test "isIdentity 2":
    let p = W.newPerm(@[0, 1, 2])
    check(p.isIdentity == true)

  test "isIdentity 3":
    let p = W.newPerm(@[1, 0])
    check(p.isIdentity == false)

  test "isIdentity 4":
    let p = W.newPerm(@[0, 1, 3, 2])
    check(p.isIdentity == false)


  test "isInvolution 0":
    let p = W.newPerm(@[])
    check(p.isInvolution == true)

  test "isInvolution 1":
    let p = W.newPerm(@[1, 0])
    check(p.isInvolution == true)

  test "isInvolution 2":
    let p = W.newPerm(@[1, 2, 0])
    check(p.isInvolution == false)

  test "isInvolution 3":
    let p = W.newPerm(@[1, 0, 3, 2])
    check(p.isInvolution == true)

  test "isInvolution 3":
    let p = W.newPerm(@[1, 2, 3, 0])
    check(p.isInvolution == false)


  test "isEqual 0":
    let p = W.newPerm(@[])
    check(p == p)

  test "isEqual 1":
    let p = W.newPerm(@[0])
    check(p == p)

  test "isEqual 2":
    let p = W.newPerm(@[0, 1])
    let q = W.newPerm(@[0, 1, 2])
    check(p == q)
    check(q == p)

  test "isEqual c0":
    let c = W.newCycle(@[1, 2, 3])
    let d = W.newCycle(@[2, 3, 1])
    check(c == d)

  test "isEqual c1":
    let c = W.newCycle(@[3, 1, 2])
    check(c == @[1, 2, 3])


suite "actions":
  test "inverse":
    let p = W.newPerm(@[1, 2, 3, 4, 0])
    check(p.inverse == [4, 0, 1, 2, 3, 5, 6, 7])


  test "compose 0":
    let p = W.newPerm(@[1, 2, 0])
    let q = W.newPerm(@[0, 3, 4, 1, 2])
    check(p * q == [3, 4, 0, 1, 2, 5, 6, 7])

  test "compose 1":
    let p = W.newPerm(@[1, 2, 0])
    let q = W.newPerm(@[0, 3, 4, 1, 2])
    let i = W.identity
    check(compose(p, i, q) == [3, 4, 0, 1, 2, 5, 6, 7])
    check(compose(p, q, i) == [3, 4, 0, 1, 2, 5, 6, 7])
    check(compose(@[p, q, i]) == [3, 4, 0, 1, 2, 5, 6, 7])


  test "power":
    let p = W.newPerm(@[1, 2, 3, 4, 5, 0])
    check(p.power(2) == [2, 3, 4, 5, 0, 1, 6, 7])


  test "conjugate 0":
    let p = W.identity
    let q = W.randomPerm
    check(p.conjugate(q).isIdentity == true)

  test "conjugate 0a":
    let p = W.randomPerm
    let q = W.identity
    check(p.conjugate(q) == p)

  test "conjugate 1":
    let p = W.newPerm(@[1, 2, 0])
    let q = W.newPerm(@[0, 3, 4, 1, 2])
    check(p.conjugate(q) == [3, 1, 2, 4, 0, 5, 6, 7])

  test "conjugate 2":
    let p = W.newPerm(@[4, 2, 0, 1, 3])
    let q = W.newPerm(@[1, 2, 0])
    check(p.conjugate(q) == [1, 4, 0, 2, 3, 5, 6, 7])

  test "conjugate c0":
    let c = W.newCycle(@[0, 1, 2, 3])
    let q = W.newPerm(@[4, 3, 2, 1, 0])
    check(c.conjugate(q) == @[1, 4, 3, 2])

  test "conjugate c1":
    let c = W.newCycle(@[0, 1, 2])
    let q = W.newPerm(@[2, 0, 1, 4, 5, 3])
    check(c.conjugate(q) == c)

  test "conjugate c2":
    let c = W.newCycle(@[0, 1, 2])
    let q = W.newPerm(@[0, 1, 2, 4, 3])
    check(c.conjugate(q) == c)

  test "conjugate c2":
    let c = W.newCycle(@[0, 4, 7])
    let q = W.randomPerm
    check(c.conjugate(q).toPerm == c.toPerm.conjugate(q))


suite "signature":
  test "signature 0":
    let p = W.newPerm(@[])
    check(p.signature.s == [0, 8, 0, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 1)

  test "signature 1":
    let p = W.newPerm(@[0])
    check(p.signature.s == [0, 8, 0, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 1)

  test "signature 2":
    let p = W.newPerm(@[1, 0])
    check(p.signature.s == [0, 6, 1, 0, 0, 0, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 2)
    check(p.orderToCycle(2) == 1)

  test "signature 4":
    let p = W.newPerm(@[1, 0, 3, 2])
    check(p.signature.s == [0, 4, 2, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 2)
    check(p.orderToCycle(2) == -1)

  test "signature 5a":
    let p = W.newPerm(@[1, 0, 3, 2, 4])
    check(p.signature.s == [0, 4, 2, 0, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 2)

  test "signature 5c":
    let p = W.newPerm(@[1, 0, 3, 4, 2])
    check(p.signature.s == [0, 3, 1, 1, 0, 0, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)
    check(p.orderToCycle(2) == 3)
    check(p.orderToCycle(3) == 2)

  test "signature 5d":
    let p = W.newPerm(@[0, 1, 3, 4, 2])
    check(p.signature.s == [0, 5, 0, 1, 0, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 3)
    check(p.orderToCycle(3) == 1)

  test "signature 6a":
    let p = W.newPerm(@[1, 2, 3, 4, 5, 0])
    check(p.signature.s == [0, 2, 0, 0, 0, 0, 1, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)

  test "signature 6b":
    let p = W.newPerm(@[0, 2, 1, 4, 5, 3])
    check(p.signature.s == [0, 3, 1, 1, 0, 0, 0, 0, 0])
    check(p.sign == -1)
    check(p.order == 6)

  test "signature 6c":
    let p = W.newPerm(@[5, 4, 1, 2, 3, 0])
    check(p.signature.s == [0, 2, 1, 0, 1, 0, 0, 0, 0])
    check(p.sign == 1)
    check(p.order == 4)
    check(p.orderToCycle(4) == -1)


suite "cycles":
  test "parsePerm invalid 0":
    expect PermError:
      discard W.parsePerm("(1 2 3 0)")

  test "parsePerm invalid 1":
    expect PermError:
      discard W.parsePerm("(1 2)(2, 3)")

  test "parsePerm invalid 2":
    expect PermError:
      discard W.parsePerm("(1, 2, 65537)")


  test "parsePerm 0":
    let p = W.parsePerm("")
    check(p == [0, 1, 2, 3, 4, 5, 6, 7])

  test "parsePerm 1":
    let p = W.parsePerm("")
    check(p == [0, 1, 2, 3, 4, 5, 6, 7])

  test "parsePerm 2":
    let p = W.parsePerm("( )( ( )(")
    check(p == [0, 1, 2, 3, 4, 5, 6, 7])

  test "parsePerm 3":
    let p = W.parsePerm("(1)")
    check(p == [0, 1, 2, 3, 4, 5, 6, 7])

  test "parsePerm 4":
    let p = W.parsePerm("(1,2)")
    check(p == [1, 0, 2, 3, 4, 5, 6, 7])

  test "parsePerm 5":
    let p = W.parsePerm("(3,5)")
    check(p == [0, 1, 4, 3, 2, 5, 6, 7])

  test "parsePerm 6":
    let p = W.parsePerm("(1, 2) (3, 4) ")
    check(p == [1, 0, 3, 2, 4, 5, 6, 7])

  test "parsePerm 7":
    let p = W.parsePerm("(1 2)(3 8)(7 4)")
    check(p == [1, 0, 7, 6, 4, 5, 3, 2])

  test "parsePerm 8":
    let p = W.parsePerm("(1 2 ; 3, 8 ; 7 4 )")
    check(p == [1, 0, 7, 6, 4, 5, 3, 2])

  test "parsePerm 9":
    let p = W.parsePerm("1 2 3 4)(5 6 7 8")
    check(p == [1, 2, 3, 0, 5, 6, 7, 4])


  test "printCycles 1":
    let p = W.newPerm(@[])
    check(p.printCycles == "()")

  test "printCycles 2":
    let p = W.newPerm(@[0])
    check(p.printCycles == "()")

  test "printCycles 3":
    let p = W.identity
    check(p.cycles[0].c.len == 0)
    check(p.printCycles == "()")

  test "printCycles 4":
    let p = W.newPerm(@[1, 2, 3, 4, 5, 0])
    check(p.cycles[0] == @[0, 1, 2, 3, 4, 5])
    check(p.printCycles == "(1, 2, 3, 4, 5, 6)")

  test "printCycles 5":
    let p = W.newPerm(@[1, 2, 0, 4, 5, 3])
    check(p.cycles[0] == @[0, 1, 2])
    check(p.cycles[1] == @[3, 4, 5])
    check(p.printCycles == "(1, 2, 3)(4, 5, 6)")

  test "printCycles 6":
    let p = W.newPerm(@[5, 4, 3, 2, 1, 0])
    check(p.printCycles == "(1, 6)(2, 5)(3, 4)")

  test "printCycles 7":
    let p = W.newPerm(@[0, 1, 4, 3, 2, 5])
    check(p.printCycles == "(3, 5)")


  test "splitCycles2 0":
    let p = W.newPerm(@[1, 2, 3, 4, 5, 0])
    let s = @[@[0, 1], @[0, 2], @[0, 3], @[0, 4], @[0, 5]]
    for i, c in p.splitCycles(2):
      check(c == s[i])

  test "splitCycles2 1":
    let p = W.parsePerm("(1 2)(3 8)(7 4)")
    let s = @[@[0, 1], @[2, 7], @[3, 6]]
    for i, c in p.splitCycles(2):
      check(c == s[i])

  test "splitCycles2 2":
    let p = W.newPerm(@[1, 2, 0, 4, 5, 3])
    let s = @[@[0, 1], @[0, 2], @[3, 4], @[3, 5]]
    for i, c in p.splitCycles(2):
      check(c == s[i])

  test "splitCycles3 0":
    let p = W.newPerm(@[1, 2, 0, 4, 5, 3])
    let s = @[@[0, 1, 2], @[3, 4, 5]]
    for i, c in p.splitCycles(3):
      check(c == s[i])

  test "splitCycles3 1":
    let p = W.parsePerm("(1 2 4 8)(3 5)")
    let s = @[@[0, 1, 3], @[0, 7, 2], @[0, 4, 2]]
    for i, c in p.splitCycles(3):
      check(c == s[i])

  test "splitCycles3 2":
    let p = W.parsePerm("(1 7)(3 2 6)(5 8)") # [0 6][1 5 2][4 7]
    let s = @[@[1, 5, 2], @[0, 6, 4], @[0, 7, 4]]
    for i, c in p.splitCycles(3):
      check(c == s[i])

  test "splitCycles3 3":
    expect PermError:
      let p = W.parsePerm("(1 2)(3 8)(7 4)")
      discard p.splitCycles(3)
    expect PermError:
      let q = W.parsePerm("(8 1)")
      discard q.splitCycles(3)
