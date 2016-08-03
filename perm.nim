import algorithm, math, random, nre, sequtils, strutils # , unsigned

randomize()

type P = uint8 # point, max 256, TODO: parametrize

type Perm*[N: static[int]] = array[N, P]

# TODO: parameterize by N?, object?
type Cycle* = seq[P]

type Signature*[N: static[int]] = array[N+1, int]

type PermError* = object of Exception


# ------ helpers ------

proc valid(p: Perm): bool =
  var check = p
  check.sort(system.cmp[P])

  for i in 0 .. <p.len:
    if int(check[i]) != i:
      return false

  return true


proc minIndex[T](list: seq[T]): int =
  for i, val in list:
    if val < list[result]:
      result = i


proc rotateSeq[T](list: var seq[T], m: int) =
  reverse(list, 0, m-1)
  reverse(list, m, list.high)
  reverse(list)


proc rotateToMin[T](list: var seq[T]) =
  let m = minIndex(list)
  if m > 0:
    rotateSeq(list, m)


# ------ constructors ------

proc newPerm*(data: seq[int], N: static[int]): Perm[N] =
  if data.len > N:
    raise PermError.newException("seq length mismatch")
  for i in 0 .. <data.len:
    result[i] = P(data[i])
  for i in data.len .. <N:
    result[i] = P(i)
  if not result.valid:
    raise PermError.newException("seq invalid")


# TODO: avoid N?
proc newCycle*(data: seq[int], N: static[int]): Cycle =
  result = newSeq[P](data.len)
  if data.len > N:
    raise PermError.newException("seq length mismatch")
  for i in 0 .. <data.len:
    result[i] = P(data[i])

  rotateToMin(result)


proc identity*(N: static[int]): Perm[N] =
  for i in 0 .. <N:
    result[i] = P(i)


proc randomPerm*(N: static[int]): Perm[N] =
  result = identity(N)
  for i in countdown(result.high, 0):
    let j = random(i + 1)
    swap(result[i], result[j])


# TODO: avoid N
proc toPerm*(c: Cycle, N: static[int]): Perm[N] =
  result = identity(N)
  if c.len < 2:
    return

  var point = c[0]
  for i in 1 .. <c.len:
    result[point] = c[i]
    point = c[i]
  result[point] = c[0]


# ------ basics ------

proc isZero*(p: Perm): bool =
  for i, v in p:
    if int(v) != 0:
      return false

  return true


proc isIdentity*(p: Perm): bool =
  for i, v in p:
    if int(v) != i:
      return false

  return true


# optimized p.inverse == p
proc isInvolution*[N: static[int]](p: Perm[N]): bool = 
  for i in 0 .. <N:
    if p[p[i]] != P(i):
      return false

  return true


#proc `[]`(p: Perm, x: P): P = p[int(x)]


#proc `$`*(d: P): string = $(int(d))


proc `$`*(p: Perm): string =
  result = "["
  for i, e in p:
    if i > 0:
      result.add ", "
    result.add($ int(e))
  result.add "]"


proc `==`*(x: P, y: P): bool = int(x) == int(y)


proc `==`*[N: static[int]](p: Perm[N], q: Perm[N]): bool =
  for i in 0 .. <N:
    if p[i] != q[i]:
      return false

  return true


proc `==`*[N: static[int]](p: Perm[N], q: array[N, int]): bool =
  for i in 0 .. <N:
    if int(p[i]) != int(q[i]):
      return false

  return true


proc `==`*[T](c: Cycle, d: seq[T]): bool =
  if c.len != d.len:
    return false
  for i in 0 .. <c.len:
    if int(c[i]) != int(d[i]):
      return false

  return true


# ------ actions ------

proc inverse*[N: static[int]](p: Perm[N]): Perm[N] =
  for i in 0 .. <N:
    result[p[i]] = P(i)


proc `*`*[N: static[int]](p: Perm[N], q: Perm[N]): Perm[N] =
  for i in 0 .. <N:
    result[i] = q[p[i]]


proc compose*[N: static[int]](list: varargs[Perm[N]]): Perm[N] =
  var p: P
  for i in 0 .. <N:
    p = P(i)
    for perm in list:
      p = perm[p]
    result[i] = p


proc power*[N: static[int]](p: Perm[N], n: int): Perm[N] =
  if n == 0:
    return identity(N)

  if n < 0:
    return p.inverse.power(-n)

  for i in 0 .. <N:
    var k = P(i)
    for j in 0 .. <n:
      k = p[k]

    result[i] = k


proc conjugate*[N: static[int]](p: Perm[N], q: Perm[N]): Perm[N] =
  for i in 0 .. <N:
    var j = q[i]
    var k = p[i]
    result[j] = q[k]


proc conjugate*[N: static[int]](c: Cycle, q: Perm[N]): Cycle =
  result = newSeq[P](c.len)
  for i in 0 .. <c.len:
    result[i] = q[c[i]]

  rotateToMin(result)


# ------ signature ------

proc gcd(a, b: auto): auto =
  var
    t = 0
    a = a
    b = b
  while b != 0:
    t = a
    a = b
    b = t %% b
  a


proc lcm(a, b: auto): auto =
  a * (b div gcd(a, b))


