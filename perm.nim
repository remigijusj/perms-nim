from algorithm import sort, reverse
from nre       import re, findAll
from random    import random, randomize
from strutils  import parseInt

randomize()

type World* = int

type Point* = uint8 # TODO: static

type Perm*[N: static[int]] = tuple
  deg: int
  p: array[N, Point]

type Cycle*[N: static[int]] = tuple
  deg: int
  c: seq[Point]

type Signature*[N: static[int]] = tuple
  deg: int
  s: array[N+1, int]

type PermError* = object of Exception


# ------ helpers ------

proc valid(p: Perm): bool =
  var check = p.p
  check.sort(system.cmp[Point])

  for i in 0 .. <p.p.len:
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

proc newPerm*(N: static[int], data: seq[int]): Perm[N] =
  if data.len > N:
    raise PermError.newException("seq length mismatch")
  for i in 0 .. <data.len:
    result.p[i] = Point(data[i])
  for i in data.len .. <N:
    result.p[i] = Point(i)
  if not result.valid:
    raise PermError.newException("seq invalid")


proc newCycle*(N: static[int], data: seq[int]): Cycle[N] =
  if data.len > N or data.len < 2:
    raise PermError.newException("seq length is invalid")
 
  result.c = newSeq[Point](data.len)
  for i in 0 .. <data.len:
    result.c[i] = Point(data[i])

  rotateToMin(result.c)


proc identity*(N: static[int]): Perm[N] =
  for i in 0 .. <N:
    result.p[i] = Point(i)


# Knuth shuffle
proc randomPerm*(N: static[int]): Perm[N] =
  result = N.identity
  for i in countdown(result.p.high, 0):
    let j = random(i+1)
    swap(result.p[i], result.p[j])


# Sattolo algorithm
proc randomCycle*(N: static[int], size: int): Cycle[N] =
  if size > N or size < 2:
    raise PermError.newException("size is invalid")

  result.c = newSeq[Point](size)
  for i in 1 .. size:
    result.c[i-1] = Point(i)

  for i in countdown(result.c.high, 1):
    let j = random(i)
    swap(result.c[i], result.c[j])

  rotateToMin(result.c)


proc toPerm*[N: static[int]](c: Cycle[N]): Perm[N] =
  result = N.identity
  if c.c.len < 2:
    return

  var x = c.c[0]
  for i in 1 .. <c.c.len:
    result.p[x] = c.c[i]
    x = c.c[i]
  result.p[x] = c.c[0]


# ------ basics ------

proc isZero*(p: Perm): bool =
  for i, v in p.p:
    if int(v) != 0:
      return false

  return true


proc isIdentity*(p: Perm): bool =
  for i, v in p.p:
    if int(v) != i:
      return false

  return true


# optimized p.inverse == p
proc isInvolution*[N: static[int]](p: Perm[N]): bool = 
  for i in 0 .. <N:
    if p.p[p.p[i]] != Point(i):
      return false

  return true


proc `$`*(p: Perm): string =
  result = "["
  for i, e in p.p:
    if i > 0:
      result.add ", "
    result.add($ int(e))
  result.add "]"


#proc `[]`*(p: Perm, x: Point): Point = p[int(x)]


#proc `$`*(d: Point): string = $(int(d))


proc `==`*[N: static[int]](p: Perm[N], q: array[N, int]): bool =
  for i in 0 .. <N:
    if int(p.p[i]) != q[i]:
      return false

  return true


proc `==`*[T](c: Cycle, d: seq[T]): bool =
  if c.c.len != d.len:
    return false
  for i in 0 .. <c.c.len:
    if int(c.c[i]) != int(d[i]):
      return false

  return true


# ------ actions ------

proc inverse*[N: static[int]](p: Perm[N]): Perm[N] =
  for i in 0 .. <N:
    result.p[p.p[i]] = Point(i)


proc `*`*[N: static[int]](p: Perm[N], q: Perm[N]): Perm[N] =
  for i in 0 .. <N:
    result.p[i] = q.p[p.p[i]]


proc compose*[N: static[int]](list: varargs[Perm[N]]): Perm[N] =
  var x: Point
  for i in 0 .. <N:
    x = Point(i)
    for p in list:
      x = p.p[x]
    result.p[i] = x


proc power*[N: static[int]](p: Perm[N], n: int): Perm[N] =
  if n == 0:
    return N.identity

  if n < 0:
    return p.inverse.power(-n)

  for i in 0 .. <N:
    var k = Point(i)
    for j in 0 .. <n:
      k = p.p[k]

    result.p[i] = k


proc conjugate*[N: static[int]](p: Perm[N], q: Perm[N]): Perm[N] =
  for i in 0 .. <N:
    var j = q.p[i]
    var k = p.p[i]
    result.p[j] = q.p[k]


