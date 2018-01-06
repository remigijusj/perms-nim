import permgroup, unittest

from sequtils import toSeq
from options import get, isNone

const W = 8

suite "permgroup":
  test "basics":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    check(gens.len == 2)
    check(gens.printGens == data)

  test "random":
    let gens = W.randomGens(3)
    check(gens.len == 3)
    check(gens[0].name == "A")
    check(gens[1].name == "B")
    check(gens[2].name == "C")

  test "permByName":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    check(gens.permByName("B").get == W.parsePerm("(3, 4)"))
    check(gens.permByName("C").isNone)

  test "perms":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    check(gens.perms == @[W.parsePerm("(1, 2, 3)"), W.parsePerm("(3, 4)")])

  test "normalize 0":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data).normalize
    check(gens.len == 3)
    check(gens[2].name == "A'")
    check(gens[2].inverse == 0)

  test "normalize 1":
    let data = "A: (1, 2)\nB: (3, 4)"
    let gens = W.parseGens(data).normalize
    check(gens.len == 2)
    check(gens[0].inverse == 0)
    check(gens[1].inverse == 1)

  test "normalize 2":
    let data = "A: (1, 2, 4)\nB: (3, 1)\nX: (5, 4, 3, 2, 1)"
    let gens = W.parseGens(data).normalize
    check(gens.len == 5)
    check(gens[0].inverse == 3)
    check(gens[1].inverse == 1)
    check(gens[2].inverse == 4)
    check(gens[3].inverse == 0)
    check(gens[4].inverse == 2)
    check(gens[3].name == "A'")
    check(gens[4].name == "X'")
    check(gens[3].perm.inverse == gens[0].perm)
    check(gens[4].perm.inverse == gens[2].perm)

  test "composeSeq":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let gens = W.parseGens(data)
    check(gens.composeSeq(newSeq[int]()) == W.identity)
    check(gens.composeSeq(@[0]) == gens[0].perm)
    check(gens.composeSeq(@[1]) == gens[1].perm)
    check(gens.composeSeq(@[0, 1, 0]) == [0, 1, 2, 7, 3, 4, 5, 6])
    check(gens.composeSeq(@[1, 0, 1]) == [6, 5, 0, 4, 7, 3, 2, 1])

  test "factorNames":
    let data = "A: (1 8)(2 7)(3 6)(4 5)\nB: (1 2 3 4 5)"
    let gens = W.parseGens(data).normalize
    check(gens.factorNames(newSeq[int]()) == "")
    check(gens.factorNames(@[0]) == "A")
    check(gens.factorNames(@[1]) == "B")
    check(gens.factorNames(@[0, 1, 2]) == "ABB'")
    check(gens.factorNames(@[1, 0, 1], ",") == "B,A,B")
    check(gens.factorNames(@[0, 0, 0, 1, 2, 2], "-", true) == "A3-B-B'2")


suite "specific":
  test "multiply":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    var list = newSeq[Perm[W]](4)
    for perm, i in gens.perms.multiply(gens):
      list[i] = perm
    check(list[0].printCycles == "(1, 3, 2)")
    check(list[1].printCycles == "(1, 2, 4, 3)")
    check(list[2].printCycles == "(1, 2, 3, 4)")
    check(list[3].printCycles == "()")

  test "conjugate":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    var seed = W.parsePerm("(1, 4)(2, 3)").cycles
    check(seed[0] == W.newCycle(@[0, 3]))
    check(seed[1] == W.newCycle(@[1, 2]))
    var list = toSeq(seed.conjugate(gens))
    check(list.len == 4)
    check(list[0] == (W.newCycle(@[1, 3]), 0, 0))
    check(list[1] == (W.newCycle(@[0, 2]), 0, 1))
    check(list[2] == (W.newCycle(@[0, 2]), 1, 0))
    check(list[3] == (W.newCycle(@[1, 3]), 1, 1))

  test "isTransitive 0":
    let data = "A: (1, 2, 4)\nB: (3, 1)"
    let gens = W.parseGens(data)
    check(gens.isTransitive == false)

  test "isTransitive 1":
    let data = "A: (7, 6, 5, 4)\nB: (4, 3, 2)\nC: (1, 2, 8)"
    let gens = W.parseGens(data)
    check(gens.isTransitive == true)

  test "orbitTransversal 1":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    let tree = gens.orbitTransversal(1)
    check(tree[0].get == W.newPerm(@[2, 0, 1]))
    check(tree[1].get == W.identity)
    check(tree[2].get == W.newPerm(@[1, 2, 0]))
    check(tree[3].get == W.newPerm(@[1, 3, 0, 2]))
    check(tree[4].isNone)
    check(tree[5].isNone)
    check(tree[6].isNone)
    check(tree[7].isNone)

  test "schreierVector 1":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    let tree = gens.schreierVector(1)
    check(tree[0] == (true, 0, 2))
    check(tree[1] == (true, -1, -1))
    check(tree[2] == (true, 0, 1))
    check(tree[3] == (true, 1, 2))
    check(tree[4] == (false, 0, 0))
    check(tree[5] == (false, 0, 0))
    check(tree[6] == (false, 0, 0))
    check(tree[7] == (false, 0, 0))

  test "stabilizator 1":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    var list = toSeq(gens.stabilizator(1))
    check(list.len == 3)
    check(list[0].printCycles == "(1, 4)")
    check(list[1].printCycles == "(3, 4)")
    check(list[2].printCycles == "(1, 4, 3)")