proc signature*[N: static[int]](p: Perm[N]): Signature[N] =
  var marks {.global.}: array[N, bool]
  var sgn {.global.}: array[N+1, int]

  # WARNING: unsafe, size matters
  zeroMem(addr(marks), N)
  zeroMem(addr(sgn), N * 8)

  var m = 0
  while true:
    # find next unmarked
    while m < N and marks[m]:
      inc(m)

    if m == N:
      break

    # trace a cycle
    var cnt = 0
    var j = m
    while not marks[j]:
      marks[j] = true
      inc(cnt)
      j = int(p[j])

    inc(sgn[cnt])

  result = sgn


proc signFrom[N: static[int]](sgn: Signature[N]): int {.noSideEffect.} =
  var sum = 0
  for i in countup(2, N, 2):
    sum += sgn[i]

  if sum %% 2 == 0:
    return 1
  else:
    return -1


proc orderFrom(sgn: Signature, max = 0): int {.noSideEffect.} =
  result = 1
  for i, v in sgn:
    if i >= 2 and v > 0:
      result = lcm(result, i)
      if max > 0 and result > max:
        return -1


proc orderToCycleFrom[N: static[int]](sgn: Signature[N], n: int, max = 0): int {.noSideEffect.} =
  # there must be unique n-cycle
  if n > N or sgn[n] != 1:
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


proc sign*(p: Perm): int = signFrom(p.signature)


proc order*(p: Perm): int = orderFrom(p.signature)


proc orderToCycle*(p: Perm, n: int, max = 0): int =
  if n < 2:
    -1
  else:
    orderToCycleFrom(p.signature, n, max)


# ------ cycles ------

# scan integers, liberally
# ex: (1 2)(3, 8)(7 4)() -> []int{-1, 0, 1, -1, 2, 7, -1, 6, 3, -1}
proc scanCycleRep(data: string, N: static[int]): seq[int] =
  result = newSeq[int]()
  for item in data.findAll(re"\d+|[();]+"):
    var part: int
    try:
      part = parseInt(item)
    except ValueError:
      part = -1

    if part == 0:
      raise PermError.newException("integer must be positive")
    elif part > N:
      raise PermError.newException("integer too large")
    elif part > 0:
      dec(part)

    result.add(part)

  # must end in -1
  if result.len == 0 or result[result.len-1] != -1:
    result.add(-1)


# build permutation
# ex: []int{-1, 0, 1, -1, 2, 7, -1, 6, 3, -1} -> []Pt{1, 0, 7, 6, 4, 5, 3, 2}
proc buildPermFromCycleRep(parts: seq[int], N: static[int]): Perm[N] =
  var perm = identity(N)

  var first = -1
  var point = -1
  for part in parts:
    if part == -1:
      if first >= 0 and point >= 0:
        if int(perm[point]) != point:
          raise PermError.newException("integers must be unique")

        perm[point] = P(first)
        first = -1
        point = -1
    else:
      if point == -1:
        first = part
        point = part
      else:
        if int(perm[point]) != point:
          raise PermError.newException("integers must be unique")

        perm[point] = P(part)
        point = part

  return perm


proc parsePerm*(data: string, N: static[int]): Perm[N] =
  buildPermFromCycleRep(scanCycleRep(data, N), N)


proc cycles*[N: static[int]](p: Perm[N]): seq[Cycle] =
  var cycles = newSeq[seq[P]]()
  var marks: array[N, bool]
  var m = 0
  while true:
    # find next unmarked
    while m < N and marks[m]:
      inc(m)
    if m == N:
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


proc printCycle*(c: Cycle): string =
  result = ""
  result.add "("
  for i, e in c:
    if i > 0:
      result.add ", "
    result.add($(e+1))
  result.add ")"


proc printCycles*(p: Perm): string =
  result = ""
  for c in p.cycles:
    result.add printCycle(c)

# canonical star decomposition
proc splitCycles2(p: Perm): seq[Cycle] =
  result = newSeq[Cycle]()
  for c in p.cycles:
    for j in 1 .. c.high:
      result.add Cycle(@[c[0], c[j]])


# certain 3-cycles decomposition
proc splitCycles3(p: Perm): seq[Cycle] =
  result = newSeq[Cycle]()
  # odd cycles
  for c in p.cycles:
    if c.len mod 2 == 0:
      continue
    for j in countup(1, c.high-1, 2):
      result.add Cycle(@[c[0], c[j], c[j+1]])

  # even cycles
  var r: Cycle
  for c in p.cycles:
    if c.len mod 2 == 1:
      continue
    if r.isNil():
      for j in countup(1, c.high-1, 2):
        result.add Cycle(@[c[0], c[j], c[j+1]])
      r = Cycle(@[c[0], c[c.high]])
    else:
      result.add Cycle(@[r[0], r[1], c[0]])
      result.add Cycle(@[r[0], c[1], c[0]])
      for j in countup(2, c.high-1, 2):
        result.add Cycle(@[c[0], c[j], c[j+1]])
      r = nil

  if not r.isNil():
    raise PermError.newException("no split for odd perm")


# proxy wrapper
proc splitCycles*(p: Perm, length: int): seq[Cycle] =
  if length == 2:
    return splitCycles2(p)
  elif length == 3:
    return splitCycles3(p)
  else:
    raise PermError.newException("unsupported split length")
