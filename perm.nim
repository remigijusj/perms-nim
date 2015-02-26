import algorithm, math, re, strutils

randomize()

const TOP_LEN = 1 shl 8 # OBSOLETE, get from Dot
# const Size = 1 # bytes: max 256

type
  Dot* = distinct uint8
  Perm* = seq[Dot]
  PError* = object of Exception


proc `$`*(d: Dot): string =
  $(int(d)+1)


proc isValidSeq(data: seq[int]): bool
proc convertSeq(data: seq[int]): seq[Dot]

# WTF: can't use forward-decl
proc shuffle(x: var seq[Dot]) =
  for i in countdown(x.high, 0):
    let j = random(i + 1)
    swap(x[i], x[j])


# ------ basics ------

proc newPerm*(data: seq[int]): Perm =
  if data.len > TOP_LEN:
    raise PError.newException("constructing list too long")

  if not isValidSeq(data):
    raise PError.newException("invalid constructing list")

  Perm(convertSeq(data))


proc identity*(size: int): Perm =
  if size < 0 or size > TOP_LEN:
    raise PError.newException("invalid identity size")

  var list = newSeq[Dot](size)
  for i in 0 .. <size:
    list[i] = Dot(i)

  Perm(list)


proc randomPerm*(size: int): Perm =
  var perm = identity(size)
  shuffle(perm)
  perm


proc `$`*(p: Perm): string =
  result = "["
  for i, e in p:
    if i > 0:
      result.add " "
    result.add($int(e))
  result.add "]"


proc size*(p: Perm): int = p.len


proc on*(p: Perm, i: int): int =
  if i >= 0 and i < p.len:
    return int(p[i])
  else:
    return i


proc inverse*(p: Perm): Perm =
  var list = newSeq[Dot](p.len)
  for i in 0 .. <list.len:
    list[int(p[i])] = Dot(i)

  Perm(list)


proc compose*(p: Perm, q: Perm): Perm =
  var list: seq[Dot]
  let psize = p.len
  let qsize = q.len
  if psize > qsize:
    list = newSeq[Dot](psize)
  else:
    list = newSeq[Dot](qsize)

  for i in 0 .. <list.len:
    var k = i
    if k < psize:
      k = int(p[k])

    if k < qsize:
      k = int(q[k])

    list[i] = Dot(k)

  Perm(list)


proc power*(p: Perm, n: int): Perm =
  if n == 0:
    return identity(p.len)

  if n < 0:
    return p.inverse.power(-n)

  var list = newSeq[Dot](p.len)
  for i in 0 .. <list.len:
    var j = i
    for k in 0 .. <n:
      j = int(p[j])

    list[i] = Dot(j)

  return Perm(list)


proc conjugate*(p: Perm, q: Perm): Perm =
  var list: seq[Dot]
  let psize = p.len
  let qsize = q.len
  if psize > qsize:
    list = newSeq[Dot](psize)
  else:
    list = newSeq[Dot](qsize)

  for i in 0 .. <list.len:
    var k = i
    var j = i
    if k < qsize:
      j = int(q[i])

    if k < psize:
      k = int(p[k])

    if k < qsize:
      k = int(q[k])

    list[j] = Dot(k)

  Perm(list)


proc isIdentity*(p: Perm): bool =
  for i, v in p:
    if int(v) != i:
      return false

  return true


proc `==`*(p: Perm, q: Perm): bool =
  var
    a = p
    b = q

  if b.len > a.len:
    swap(a, b)

  let lim = b.len
  for i, v in a:
    if i < lim:
      if int(v) != int(b[i]):
        return false
    else:
      if int(v) != i:
        return false

  return true


proc isValidSeq(data: seq[int]): bool =
  var check = data
  check.sort(system.cmp[int])

  for i in 0 .. <check.len:
    if check[i] != i:
      return false

  return true


proc convertSeq(data: seq[int]): seq[Dot] =
  result = newSeq[Dot](data.len)

  for i in 0 .. <data.len:
    result[i] = Dot(data[i])


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
  let size = p.len
  var sign = newSeq[int](size+1)

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

    inc(sign[cnt])

  sign


proc sign*(p: Perm): int =
  let sgn = p.signature
  var sum = 0
  for i in countup(2, sgn.len-1, 2):
    sum += sgn[i]

  if sum %% 2 == 0:
    return 1
  else:
    return -1


# TODO: binary reduce, multi-lcm algorithm
# TODO: control overflow of lcm
proc order*(p: Perm): int =
  if p.len < 2:
    return 1

  let sgn = p.signature
  var ord = 1
  for i, v in sgn:
    if i >= 2 and v > 0:
      ord = lcm(ord, i)

  return ord


proc orderToCycle*(p: Perm, n: int, max = 0): int =
  if n < 2:
    return -1

  let sgn = p.signature
  # there must be unique n-cycle
  if sgn[n] != 1:
    return -1

  var pow = 1
  for i, v in sgn:
    if gcd(i, n) > 1:
      # no cycles which could reduce to n
      if i != n and v > 0:
        return -1
    else:
      # contributes to power
      if i >= 2 and v > 0:
        pow = lcm(pow, i)
        if max > 0 and pow > max:
          return -1

  return pow


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

    if part > 0:
      dec(part)
    elif part == 0:
      raise PError.newException("integers can't be zero")

    parts.add(part)
    if part > max:
      max = part

  # must end in -1
  if parts.len == 0 or parts[parts.len-1] != -1:
    parts.add(-1)

  result.parts = parts
  result.max = max


# build permutation
# ex: []int{-1, 0, 1, -1, 2, 7, -1, 6, 3, -1} -> []Dot{1, 0, 7, 6, 4, 5, 3, 2}
proc buildPermFromCycleRep(rep: tuple[parts: seq[int], max: int]): Perm =
  var perm = identity(rep.max + 1)

  var first = -1 
  var point = -1
  for part in rep.parts:
    if part == -1:
      if first >= 0 and point >= 0:
        if int(perm[point]) != point:
          raise PError.newException("integers must be unique")

        perm[point] = Dot(first)
        first = -1
        point = -1
    else:
      if point == -1:
        first = part
        point = part
      else:
        if int(perm[point]) != point:
          raise PError.newException("integers must be unique")

        perm[point] = Dot(part)
        point = part

  return perm


proc parseCycles*(data: string): Perm =
  buildPermFromCycleRep(scanCycleRep(data))


proc getCycles(p: Perm): seq[seq[Dot]] =
  let size = p.len
  var cycles = newSeq[seq[Dot]]()
  var marks = newSeq[bool](size)
  var m = 0
  while true:
    # find next unmarked
    while m < size and marks[m]:
      inc(m)

    if m == size:
      break

    # construct a cycle
    var cycle = newSeq[Dot]()
    var j = m
    while not marks[j]:
      marks[j] = true
      cycle.add(Dot(j))
      j = int(p[j])

    if cycle.len > 1:
      cycles.add(cycle)

  # exceptional case: empty
  if cycles.len == 0:
    let cycle = newSeq[Dot]()
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
