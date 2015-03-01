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


when isMainModule:
  import unittest

  suite "basic tests":
    test "constructor":
      let p: Perm = [1'u8, 0'u8, 2'u8, 3'u8, 4'u8, 5'u8, 6'u8, 7'u8]
      check($ p == "[1 0 2 3 4 5 6 7]")

    test "newPerm invalid":
      var p: Perm
      expect PermErr:
        p = newPerm(@[1, 2, 3, 4, 5, 6, 7])
      expect PermErr:
        p = newPerm(@[0, 0, 1])
      expect PermErr:
        p = newPerm(@[-2, 0, 1])
      expect PermErr:
        p = newPerm(@[0, 2, 3])
      expect PermErr:
        p = newPerm(@[3, 2, 3])

    test "identity valid":
      let p = identity()
      check(p.size == 8)
      check($ p == "[0 1 2 3 4 5 6 7]")

    test "randomPerm":
      let p = randomPerm()
      check(p.size == 8)


    test "size":
      let p = newPerm(@[1, 3, 2, 0])
      check(p.size == 8)


    test "inverse":
      let p = newPerm(@[1, 2, 3, 4, 0])
      check($ p.inverse == "[4 0 1 2 3 5 6 7]")


    test "compose":
      let p = newPerm(@[1, 2, 0])
      let q = newPerm(@[0, 3, 4, 1, 2])
      check($ p.compose(q) == "[3 4 0 1 2 5 6 7]")


    test "power":
      let p = newPerm(@[1, 2, 3, 4, 5, 0])
      check($ p.power(2) == "[2 3 4 5 0 1 6 7]")


    test "conjugate 0":
      let p = identity()
      let q = randomPerm()
      check(p.conjugate(q).isIdentity == true)

    test "conjugate 0a":
      let p = randomPerm()
      let q = identity()
      check(p.conjugate(q) == p)

    test "conjugate 1":
      let p = newPerm(@[1, 2, 0])
      let q = newPerm(@[0, 3, 4, 1, 2])
      check($ p.conjugate(q) == "[3 1 2 4 0 5 6 7]")

    test "conjugate 2":
      let p = newPerm(@[4, 2, 0, 1, 3])
      let q = newPerm(@[1, 2, 0])
      check($ p.conjugate(q) == "[1 4 0 2 3 5 6 7]")


    test "isIdentity 0":
      let p = newPerm(@[])
      check(p.isIdentity == true)

    test "isIdentity 1":
      let p = newPerm(@[0, 1])
      check(p.isIdentity == true)

    test "isIdentity 2":
      let p = newPerm(@[0, 1, 2])
      check(p.isIdentity == true)

    test "isIdentity 3":
      let p = newPerm(@[1, 0])
      check(p.isIdentity == false)

    test "isIdentity 4":
      let p = newPerm(@[0, 1, 3, 2])
      check(p.isIdentity == false)


    test "isEqual 0":
      let p = newPerm(@[])
      check(p == p)

    test "isEqual 1":
      let p = newPerm(@[0])
      check(p == p)

    test "isEqual 2":
      let p = newPerm(@[0, 1])
      let q = newPerm(@[0, 1, 2])
      check(p == q)
      check(q == p)


    test "signature 0":
      let p = newPerm(@[])
      check(p.signature == @[0, 8, 0, 0, 0, 0, 0, 0, 0])
      check(p.sign == 1)
      check(p.order == 1)

    test "signature 1":
      let p = newPerm(@[0])
      check(p.signature == @[0, 8, 0, 0, 0, 0, 0, 0, 0])
      check(p.sign == 1)
      check(p.order == 1)

    test "signature 2":
      let p = newPerm(@[1, 0])
      check(p.signature == @[0, 6, 1, 0, 0, 0, 0, 0, 0])
      check(p.sign == -1)
      check(p.order == 2)
      check(p.orderToCycle(2) == 1)

    test "signature 4":
      let p = newPerm(@[1, 0, 3, 2])
      check(p.signature == @[0, 4, 2, 0, 0, 0, 0, 0, 0])
      check(p.sign == 1)
      check(p.order == 2)
      check(p.orderToCycle(2) == -1)

    test "signature 5a":
      let p = newPerm(@[1, 0, 3, 2, 4])
      check(p.signature == @[0, 4, 2, 0, 0, 0, 0, 0, 0])
      check(p.sign == 1)
      check(p.order == 2)

    test "signature 5c":
      let p = newPerm(@[1, 0, 3, 4, 2])
      check(p.signature == @[0, 3, 1, 1, 0, 0, 0, 0, 0])
      check(p.sign == -1)
      check(p.order == 6)
      check(p.orderToCycle(2) == 3)
      check(p.orderToCycle(3) == 2)

    test "signature 5d":
      let p = newPerm(@[0, 1, 3, 4, 2])
      check(p.signature == @[0, 5, 0, 1, 0, 0, 0, 0, 0])
      check(p.sign == 1)
      check(p.order == 3)
      check(p.orderToCycle(3) == 1)

    test "signature 6a":
      let p = newPerm(@[1, 2, 3, 4, 5, 0])
      check(p.signature == @[0, 2, 0, 0, 0, 0, 1, 0, 0])
      check(p.sign == -1)
      check(p.order == 6)

    test "signature 6b":
      let p = newPerm(@[0, 2, 1, 4, 5, 3])
      check(p.signature == @[0, 3, 1, 1, 0, 0, 0, 0, 0])
      check(p.sign == -1)
      check(p.order == 6)

    test "signature 6c":
      let p = newPerm(@[5, 4, 1, 2, 3, 0])
      check(p.signature == @[0, 2, 1, 0, 1, 0, 0, 0, 0])
      check(p.sign == 1)
      check(p.order == 4)
      check(p.orderToCycle(4) == -1)


    test "parseCycles invalid 0":
      expect PermErr:
        discard parseCycles("(1 2 3 0)")

    test "parseCycles invalid 1":
      expect PermErr:
        discard parseCycles("(1 2)(2, 3)")

    test "parseCycles invalid 2":
      expect PermErr:
        discard parseCycles("(1, 2, 65537)")


    test "parseCycles 0":
      let p = parseCycles("")
      check($ p == "[0 1 2 3 4 5 6 7]")

    test "parseCycles 1":
      let p = parseCycles("")
      check($ p == "[0 1 2 3 4 5 6 7]")

    test "parseCycles 2":
      let p = parseCycles("( )( ( )(")
      check($ p == "[0 1 2 3 4 5 6 7]")

    test "parseCycles 3":
      let p = parseCycles("(1)")
      check($ p == "[0 1 2 3 4 5 6 7]")

    test "parseCycles 4":
      let p = parseCycles("(1,2)")
      check($ p == "[1 0 2 3 4 5 6 7]")

    test "parseCycles 5":
      let p = parseCycles("(3,5)")
      check($ p == "[0 1 4 3 2 5 6 7]")

    test "parseCycles 6":
      let p = parseCycles("(1, 2) (3, 4) ")
      check($ p == "[1 0 3 2 4 5 6 7]")

    test "parseCycles 7":
      let p = parseCycles("(1 2)(3 8)(7 4)")
      check($ p == "[1 0 7 6 4 5 3 2]")

    test "parseCycles 8":
      let p = parseCycles("(1 2 ; 3, 8 ; 7 4 )")
      check($ p == "[1 0 7 6 4 5 3 2]")

    test "parseCycles 9":
      let p = parseCycles("1 2 3 4)(5 6 7 8")
      check($ p == "[1 2 3 0 5 6 7 4]")


    test "printCycles 1":
      let p = newPerm(@[])
      check(p.printCycles == "()")

    test "printCycles 2":
      let p = newPerm(@[0])
      check(p.printCycles == "()")

    test "printCycles 3":
      let p = identity()
      check(p.printCycles == "()")

    test "printCycles 4":
      let p = newPerm(@[1, 2, 3, 4, 5, 0])
      check(p.printCycles == "(1, 2, 3, 4, 5, 6)")

    test "printCycles 5":
      let p = newPerm(@[1, 2, 0, 4, 5, 3])
      check(p.printCycles == "(1, 2, 3)(4, 5, 6)")

    test "printCycles 6":
      let p = newPerm(@[5, 4, 3, 2, 1, 0])
      check(p.printCycles == "(1, 6)(2, 5)(3, 4)")

    test "printCycles 7":
      let p = newPerm(@[0, 1, 4, 3, 2, 5])
      check(p.printCycles == "(3, 5)")
