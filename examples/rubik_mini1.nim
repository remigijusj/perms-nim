import "../permgroup", "../minkwitz"

from sequtils import mapIt

const W = 24

# Mini-Rubik
#
#            U    
#         L  F  R  B
#            D
#
# -------- encoding by faces --------
#           1  2
#           3  4
# 
#   5  6    9 10   13 14   17 18
#   7  8   11 12   15 16   19 20
# 
#          21 22
#          23 24

const MiniRubik = """
F: (9 10 12 11)(3 13 22 8)(4 15 21 6)
B: (17 18 20 19)(1 7 24 14)(2 5 23 16)
U: (1 2 4 3)(9 5 17 13)(10 6 18 14)
D: (21 22 24 23)(11 15 19 7)(12 16 20 8)
L: (5 6 8 7)(9 21 20 1)(11 23 18 3)
R: (13 14 16 15)(10 2 19 22)(12 4 17 24)
"""

const RubikBase = @[0, 1, 2, 3, 20, 21, 22, 23]

proc solve(input: string): void =
  let gens = W.parseGens(MiniRubik).normalize
  let base = RubikBase.mapIt(it.Point)
  let tt = buildShortWordsSGS(gens, base, n=1000, s=8*8, w=100)
  let perm = W.parsePerm(input)
  let fact = factorizeM(gens, base, tt, perm)
  echo factorNames(gens, fact, sep=" ", concise=true)
  echo fact.len, " moves"
  echo composeSeq(gens, fact) == perm

solve "(3, 4)(6, 10)(9, 13)"
