# this file is excluded from the fizzygum homepage build


class LCLTransforms

  matrixStack: nil
  worldMatrix: nil

  constructor: ->
    @resetMatrixStack()


  # same shape and basically same implementation as most
  # matrix libraries e.g. Three.Matrix4, twgl.m4, gl-matrix.mat4
  createIdentityMatrix: ->
    out = new Float32Array(16)
    # all other elements are zero by default
    out[0] = 1
    out[5] = 1
    out[10] = 1
    out[15] = 1
    out

  getWorldMatrix: ->
    @worldMatrix

  resetMatrixStack: ->
    @matrixStack = []
    @worldMatrix = @createIdentityMatrix()

  pushMatrix: ->
    @matrixStack.push @worldMatrix
    @worldMatrix = @copyMatrix @worldMatrix

  scaleMatrix = (m, v, dst = new Float32Array(16)) ->
    v0 = v[0]
    v1 = v[1]
    v2 = v[2]
    dst[0] = v0 * m[0 * 4 + 0]
    dst[1] = v0 * m[0 * 4 + 1]
    dst[2] = v0 * m[0 * 4 + 2]
    dst[3] = v0 * m[0 * 4 + 3]
    dst[4] = v1 * m[1 * 4 + 0]
    dst[5] = v1 * m[1 * 4 + 1]
    dst[6] = v1 * m[1 * 4 + 2]
    dst[7] = v1 * m[1 * 4 + 3]
    dst[8] = v2 * m[2 * 4 + 0]
    dst[9] = v2 * m[2 * 4 + 1]
    dst[10] = v2 * m[2 * 4 + 2]
    dst[11] = v2 * m[2 * 4 + 3]
    if m != dst
      dst[12] = m[12]
      dst[13] = m[13]
      dst[14] = m[14]
      dst[15] = m[15]
    dst

  copyMatrix: (m, dst = new Float32Array(16)) ->
    dst[0] = m[0]
    dst[1] = m[1]
    dst[2] = m[2]
    dst[3] = m[3]
    dst[4] = m[4]
    dst[5] = m[5]
    dst[6] = m[6]
    dst[7] = m[7]
    dst[8] = m[8]
    dst[9] = m[9]
    dst[10] = m[10]
    dst[11] = m[11]
    dst[12] = m[12]
    dst[13] = m[13]
    dst[14] = m[14]
    dst[15] = m[15]
    dst

  # in the following case:
  #  flashing = <if random < 0.5 then scale 0>
  #  flashing
  #  ball
  # it happens that because flashing is invoked
  # without arguments, then scale is invoked with 0
  # and a function that returns null
  # in which case it means that scale has done a
  # push matrix, it invokes the chained function
  # and finds out that the transformation actually
  # won't be popped. So we need a way to "undo"
  # the push. This is like a pop but we
  # discard the popped value.
  discardPushedMatrix: ->
    if @matrixStack.length
      @matrixStack.pop()

  popMatrix: ->
    if @matrixStack.length
      @worldMatrix = @matrixStack.pop()
    else
      @worldMatrix = @createIdentityMatrix()

  resetMatrix: ->
    @worldMatrix = @createIdentityMatrix()

  multiplyMatrix: (a, b, dst = new Float32Array(16)) ->
    a00 = a[0]
    a01 = a[1]
    a02 = a[2]
    a03 = a[3]
    a10 = a[4 + 0]
    a11 = a[4 + 1]
    a12 = a[4 + 2]
    a13 = a[4 + 3]
    a20 = a[8 + 0]
    a21 = a[8 + 1]
    a22 = a[8 + 2]
    a23 = a[8 + 3]
    a30 = a[12 + 0]
    a31 = a[12 + 1]
    a32 = a[12 + 2]
    a33 = a[12 + 3]
    b00 = b[0]
    b01 = b[1]
    b02 = b[2]
    b03 = b[3]
    b10 = b[4 + 0]
    b11 = b[4 + 1]
    b12 = b[4 + 2]
    b13 = b[4 + 3]
    b20 = b[8 + 0]
    b21 = b[8 + 1]
    b22 = b[8 + 2]
    b23 = b[8 + 3]
    b30 = b[12 + 0]
    b31 = b[12 + 1]
    b32 = b[12 + 2]
    b33 = b[12 + 3]
    dst[0] = a00 * b00 + a10 * b01 + a20 * b02 + a30 * b03
    dst[1] = a01 * b00 + a11 * b01 + a21 * b02 + a31 * b03
    dst[2] = a02 * b00 + a12 * b01 + a22 * b02 + a32 * b03
    dst[3] = a03 * b00 + a13 * b01 + a23 * b02 + a33 * b03
    dst[4] = a00 * b10 + a10 * b11 + a20 * b12 + a30 * b13
    dst[5] = a01 * b10 + a11 * b11 + a21 * b12 + a31 * b13
    dst[6] = a02 * b10 + a12 * b11 + a22 * b12 + a32 * b13
    dst[7] = a03 * b10 + a13 * b11 + a23 * b12 + a33 * b13
    dst[8] = a00 * b20 + a10 * b21 + a20 * b22 + a30 * b23
    dst[9] = a01 * b20 + a11 * b21 + a21 * b22 + a31 * b23
    dst[10] = a02 * b20 + a12 * b21 + a22 * b22 + a32 * b23
    dst[11] = a03 * b20 + a13 * b21 + a23 * b22 + a33 * b23
    dst[12] = a00 * b30 + a10 * b31 + a20 * b32 + a30 * b33
    dst[13] = a01 * b30 + a11 * b31 + a21 * b32 + a31 * b33
    dst[14] = a02 * b30 + a12 * b31 + a22 * b32 + a32 * b33
    dst[15] = a03 * b30 + a13 * b31 + a23 * b32 + a33 * b33
    dst

  makeRotationFromEuler: (euler, te = new Float32Array(16)) ->
    x = euler[0]
    y = euler[1]
    z = euler[2]
    a = Math.cos(x)
    b = Math.sin(x)
    c = Math.cos(y)
    d = Math.sin(y)
    e = Math.cos(z)
    f = Math.sin(z)
    ae = a * e
    af = a * f
    be = b * e
    bf = b * f
    te[0] = c * e
    te[4] = -c * f
    te[8] = d
    te[1] = af + be * d
    te[5] = ae - (bf * d)
    te[9] = -b * c
    te[2] = bf - (ae * d)
    te[6] = be + af * d
    te[10] = a * c
    # bottom row
    te[3] = 0
    te[7] = 0
    te[11] = 0
    # last column
    te[12] = 0
    te[13] = 0
    te[14] = 0
    te[15] = 1
    te

  makeTranslation: (x, y, z) ->
    dst = new Float32Array(16)
    dst[0] = 1
    dst[1] = 0
    dst[2] = 0
    dst[3] = x
    dst[4] = 0
    dst[5] = 1
    dst[6] = 0
    dst[7] = y
    dst[8] = 0
    dst[9] = 0
    dst[10] = 1
    dst[11] = z
    dst[12] = 0
    dst[13] = 0
    dst[14] = 0
    dst[15] = 1
    dst


  # TODO pulse function probably should go somewhere else?
  pulse: (frequency) ->

    d = new Date
    n = d.getMilliseconds()

    if typeof frequency != "number"
      frequency = 1
    return Math.exp(
      -Math.pow(
        Math.pow(((n/1000) * frequency) % 1, 0.3) - 0.5, 2
      ) / 0.05
    )

  scale: (a, b = 1, c = 1, d = nil) ->
    arg_a = a
    arg_b = b
    arg_c = c
    arg_d = d

    appendedFunctionsStartIndex = undefined

    if typeof arg_a isnt "number"
      if Utils.isFunction arg_a then appendedFunctionsStartIndex = 0
      arg_a = 0.5 + @pulse()
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_b isnt "number"
      if Utils.isFunction arg_b then appendedFunctionsStartIndex = 1
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_c isnt "number"
      if Utils.isFunction arg_c then appendedFunctionsStartIndex = 2
      arg_c = 1
    else if Utils.isFunction arg_d
      appendedFunctionsStartIndex = 3


    @pushMatrix() if appendedFunctionsStartIndex?

    # odd things happen setting scale to zero
    arg_a = 0.000000001  if arg_a > -0.000000001 and arg_a < 0.000000001
    arg_b = 0.000000001  if arg_b > -0.000000001 and arg_b < 0.000000001
    arg_c = 0.000000001  if arg_c > -0.000000001 and arg_c < 0.000000001

    @scaleMatrix @worldMatrix,[arg_a,arg_b,arg_c], @worldMatrix

    if appendedFunctionsStartIndex?
      while Utils.isFunction arguments[appendedFunctionsStartIndex]
        result = arguments[appendedFunctionsStartIndex].apply @
        # we find out that the function is actually
        # a fake so we have to undo the push and leave
        if !result?
          @discardPushedMatrix()
          return
        appendedFunctionsStartIndex++
      @popMatrix()

  rotate: (a, b, c = 0, d = nil) ->
    arg_a = a
    arg_b = b
    arg_c = c
    arg_d = d

    appendedFunctionsStartIndex = undefined

    if typeof arg_a isnt "number"
      if Utils.isFunction arg_a then appendedFunctionsStartIndex = 0
      arg_a = @pulse() * Math.PI
      arg_b = arg_a
      arg_c = 0
    else if typeof arg_b isnt "number"
      if Utils.isFunction arg_b then appendedFunctionsStartIndex = 1
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_c isnt "number"
      if Utils.isFunction arg_c then appendedFunctionsStartIndex = 2
      arg_c = 0
    else if Utils.isFunction arg_d
      appendedFunctionsStartIndex = 3

    context = @backBufferContext
    if appendedFunctionsStartIndex?
      context.save()

    @pushMatrix() if appendedFunctionsStartIndex?
    @multiplyMatrix @worldMatrix, @makeRotationFromEuler([arg_a, arg_b, arg_c]), @worldMatrix

    if appendedFunctionsStartIndex?
      while Utils.isFunction arguments[appendedFunctionsStartIndex]
        result = arguments[appendedFunctionsStartIndex].apply @
        # we find out that the function is actually
        # a fake so we have to undo the push and leave
        if !result?
          discardPushedMatrix()
          return
        appendedFunctionsStartIndex++
      @popMatrix()

  move: (a, b, c = 0, d = nil) ->
    arg_a = a
    arg_b = b
    arg_c = c
    arg_d = d

    appendedFunctionsStartIndex = undefined

    if typeof arg_a isnt "number"
      if Utils.isFunction arg_a then appendedFunctionsStartIndex = 0
      arg_a = @pulse() * Math.PI
      arg_b = arg_a
      arg_c = 0
    else if typeof arg_b isnt "number"
      if Utils.isFunction arg_b then appendedFunctionsStartIndex = 1
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_c isnt "number"
      if Utils.isFunction arg_c then appendedFunctionsStartIndex = 2
      arg_c = 0
    else if Utils.isFunction arg_d
      appendedFunctionsStartIndex = 3

    context = @backBufferContext
    if appendedFunctionsStartIndex?
      context.save()

    @pushMatrix() if appendedFunctionsStartIndex?
    @multiplyMatrix @worldMatrix, @makeTranslation(arg_a, arg_b, arg_c), @worldMatrix

    if appendedFunctionsStartIndex?
      while Utils.isFunction arguments[appendedFunctionsStartIndex]
        result = arguments[appendedFunctionsStartIndex].apply @
        # we find out that the function is actually
        # a fake so we have to undo the push and leave
        if !result?
          discardPushedMatrix()
          return
        appendedFunctionsStartIndex++
      @popMatrix()
