# FridgeMagnetsCanvasMorph //////////////////////////////////////////////////////////
# REQUIRES BackBufferMixin
# REQUIRES numbertimes
# 
# 
# "container"/"contained" scenario going on.

class FridgeMagnetsCanvasMorph extends CanvasMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  primitiveTypes: {}
  lclCodeCompiler: new LCLCodeCompiler()

  createRefreshOrGetBackBuffer: ->
    [@backBuffer, @backBufferContext] = super
    @paintNewFrame()
    return [@backBuffer, @backBufferContext]

  oldGraphicsCode: ->

  graphicsCode: ->

  newGraphicsCode: (newCode) ->
    @oldGraphicsCode = @graphicsCode
    # Coffeescript v2 is used
    compilation = @lclCodeCompiler.compileCode newCode
    if compilation.program?
      @graphicsCode = compilation.program

  constructor: ->
    super

    @fps = 0
    world.addSteppingMorph @

    numberOfPrimitives = 0
    @primitiveTypes.ambientLight = numberOfPrimitives++
    @primitiveTypes.line = numberOfPrimitives++
    @primitiveTypes.rect = numberOfPrimitives++
    @primitiveTypes.box = numberOfPrimitives++
    @primitiveTypes.peg = numberOfPrimitives++
    @primitiveTypes.ball = numberOfPrimitives++

  step: ->
    #console.log "stepping FridgeMagnetsCanvasMorph"
    @paintNewFrame()

  paintNewFrame: ->
    # we get the context already with the correct pixel scaling
    # (ALWAYS leave the context with the correct pixel scaling.)
    @clear()
    context = @backBufferContext
    context.translate @width()/2, @height()/2
    try
      @graphicsCode()
    catch
      @graphicsCode = @oldGraphicsCode

  pulse: (frequency) ->

    d = new Date()
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
      if isFunction arg_a then appendedFunctionsStartIndex = 0
      arg_a = 0.5 + @pulse()
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_b isnt "number"
      if isFunction arg_b then appendedFunctionsStartIndex = 1
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_c isnt "number"
      if isFunction arg_c then appendedFunctionsStartIndex = 2
      arg_c = 1
    else if isFunction arg_d
      appendedFunctionsStartIndex = 3



    context = @backBufferContext
    if appendedFunctionsStartIndex?
      context.save()


    # odd things happen setting scale to zero
    arg_a = 0.000000001  if arg_a > -0.000000001 and arg_a < 0.000000001
    arg_b = 0.000000001  if arg_b > -0.000000001 and arg_b < 0.000000001
    arg_c = 0.000000001  if arg_c > -0.000000001 and arg_c < 0.000000001

    context.scale arg_a, arg_b

    if appendedFunctionsStartIndex?
      while isFunction arguments[appendedFunctionsStartIndex]
        result = arguments[appendedFunctionsStartIndex].apply @
        # we find out that the function is actually
        # a fake so we have to undo the push and leave
        if !result?
          context.restore()
          return
        appendedFunctionsStartIndex++
      context.restore()

  rotate: (a, b, c = 0, d = nil) ->
    arg_a = a
    arg_b = b
    arg_c = c
    arg_d = d

    appendedFunctionsStartIndex = undefined

    if typeof arg_a isnt "number"
      if isFunction arg_a then appendedFunctionsStartIndex = 0
      arg_a = @pulse() * Math.PI
      arg_b = arg_a
      arg_c = 0
    else if typeof arg_b isnt "number"
      if isFunction arg_b then appendedFunctionsStartIndex = 1
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_c isnt "number"
      if isFunction arg_c then appendedFunctionsStartIndex = 2
      arg_c = 0
    else if isFunction arg_d
      appendedFunctionsStartIndex = 3

    context = @backBufferContext
    if appendedFunctionsStartIndex?
      context.save()

    context.rotate arg_a

    if appendedFunctionsStartIndex?
      while isFunction arguments[appendedFunctionsStartIndex]
        result = arguments[appendedFunctionsStartIndex].apply @
        # we find out that the function is actually
        # a fake so we have to undo the push and leave
        if !result?
          context.restore()
          return
        appendedFunctionsStartIndex++
      context.restore()

  move: (a, b, c = 0, d = nil) ->
    arg_a = a
    arg_b = b
    arg_c = c
    arg_d = d

    appendedFunctionsStartIndex = undefined

    if typeof arg_a isnt "number"
      if isFunction arg_a then appendedFunctionsStartIndex = 0

      d = new Date()
      n = d.getTime()

      arg_a = Math.sin(n/150) * 15
      arg_b = Math.cos(n/150) * 15
      arg_c = arg_a
    else if typeof arg_b isnt "number"
      if isFunction arg_b then appendedFunctionsStartIndex = 1
      arg_b = arg_a
      arg_c = arg_a
    else if typeof arg_c isnt "number"
      if isFunction arg_c then appendedFunctionsStartIndex = 2
      arg_c = 0
    else if isFunction arg_d
      appendedFunctionsStartIndex = 3

    context = @backBufferContext
    if appendedFunctionsStartIndex?
      context.save()

    context.translate arg_a, arg_b

    if appendedFunctionsStartIndex?
      while isFunction arguments[appendedFunctionsStartIndex]
        result = arguments[appendedFunctionsStartIndex].apply @
        # we find out that the function is actually
        # a fake so we have to undo the push and leave
        if !result?
          context.restore()
          return
        appendedFunctionsStartIndex++
      context.restore()

  box: (a, b, c, d = nil) ->
    # primitive-specific initialisations:
    primitiveProperties =
      canFill: true
      primitiveType: @primitiveTypes.box
      #sidedness: @threeJs.FrontSide
      #threeObjectConstructor: @threeJs.Mesh
      detailLevel: 0

    # end of primitive-specific initialisations:
    @commonPrimitiveDrawingLogic a, b, c, d, primitiveProperties
  
  commonPrimitiveDrawingLogic: (a, b, c, d, primitiveProperties) ->

    
    #if @liveCodeLabCoreInstance.animationLoop.noDrawFrame
    #  #console.log "skipping the frame"
    #  return

    # b and c are not functional in some geometric
    # primitives, but we handle them here in all cases
    # to make the code uniform and unifiable
    if typeof a isnt "number"
      if isFunction a then appendedFunction = a
      a = 1
      b = 1
      c = 1
    else if typeof b isnt "number"
      if isFunction b then appendedFunction = b
      b = a
      c = a
    else if typeof c isnt "number"
      if isFunction c then appendedFunction = c
      c = 1
    else if isFunction d
      appendedFunction = d

    #context.beginPath();
    #context.lineWidth="6";
    #context.strokeStyle="red";
    #context.rect(5,5,290,140); 
    #context.stroke();

    @backBufferContext.strokeStyle = "black"
    @backBufferContext.beginPath()
    @backBufferContext.rect -50,-50,100,100
    @backBufferContext.stroke()

    @changed()

    if appendedFunction? then appendedFunction.apply @
    return

