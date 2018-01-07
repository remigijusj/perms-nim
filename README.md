# perms-nim
Permutation group calculations and factorization algorithms implemented in [Nim](https://nim-lang.org). Several modules are provided which can be imported and used independently.

`perm` implements basic permutation calculations. Various constructors and formatting in cycle notation are provided, as well as conjugation, signature and other basic permutation properties.

`permgroup` provides data structures for constructing permutation groups by given generators and calculating various simple properties of such groups.

`kalka` module implements factorization algorithm described in the paper 
["Short expressions of permutations as products and cryptanalysis of the Algebraic Eraser"](https://arxiv.org/abs/0804.0629) by Arkadius Kalka, Mina Teicher and Boaz Tsaban. It is only applicable in the case of full symmetric and alternating groups (S_n, A_n).

`minkwitz` module implements factorization algorithm invented by Torsten Minkwitz, see 
["An Algorithm for Solving the Factorization Problem in Permutation Groups"](http://www.sciencedirect.com/science/article/pii/S0747717198902024).

`schreier` module implements Schreier-Sims algorithm constructing a BSGS - Base and Strong Generators System for a permutation group. Orbit and stabilizator calculations are included.

Check `tests` and `examples` subdirectories for usage scenarios.

## Algorithms

Kalka-Teicher-Tsaban algorithm provides generator expressions of length *O(n^2 log n)* for n generators, which is significantly better than performance of Minkwitz algorithm. 

The shortcoming of this approach is that factorization can only be performed in full symmetric or alternating group (*S_n* or *A_n*).
Otherwise an involution or 3-cycle cannot be found in the first stage of algorithm, and exception will be raised.

See also the book "Permutation group algorithms" by Akos Seress for more information about the topic.

## Applications

Main inspiration for this library was to solve certain permutation-based puzzles (similar to Rubik cube). 
See ["Permutation Puzzles: A Mathematical Perspective"](https://www.sfu.ca/~jtmulhol/math302/notes/302notes.pdf)
for more information.

## Examples

* `mixing.nim` measures average levels in breadth-first search needed to reach permutation with minimum moving points. 
Some results with two generators are included as comments at the bottom.
It may be helpful for tuning the main factorization algorithm heuristic parameters.

* `rubik_periods.nim` shows how to calculate periods of Rubik group permutations given by sequences of generators in standard notation.

* `rubik_mini1.nim` shows a simple factorization in Mini Rubik (Pocket Rubik) group.