proc conjugate*[N: static[int]](c: Cycle[N], q: Perm[N]): Cycle[N] =
  result.c = newSeq[Point](c.c.len)
  for i in 0 .. <c.c.len:
    result.c[i] = q.p[c.c[i]]

  rotateToMin(result.c)


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
  zeroMem(addr(sgn), (N+1) * 8)

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
      j = int(p.p[j])

    inc(sgn[cnt])

  result.s = sgn


proc signFrom[N: static[int]](sgn: Signature[N]): int {.noSideEffect.} =
  var sum = 0
  for i in countup(2, N, 2):
    sum += sgn.s[i]

  if sum %% 2 == 0:
    return 1
  else:
    return -1


proc orderFrom(sgn: Signature, max = 0): int {.noSideEffect.} =
  result = 1
  for i, v in sgn.s:
    if i >= 2 and v > 0:
      result = lcm(result, i)
      if max > 0 and result > max:
        return -1


proc orderToCycleFrom[N: static[int]](sgn: Signature[N], n: int, max = 0): int {.noSideEffect.} =
  # there must be unique n-cycle
  if n > N or sgn.s[n] != 1:
    return -1

  result = 1
  for i, v in sgn.s:
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
proc scanCycleRep(N: static[int], data: string): seq[int] =
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
proc buildPermFromCycleRep(N: static[int], parts: seq[int]): Perm[N] =
  var perm = N.identity

  var first = -1
  var point = -1
  for part in parts:
    if part == -1:
      if first >= 0 and point >= 0:
        if int(perm.p[point]) != point:
          raise PermError.newException("integers must be unique")

        perm.p[point] = Point(first)
        first = -1
        point = -1
    else:
      if point == -1:
        first = part
        point = part
      else:
        if int(perm.p[point]) != point:
          raise PermError.newException("integers must be unique")

        perm.p[point] = Point(part)
        point = part

  return perm


proc parsePerm*(N: static[int], data: string): Perm[N] =
  N.buildPermFromCycleRep(N.scanCycleRep(data))


proc cycles*[N: static[int]](p: Perm[N]): seq[Cycle[N]] =
  var cycles = newSeq[Cycle[N]]()
  var marks: array[N, bool]
  var m = 0
  while true:
    # find next unmarked
    while m < N and marks[m]:
      inc(m)
    if m == N:
      break

    # construct a cycle
    var cycle = (deg: 0, c: newSeq[Point]())
    var j = m
    while not marks[j]:
      marks[j] = true
      cycle.c.add(Point(j))
      j = int(p.p[j])

    if cycle.c.len > 1:
      cycles.add(cycle)

  # exceptional case: empty
  if cycles.len == 0:
    let cycle = (deg: 0, c: newSeq[Point]())
    cycles.add(cycle)

  return cycles


proc printCycle*(c: Cycle): string =
  result = ""
  result.add "("
  for i, e in c.c:
    if i > 0:
      result.add ", "
    result.add($(e+1))
  result.add ")"


proc printCycles*(p: Perm): string =
  result = ""
  for c in p.cycles:
    result.add printCycle(c)


# canonical star decomposition
proc splitCycles2[N: static[int]](p: Perm[N]): seq[Cycle[N]] =
  result = @[]
  for c in p.cycles:
    for j in 1 .. c.c.high:
      result.add((deg: 0, c: @[c.c[0], c.c[j]]))


# certain 3-cycles decomposition
proc splitCycles3[N: static[int]](p: Perm[N]): seq[Cycle[N]] =
  result = @[]
  # odd cycles
  for c in p.cycles:
    if c.c.len mod 2 == 0:
      continue
    for j in countup(1, c.c.high-1, 2):
      result.add((deg: 0, c: @[c.c[0], c.c[j], c.c[j+1]]))

  # even cycles
  var r: seq[Point]
  for c in p.cycles:
    if c.c.len mod 2 == 1:
      continue
    if r.isNil():
      for j in countup(1, c.c.high-1, 2):
        result.add((deg: 0, c: @[c.c[0], c.c[j], c.c[j+1]]))
      r = @[c.c[0], c.c[c.c.high]]
    else:
      result.add((deg: 0, c: @[r[0], r[1], c.c[0]]))
      result.add((deg: 0, c: @[r[0], c.c[1], c.c[0]]))
      for j in countup(2, c.c.high-1, 2):
        result.add((deg: 0, c: @[c.c[0], c.c[j], c.c[j+1]]))
      r = nil

  if not r.isNil():
    raise PermError.newException("no split for odd perm")


# proxy wrapper
proc splitCycles*[N: static[int]](p: Perm[N], length: int): seq[Cycle[N]] =
  if length == 2:
    return splitCycles2(p)
  elif length == 3:
    return splitCycles3(p)
  else:
    raise PermError.newException("unsupported split length")
