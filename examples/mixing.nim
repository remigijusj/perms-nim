import "../perm", "../permbase"
from random import randomize
from strutils import repeat

const W = 9 # world
const Size = 2
const Depth = 10



proc search(base: PermBase, levels = 0): tuple[move: int, perm: Perm] =
  # let length = (5 + base.sign) div 2 # 2 or 3
  result = (W, W.identity)

  for perm, i, level in base.multiSearch(levels):
    # let o = p.orderToCycle(length, W)
    # if o > -1:
    let move = W - perm.signature[1]
    if move < result.move:
      result = (move, perm)


proc rnd(seed: int, depth: int): void =
  randomize(seed)
  let base = W.randomBase(Size)
  let opti = base.search(depth)
  echo base.printBase
  echo "move: ", opti.move, ", perm: ", opti.perm.printCycles


proc distro(max: int, depth: int): array[W+1, int] =
  for seed in countup(1, max):
    randomize(seed)
    let base = W.randomBase(Size)
    let opti = base.search(depth)
    result[opti.move].inc


proc frequencies(cnt, max: int): void =
  let freq = distro(cnt, max)
  for i, c in freq:
    echo i, ": ", c / cnt

  echo "OK: ", (freq[2]+freq[3])/cnt


proc printf(format: cstring): cint {.importc, varargs, nodecl.}


proc mixing(cnt, max: int): void =
  stdout.write "% |"
  for k in 2 .. <W+1:
    discard printf("%4d", k)
  echo "\n--+" & repeat("----", W-1)

  for d in 1 .. <max+1:
    discard printf("%1d |", d)
    let freq = distro(cnt, d)
    for i in 2 .. <W+1:
      discard printf("  %2.0f", (freq[i] / cnt) * 100)
    echo ""



# rnd(2, Depth)
# frequencies(10000, 6)
mixing(10000, Depth)


#[

 % |   2   3   4   5   6   7   8   9
---+--------------------------------
 1 |   0   0   1   3  12  31  40  14
 2 |   0   7  11  15  25  27  13   1
 3 |   7   6  18  25  27  13   4   0
 4 |   7  23  13  29  19   7   1   0
 5 |  16  32  20   8  19   5   0   0
 6 |  19  34  23  12  12   1   0   0
 7 |  31  31  20  10   8   0   0   0
 8 |  31  38  18   9   3   0   0   0
 9 |  35  37  18   8   2   0   0   0
10 |  39  42  15   3   1   0   0   0

 % |   2   3   4   5   6   7   8
---+----------------------------
 1 |   0   1   3  12  30  41  13
 2 |   0  14  20  23  28  13   1
 3 |  11   9  33  27  17   3   0
 4 |  11  28  23  25  11   1   0
 5 |  30  33  17  11   9   0   0
 6 |  34  36  20   8   3   0   0
 7 |  34  36  21   7   2   0   0
 8 |  35  45  17   2   1   0   0
 9 |  41  41  16   1   1   0   0
10 |  48  42   9   0   1   0   0


% |   2   3   4   5   6   7
--+------------------------
1 |   1   2  10  29  43  16
2 |   1  25  31  26  15   2
3 |  16  12  44  22   6   0
4 |  16  36  31  15   2   0
5 |  35  31  24   9   1   0
6 |  41  34  21   3   1   0
7 |  43  36  19   2   1   0
8 |  44  44  11   1   1   0
9 |  52  39   8   0   1   0

% |   2   3   4   5   6
--+--------------------
1 |   4  11  32  40  14
2 |   6  41  39  12   2
3 |  36  18  40   6   0
4 |  38  28  32   1   0
5 |  40  28  31   0   0
6 |  51  28  20   0   0
7 |  55  26  18   0   0
8 |  57  26  16   0   0
9 |  62  22  15   0   0

% |   2   3   4   5
--+----------------
1 |  16  28  43  14
2 |  23  51  25   2
3 |  52  30  18   1
4 |  55  29  14   1
5 |  58  27  14   1
6 |  61  24  14   1
7 |  64  21  14   1
8 |  64  21  14   1

]#
