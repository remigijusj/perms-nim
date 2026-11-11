# perms-nim
Permutation group calculations and factorization algorithms implemented in [Nim](https://nim-lang.org). Several modules are provided which can be imported and used independently.

`perm` implements basic permutation calculations. Various constructors and formatting in cycle notation are provided, as well as conjugation, signature and other basic permutation properties.

`permgroup` provides data structures for constructing permutation groups by given generators and calculating various simple properties of such groups.

`kalka` module implements factorization algorithm described in the paper 
["Short expressions of permutations as products and cryptanalysis of the Algebraic Eraser"](https://arxiv.org/abs/0804.0629) by Arkadius Kalka, Mina Teicher and Boaz Tsaban. It is only applicable in the case of full symmetric and alternating groups (S_n, A_n).

`minkwitz` module implements factorization algorithm invented by Torsten Minkwitz, see 
["An Algorithm for Solving the Factorization Problem in Permutation Groups"](http://www.sciencedirect.com/science/article/pii/S0747717198902024).

`schreier` provides orbit transversals, Schreier vectors, stabilizer generators,
and a transitivity test. It does not yet provide a complete BSGS constructor.

Check `tests` and `examples` subdirectories for usage scenarios.

## Algorithms

For degree *n* and a fixed number of random generators, the
Kalka–Teicher–Tsaban paper derives *O(n^2 log n)* expanded word length in a
probabilistic setting, conditional on its Minimal Cycle Conjecture. This is
not a worst-case guarantee for arbitrary generating lists or a universal
performance comparison with Minkwitz.

The shortcoming of this approach is that factorization can only be performed in full symmetric or alternating group (*S_n* or *A_n*).
In a proper subgroup the required single transposition or 3-cycle may not
exist, or its conjugacy orbit may not cover the target's canonical cycle
decomposition. Even for the intended groups, the bounded seed search can fail.
Identity and generator targets are handled directly; A_3/A_4 use both a
3-cycle seed and its inverse to cover the two conjugacy classes.

See also the book "Permutation group algorithms" by Akos Seress for more information about the topic.

## Factorization contracts

Pass valid permutations and a generator list prepared with `normalize` to
`factorizeK`, `buildShortWordsSGS`, and `factorizeM`. Returned indices refer to
that normalized list, including its appended inverses. Image arrays are
zero-based; printed cycle labels are one-based. `p * q` applies `p` first.

`buildShortWordsSGS(gens, base, n, s, w)` processes at most `n` distinct
nonidentity elements in breadth-first order, or stops when the group is
exhausted. This differs from the old repeated-word round count and from the
paper's minimum-round/until-complete stopping rule. `s` and `w` must be positive;
`n` may be zero. The base must contain distinct in-range points. A supplied
base need not be minimal, but it must kill the group for complete factorization.
The returned table can be incomplete: this is a bounded heuristic constructor.

`isValidSGS(table, base)` checks local permutation/transversal invariants only.
Use `isCompleteSGS(gens, base, table)` once after construction to certify word
provenance, complete orbit domains and a trivial terminal stabilizer by exact
Schreier checks. The certificate is more expensive than a local validity check;
it does not assume a known group order or enumerate the group. `quality` is an
all-target word-length bound only for a complete certified table.

`factorizeM` supports partial tables when the particular target can be sifted,
and checks that its output evaluates to the target. Missing entries, nonidentity
residuals or inconsistent words raise `FactorizeError`. A failure on an
uncertified table does not prove nonmembership. Invalid input parameters or
inverse links raise `ValueError`.

`shortWords(gens, maxWords)` enumerates distinct nonidentity elements with
shortest words in the supplied alphabet. Include inverses for symmetric word
length. It retains visited elements and their words, so use a finite cap.
Kalka's separate `multiSearch` still uses word-tree arrays; a large `minlevels`
is not a safe time or memory budget. No large-degree performance claim follows
from the small-instance correctness tests.

## Runtime and tests

Nim's `nre` module requires the PCRE 8 runtime (`libpcre3` on Ubuntu 24.04).
The audit was tested with Nim 2.2.6 on 64-bit Linux. Run each `tests/*_test.nim`
with `nim c -r`, optionally directing `--nimcache` and `-o` to a temporary
directory. `factorization_audit_test.nim` includes edge-case, damaged-certificate,
and table-maintenance regressions.

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
