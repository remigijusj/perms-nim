# perms-nim
Permutation group calculations and factorization implemented in Nim.

`perm` is a library for basic permutation calculations. Various constructors and printing in cycle notation are provided, 
as well as conjugation, signature and other properties.

`permgroup` library implements permutation factorization algorithm described in the paper 
["Short expressions of permutations as products and cryptanalysis of the Algebraic Eraser"](https://arxiv.org/abs/0804.0629)
by Arkadius Kalka et al. 

See test files `perm_test` and `permgroup_test` for usage scenarios, also `examples` subdirectory.

## Algorithm

The implemented algorithm provides generator expressions of length *O(n^2 log n)* for n generators, which is significantly better
than the more well-known algorithms (see Minkwitz and Schreier-Sims). 

The shortcoming of this approach is that factorization can only be successful in case of sets
generating full symmetric or alternating group (*S_n* or *A_n*).
Otherwise an involution or 3-cycle cannot be found in the first stage of algorithm, and exception is raised.

See book "Permutation group algorithms" by Akos Seress for more information about the topic.

## Applications

Main inspiration for this library was to solve certain permutation-based puzzles (similar to Rubik cube). 
While Rubik itself cannot be solved using this algorithm (the group is not full), many of other puzzles are a good fit. 

See ["Permutation Puzzles: A Mathematical Perspective"](https://www.google.lt/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwj7x4TI_7POAhVLECwKHW_5DWUQFggcMAA&url=http%3A%2F%2Fwww.sfu.ca%2F~jtmulhol%2Fmath302%2Fnotes%2F302notes.pdf&usg=AFQjCNGIwcOVKyWBtkky_6x6jE292BpXTg&sig2=I4kmPzk9JfWV2BNpxGbivw)
for more information.

## Examples

* `mixing.nim` measures average levels in breadth-first search needed to reach permutation with minimum moving points. 
Some results with two generators are included as comments at the bottom.
It might be helpful for tuning the main factorization algorithm heuristic parameters.

