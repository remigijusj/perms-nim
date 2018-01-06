import "../permgroup"
import nre

from system import slurp
from strscans import scanf
from strutils import splitLines, replace, `%`

# choose group definition file
const GroupDef = slurp "../groups/G_S3wrS5" # S3 wr S5

static:
  var degree: int
  discard scanf(GroupDef, "n$i", degree)

const W = degree
discard newSeq[Perm[W]](0) # ~~~


# Parse group definition given by this format:
# nXX - group degree
# a b,c d ... - generator specified in cycle format e.g. (a b)(c d ...
proc parseGroupDef: GroupGens[W] =
  result = newSeq[Generator[W]]()
  var name = 'A'
  for line in splitLines(GroupDef):
    let m = line.match(re"^\d+([ ;,]\d+)*")
    if m.isSome:
      result.add(($name, W.parsePerm(line.replace(",", ";")), -1))
      name = name.succ


# Search minimum number of moved point achieved by branching search upto # of levels.
# Print moving number, level where found, permutation realizing it.
proc searchMin(gens: GroupGens[W], levels = 0): string =
  var memo: tuple[move: int, level: int, perm: Perm[W]] = (W, -1, W.identity)

  for perm, i, level in gens.multiSearch(levels):
    let move = W - perm.signature[1]
    if move < memo.move:
      echo((move: move, level: level, i: i, perm: perm.printCycles))
      let idx = decodeIndex(i, level, gens.len)
      let res = composeSeq(gens, idx).printCycles == perm.printCycles
      echo((idx: idx, res: res))
      memo = (move, level, perm)

  result = "move: $1, level: $2, perm: $3" % [$ memo.move, $ memo.level, memo.perm.printCycles]


proc main: void =
  let gens = parseGroupDef()
  echo gens.printGens
  echo gens.searchMin(10)


main()
