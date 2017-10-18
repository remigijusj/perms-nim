# Solution for Dailyprogrammer [2017-10-18] Challenge #336 [Intermediate] Repetitive Rubik's Cube
# https://www.reddit.com/r/dailyprogrammer/comments/776lcz/20171018_challenge_336_intermediate_repetitive/

import "../perm", "../permbase"
import nre, tables
from strutils import splitLines

const W = 48
discard newSeq[Perm[W]](0) # hack to ensure necessary static types


# -------- encoding by faces --------
#              1  2  3
#              4  U  5
#              6  7  8
# 
#   9 10 11   17 18 19   25 26 27   33 34 35
#  12  L 13   20  F 21   28  R 29   36  B 37
#  14 15 16   22 23 24   30 31 32   38 39 40
# 
#             41 42 43
#             44  D 45
#             46 47 48

const Rubik = """
F: (17 19 24 22)(18 21 23 20)(6 25 43 16)(7 28 42 13)(8 30 41 11)
B: (33 35 40 38)(34 37 39 36)(1 14 48 27)(2 12 47 29)(3 9 46 32)
U: (1 3 8 6)(2 5 7 4)(17 9 33 25)(18 10 34 26)(19 11 35 27)
D: (41 43 48 46)(42 45 47 44)(22 30 38 14)(23 31 39 15)(24 32 40 16)
L: (9 11 16 14)(10 13 15 12)(17 41 40 1)(20 44 37 4)(22 46 35 6)
R: (25 27 32 30)(26 29 31 28)(19 3 38 43)(21 5 36 45)(24 8 33 48)
"""


proc printPeriod(input: string): void =
  let rubik = W.parseBase(Rubik)
  var perm = W.identity
  for item in input.findIter(re"([FBUDLR])(['2])?"):
    var move = rubik.permByName(item.captures[0]).get
    case item.captures[1]
    of "'":
      move = move.inverse
    of "2":
      move = move * move
    perm = perm * move
  echo perm.order


printPeriod "R"
printPeriod "R F2 L' U D B2"
printPeriod "R' F2 B F B F2 L' U F2 D R2 L R' B L B2 R U"
