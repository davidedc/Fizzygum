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
