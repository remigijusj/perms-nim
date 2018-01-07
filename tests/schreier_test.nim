import permgroup, schreier, unittest

from sequtils import toSeq
from options import get, isNone

const W = 8

suite "specific":
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
    check(tree[0].get == (0, 2))
    check(tree[1].get == (-1, -1))
    check(tree[2].get == (0, 1))
    check(tree[3].get == (1, 2))
    check(tree[4].isNone)
    check(tree[5].isNone)
    check(tree[6].isNone)
    check(tree[7].isNone)

  test "stabilizator 1":
    let data = "A: (1, 2, 3)\nB: (3, 4)"
    let gens = W.parseGens(data)
    var list = toSeq(gens.stabilizator(1))
    check(list.len == 3)
    check(list[0].printCycles == "(1, 4)")
    check(list[1].printCycles == "(3, 4)")
    check(list[2].printCycles == "(1, 4, 3)")

  test "isTransitive 0":
    let data = "A: (1, 2, 4)\nB: (3, 1)"
    let gens = W.parseGens(data)
    check(gens.isTransitive == false)

  test "isTransitive 1":
    let data = "A: (7, 6, 5, 4)\nB: (4, 3, 2)\nC: (1, 2, 8)"
    let gens = W.parseGens(data)
    check(gens.isTransitive == true)
