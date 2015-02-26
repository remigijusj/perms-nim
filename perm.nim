import algorithm, math, re, strutils

randomize()

const TOP_LEN = 1 shl 16

# TODO: array parametrized over len?
type
  Dot* = distinct uint16
  Perm* = object
    elements: seq[Dot]
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

  Perm(elements: convertSeq(data))


proc identity*(size: int): Perm =
  if size < 0 or size > TOP_LEN:
    raise PError.newException("invalid identity size")

  var elements = newSeq[Dot](size)
  for i in 0 .. <size:
    elements[i] = Dot(i)

  Perm(elements: elements)


proc randomPerm*(size: int): Perm =
  var perm = identity(size)
  shuffle(perm.elements)
  perm


proc `$`*(p: Perm): string =
  result = "["
  for i, e in p.elements:
    if i > 0:
      result.add " "
    result.add($int(e))
  result.add "]"


proc size*(p: Perm): int = p.elements.len


proc on*(p: Perm, i: int): int =
  if i >= 0 and i < p.elements.len:
    return int(p.elements[i])
  else:
    return i


proc inverse*(p: Perm): Perm =
  var elements = newSeq[Dot](p.elements.len)
  for i in 0 .. <elements.len:
    elements[int(p.elements[i])] = Dot(i)

  Perm(elements: elements)


proc compose*(p: Perm, q: Perm): Perm =
  var elements: seq[Dot]
  let psize = p.elements.len
  let qsize = q.elements.len
  if psize > qsize:
    elements = newSeq[Dot](psize)
  else:
    elements = newSeq[Dot](qsize)

  for i in 0 .. <elements.len:
    var k = i
    if k < psize:
      k = int(p.elements[k])

    if k < qsize:
      k = int(q.elements[k])

    elements[i] = Dot(k)

  Perm(elements: elements)


proc power*(p: Perm, n: int): Perm =
  if n == 0:
    return identity(p.elements.len)

  if n < 0:
    return p.inverse.power(-n)

  var elements = newSeq[Dot](p.elements.len)
  for i in 0 .. <elements.len:
    var j = i
    for k in 0 .. <n:
      j = int(p.elements[j])

    elements[i] = Dot(j)

  return Perm(elements: elements)


proc conjugate*(p: Perm, q: Perm): Perm =
  var elements: seq[Dot]
  let psize = p.elements.len
  let qsize = q.elements.len
  if psize > qsize:
    elements = newSeq[Dot](psize)
  else:
    elements = newSeq[Dot](qsize)

  for i in 0 .. <elements.len:
    var k = i
    var j = i
    if k < qsize:
      j = int(q.elements[i])

    if k < psize:
      k = int(p.elements[k])

    if k < qsize:
      k = int(q.elements[k])

    elements[j] = Dot(k)

  Perm(elements: elements)


proc isIdentity*(p: Perm): bool =
  for i, v in p.elements:
    if int(v) != i:
      return false

  return true


# TODO: `==`
proc isEqual*(p: Perm, q: Perm): bool =
  var
    a = p
    b = q

  if b.elements.len > a.elements.len:
    swap(a, b)

  let lim = b.elements.len
  for i, v in a.elements:
    if i < lim:
      if int(v) != int(b.elements[i]):
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
  let size = p.elements.len
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
      j = int(p.elements[j])

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


# TODO: binary reduce? multi-lcm algorithm?
# TODO: control overflow
proc order*(p: Perm): int =
  if p.elements.len < 2:
    return 1

  let sgn = p.signature
  var ord = 1
  for i, v in sgn:
    if i >= 2 and v > 0:
      ord = lcm(ord, i)

  return ord


proc orderToCycle*(p: Perm, n: int): int =
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
        if int(perm.elements[point]) != point:
          raise PError.newException("integers must be unique")

        perm.elements[point] = Dot(first)
        first = -1
        point = -1
    else:
      if point == -1:
        first = part
        point = part
      else:
        if int(perm.elements[point]) != point:
          raise PError.newException("integers must be unique")

        perm.elements[point] = Dot(part)
        point = part

  return perm


proc parseCycles*(data: string): Perm =
  buildPermFromCycleRep(scanCycleRep(data))


proc getCycles(p: Perm): seq[seq[Dot]] =
  let size = p.elements.len
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
      j = int(p.elements[j])

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
