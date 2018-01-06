import "../permgroup", "../kalka"

from random import randomize

const W = 8

discard newSeq[Perm[W]](0) # ~~~

debug = false

# With a random generating set and perm, print them, then try to factorize the perm.
# Print various meta-info:
# - list of factor indices
# - sequence of factor names
# - concise sequence of factor names separated by dash
# - equality verification (factorization produces original perm?)
# - length of factorization
proc test_factorize(seed: int): void =
  randomize(seed)
  let gens = W.randomGens(3)
  let perm = W.randomPerm
  let norm = gens.normalize
  echo gens.printGens
  echo "P: ", perm.printCycles

  let list = norm.factorizeK(perm, false, 9)
  echo "LIST: ", list
  echo "SEQ: ", norm.factorNames(list)
  echo "CON: ", norm.factorNames(list, "-", true)
  echo "EQL: ", (norm.composeSeq(list) == perm)
  echo "LEN: ", list.len


test_factorize(12345)

#[

SEED: 1234 -> n/f
A: (1, 8, 3, 2, 4, 7, 6)
B: (1, 6, 5, 2, 4)(3, 8, 7)
C: (1, 2, 5)(3, 6, 8, 4)
P: (1, 5, 8, 7, 4, 6)

SEED: 12345 -> ok
A: (1, 4)(2, 3, 5, 6, 7, 8)
B: (1, 2, 3, 8, 6, 5)
C: (1, 6, 2, 7)(3, 5, 8, 4)
P: (1, 7, 4, 5)(2, 8, 6)
LIST: @[4, 4, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 5, 3, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 2, 1, 5, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2, 4, 3, 3, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 3, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 4, 3]
SEQ: B'B'ABABABABABBBC'A'ABABABABABACBC'ABABABABABCB'A'A'ABABABABABAAABA'ABABABABABAB'A'
CON: B'2-A-B-A-B-A-B-A-B-A-B3-C'-A'-A-B-A-B-A-B-A-B-A-B-A-C-B-C'-A-B-A-B-A-B-A-B-A-B-C-B'-A'2-A-B-A-B-A-B-A-B-A-B-A3-B-A'-A-B-A-B-A-B-A-B-A-B-A-B'-A'
EQL: true
LEN: 72

]#
