import "../perm", "../permbase"

const W = 8

discard newSeq[Perm[W]](0) # ~~~

# (C3 x C3) : C4
# [0 1 2 3][4 5], [0 2 4]
proc test1: void =
  let base = W.parseBase("A: (1 2 3 4)(5 6)\nB: (1 3 5)")
  let seed = @[W.newCycle(@[1, 3])]
  let target = @[W.newCycle(@[0, 4]), W.newCycle(@[1, 5])]
  echo base.coverCycles(seed, target)
  echo "---------"

# C2 x C2
proc test2: void =
  let base = W.parseBase("A: (1 2)(3 4)\nB: (1 3)(2 4)")
  let norm = base.normalize
  let (list, meta) = norm.searchCycle(4, 2)
  echo (list, meta)
  echo "---------"

proc test3: void =
  let base = W.parseBase("A: (1 2 3 4)(5 6)\nB: (1 3 5)").normalize
  let seed = W.parsePerm("(1 3 5)(2 4 6)")
  let list = base.factorize(seed)
  echo (base.composeSeq(list) == seed)
  echo base.factorNames(list)
  echo "---------"

test1()
test2()
test3()
