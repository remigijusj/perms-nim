import algorithm, math, re, strutils, unsigned

randomize()


const N = 8
type P = uint8

type Perm* = array[N, P]

type PermErr* = object of Exception


# ------ basics ------

proc valid*(p: Perm): bool =
  var check = p
  check.sort(system.cmp[P])

  for i in 0 .. <N:
    if int(check[i]) != i:
      return false

  return true


proc newPerm*(data: seq[int]): Perm =
  if data.len > N:
    raise PermErr.newException("seq length mismatch")
  for i in 0 .. <data.len:
    result[i] = P(data[i])
  for i in data.len .. <N:
    result[i] = P(i)
  if not result.valid:
    raise PermErr.newException("seq invalid")


proc identity*: Perm =
  for i in 0 .. <N:
    result[i] = P(i)


proc randomPerm*: Perm =
  result = identity()
  for i in countdown(result.high, 0):
    let j = random(i + 1)
    swap(result[i], result[j])


proc `$`*(d: P): string =
  $(int(d)+1)


proc `$`*(p: Perm): string =
  result = "["
  for i, e in p:
    if i > 0:
      result.add " "
    result.add($ int(e))
  result.add "]"


proc size*(p: Perm): int = N


proc inverse*(p: Perm): Perm =
  for i in 0 .. <N:
    result[int(p[i])] = P(i)


proc compose*(p: Perm, q: Perm): Perm =
  for i in 0 .. <N:
    result[i] = q[int(p[i])]


proc power*(p: Perm, n: int): Perm =
  if n == 0:
    return identity()

  if n < 0:
    return p.inverse.power(-n)

  for i in 0 .. <N:
    var k = i
    for j in 0 .. <n:
      k = int(p[k])

    result[i] = P(k)


proc conjugate*(p: Perm, q: Perm): Perm =
  for i in 0 .. <N:
    var j = int(q[i])
    var k = int(p[i])
    result[j] = q[k]


proc isIdentity*(p: Perm): bool =
  for i, v in p:
    if int(v) != i:
      return false

  return true


#proc `==`*(x: Pt, y: Pt): bool = uint(x) == uint(y)

proc `==`*(p: Perm, q: Perm): bool =
  for i in 0 .. <N:
    if int(p[i]) != int(q[i]):
      return false

  return true


# ------ signature ------

proc gcd(a, b): auto =
  var
    t = 0
    a = a
    b = b
  while b != 0:
    t = a
    a = b
    b = t %% b
  a


proc lcm(a, b): auto =
  a * (b div gcd(a, b))


proc signature*(p: Perm): seq[int] =
  let size = N
  result = newSeq[int](size+1)

  var marks = newSeq[bool](size)
  var m = 0
  while true:
    # find next unmarked
    while m < size and marks[m]:
      inc(m)

    if m == size:
      break

    # trace a cycle
    var cnt = 0
    var j = m
    while not marks[j]:
      marks[j] = true
      inc(cnt)
      j = int(p[j])

    inc(result[cnt])


proc sign*(p: Perm): int =
  let sgn = p.signature
  var sum = 0
  for i in countup(2, N, 2):
    sum += sgn[i]

  if sum %% 2 == 0:
    return 1
  else:
    return -1


# TODO: binary reduce, multi-lcm algorithm
# TODO: control overflow of lcm
proc order*(p: Perm): int =
  # if N < 2:
  #   return 1

  let sgn = p.signature
  result = 1
  for i, v in sgn:
    if i >= 2 and v > 0:
      result = lcm(result, i)


proc orderToCycle*(p: Perm, n: int, max = 0): int =
  if n < 2:
    return -1

  let sgn = p.signature
  # there must be unique n-cycle
  if sgn[n] != 1:
    return -1

  result = 1
  for i, v in sgn:
    if gcd(i, n) > 1:
      # no cycles which could reduce to n
      if i != n and v > 0:
        return -1
    else:
      # contributes to power
      if i >= 2 and v > 0:
        result = lcm(result, i)
        if max > 0 and result > max:
          return -1


# ------ cycles ------

# TODO: optimize, perhaps no re?
# scan integers, liberally
# ex: (1 2)(3, 8)(7 4)() -> []int{-1, 0, 1, -1, 2, 7, -1, 6, 3, -1}
proc scanCycleRep(data: string): tuple[parts: seq[int], max: int] =
  var parts = newSeq[int]()
  var max = -1
  for item in data.findAll(re"\d+|[();]+"):
    var part: int
    try:
      part = parseInt(item)
    except ValueError:
      part = -1

    if part == 0:
      raise PermErr.newException("int can't be zero")
    elif part > N:
      raise PermErr.newException("int overflow")
    elif part > 0:
      dec(part)

    parts.add(part)
    if part > max:
      max = part

  # must end in -1
  if parts.len == 0 or parts[parts.len-1] != -1:
    parts.add(-1)

  result.parts = parts
  result.max = max


# build permutation
# ex: []int{-1, 0, 1, -1, 2, 7, -1, 6, 3, -1} -> []Pt{1, 0, 7, 6, 4, 5, 3, 2}
proc buildPermFromCycleRep(rep: tuple[parts: seq[int], max: int]): Perm =
  var perm = identity()

  var first = -1
  var point = -1
  for part in rep.parts:
    if part == -1:
      if first >= 0 and point >= 0:
        if int(perm[point]) != point:
          raise PermErr.newException("integers must be unique")

        perm[point] = P(first)
        first = -1
        point = -1
    else:
      if point == -1:
        first = part
        point = part
      else:
        if int(perm[point]) != point:
          raise PermErr.newException("integers must be unique")

        perm[point] = P(part)
        point = part

  return perm


proc parseCycles*(data: string): Perm =
  buildPermFromCycleRep(scanCycleRep(data))


proc getCycles(p: Perm): seq[seq[P]] =
  let size = N
  var cycles = newSeq[seq[P]]()
  var marks = newSeq[bool](size)
  var m = 0
  while true:
    # find next unmarked
    while m < size and marks[m]:
      inc(m)

    if m == size:
      break

    # construct a cycle
    var cycle = newSeq[P]()
    var j = m
    while not marks[j]:
      marks[j] = true
      cycle.add(P(j))
      j = int(p[j])

    if cycle.len > 1:
      cycles.add(cycle)

  # exceptional case: empty
  if cycles.len == 0:
    let cycle = newSeq[P]()
    cycles.add(cycle)

  return cycles


# TODO: more efficient serialization?
proc printCycles*(p: Perm): string =
  result = ""
  for cycle in p.getCycles:
    result.add "("
    for i, e in cycle:
      if i > 0:
        result.add ", "
      result.add($e)
    result.add ")"
