import "../perm", "../permbase"
from random import randomize

const W = 8

debug = false

proc rnd(seed: int): void =
  randomize(seed)
  let base = W.randomBase(3)
  let perm = W.randomPerm
  let norm = base.normalize
  echo base.printBase
  echo "X: ", perm.printCycles

  let list = norm.factorize(perm, false, 9)
  echo "LIST: ", list
  echo "SEQ: ", norm.factorNames(list)
  echo "CON: ", norm.factorNames(list, "-", true)
  echo "EQL: ", (norm.composeSeq(list) == perm)
  echo "LEN: ", list.len


# 1235: ok
rnd(12345)

# 1234: n/f
# A: (1, 8, 3, 2, 4, 7, 6)
# B: (1, 6, 5, 2, 4)(3, 8, 7)
# C: (1, 2, 5)(3, 6, 8, 4)
# X: (1, 5, 8, 7, 4, 6)
