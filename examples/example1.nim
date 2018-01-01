import "../permgroup"

const W = 8

discard newSeq[Perm[W]](0) # ~~~

# (C3 x C3) : C4 -- [0 1 2 3][4 5], [0 2 4]
# Try to obtain given cycles by conjugation from the seed cycle using the generators.
proc test1: void =
  let gens = W.parseGens("A: (1 2 3 4)(5 6)\nB: (1 3 5)")
  let seed = @[W.newCycle(@[1, 3])]
  let target = @[W.newCycle(@[0, 4]), W.newCycle(@[1, 5])]
  echo gens.coverCycles(seed, target)
  echo "---------"

# C2 x C2
# Search 2 levels, try to obtain a cycle of length 4. Results: empty.
proc test2: void =
  let gens = W.parseGens("A: (1 2)(3 4)\nB: (1 3)(2 4)")
  let norm = gens.normalize
  let (list, meta) = norm.searchCycle(4, 2)
  echo((list, meta))
  echo "---------"

# Factorize a perm over given generators. Verify factorization, print factor names sequence.
proc test3: void =
  let gens = W.parseGens("A: (1 2 3 4)(5 6)\nB: (1 3 5)").normalize
  let perm = W.parsePerm("(1 3 5)(2 4 6)")
  let list = gens.factorize(perm)
  echo gens.composeSeq(list) == perm
  echo gens.factorNames(list)
  echo "---------"

test1()
test2()
test3()
