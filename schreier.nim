import permgroup, options

from sequtils import allIt

## Schreier-Sims algorithm to compute BSGS and related algorithms.

# Breadth-first search to determine the orbit of alpha point and transversal.
# For each point it gives:
#   an optional coset representative (perm moving alpha to that point).
proc orbitTransversal*[N: static[int]](gens: GroupGens[N], alpha: int): array[N, Option[Perm[N]]] =
  var old_level: seq[int]
  var new_level: seq[int] = @[alpha]

  result[alpha] = some(N.identity)

  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for x in old_level:
      for item in gens:
        let y = int(item.perm[x])
        if result[y].isNone:
          result[y] = some(result[x].get * item.perm)
          new_level.add(y)


# Breadth-first search to determine the orbit of alpha point and transversal.
# For each point it gives:
#   an optional tuple (index of generator, preimage under that perm).
proc schreierVector*[N: static[int]](gens: GroupGens[N], alpha: int): array[N, Option[tuple[idx: int, pre: int]]] =
  var old_level: seq[int]
  var new_level: seq[int] = @[alpha]

  result[alpha] = some((idx: -1, pre: -1))

  while new_level.len > 0:
    swap(new_level, old_level)
    new_level = @[]
    for x in old_level:
      for i, item in gens:
        let y = int(item.perm[x])
        if result[y].isNone:
          result[y] = some((idx: i, pre: x))
          new_level.add(y)


# Yields stabilizator generators by Schreier lemma.
# TODO: along with transversal / schreier vector? -> orbitTransversalStabilizer
# TODO: deduplicate (keep dict)
iterator stabilizator*[N: static[int]](gens: GroupGens[N], alpha: int): Perm[N] =
  let reps = orbitTransversal(gens, alpha)
  for i, rep in reps:
    if rep.isSome:
      for item in gens:
        let rep1 = reps[item.perm[i]]
        let perm = rep.get * item.perm * rep1.get.inverse
        if not perm.isIdentity:
          yield perm


# Return true if the generated group is transitive (has single orbit)
proc isTransitive*[N: static[int]](gens: GroupGens[N]): bool =
  result = orbitTransversal(gens, 0).allIt(it.isSome)
