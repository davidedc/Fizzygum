# this file is excluded from the fizzygum homepage build

# "container"/"contained" scenario going on.

class FridgeMagnets3DCanvasMorph extends CanvasMorph

  primitiveTypes: {}
  # TODO this type of construction in the fields is bad for
  # dependency checks, because this constructor might in turn
  # depend on a number of other definitions. Better to initialise
  # things in the constructor
  lclCodeCompiler: nil

  m4: nil
  gl: nil
  glBuffer: nil
  programInfo: nil
  arrays: nil
  bufferInfo: nil
  tex: nil
  uniforms: nil

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

    script = document.createElement "script"
    script.src = "js/libs/twgl-full.js"
    script.async = true # should be the default
    # triggers after the script was loaded and executed
    # see https://javascript.info/onload-onerror#script-onload
    script.onload = ->
      console.log "loaded and executed " + this.src
    #resolve(script)
    document.head.appendChild script
    #script.onerror = ->
    #  reject(script)


    @lclCodeCompiler = new LCLCodeCompiler
    @fps = 0
    world.steppingWdgts.add @

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

  initialiseWebGLStuff: ->
    @m4 = window.twgl.m4

    extent = @extent()
    # make a new canvas of the new size
    @glBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
    @gl = @glBuffer.getContext "webgl"

    # TODO which of this code can actually be done only once
    # instead of each time a gl canvas/context is created?


    vs = """uniform mat4 u_worldViewProjection;
    uniform vec3 u_lightWorldPos;
    uniform mat4 u_world;
    uniform mat4 u_viewInverse;
    uniform mat4 u_worldInverseTranspose;

    attribute vec4 position;
    attribute vec3 normal;
    attribute vec2 texcoord;

    varying vec4 v_position;
    varying vec2 v_texCoord;
    varying vec3 v_normal;
    varying vec3 v_surfaceToLight;
    varying vec3 v_surfaceToView;

    void main() {
      v_texCoord = texcoord;
    v_position = u_worldViewProjection * position;
    v_normal = (u_worldInverseTranspose * vec4(normal, 0)).xyz;
    v_surfaceToLight = u_lightWorldPos - (u_world * position).xyz;
    v_surfaceToView = (u_viewInverse[3] - (u_world * position)).xyz;
    gl_Position = v_position;
    }"""

    fs = """precision mediump float;
    varying vec4 v_position;
    varying vec2 v_texCoord;
    varying vec3 v_normal;
    varying vec3 v_surfaceToLight;
    varying vec3 v_surfaceToView;

    uniform vec4 u_lightColor;
    uniform vec4 u_ambient;
    uniform sampler2D u_diffuse;
    uniform vec4 u_specular;
    uniform float u_shininess;
    uniform float u_specularFactor;

    vec4 lit(float l ,float h, float m) {
      return vec4(1.0,
                  max(l, 0.0),
                  (l > 0.0) ? pow(max(0.0, h), m) : 0.0,
                  1.0);
    }

    void main() {
      vec4 diffuseColor = texture2D(u_diffuse, v_texCoord);
      vec3 a_normal = normalize(v_normal);
      vec3 surfaceToLight = normalize(v_surfaceToLight);
      vec3 surfaceToView = normalize(v_surfaceToView);
      vec3 halfVector = normalize(surfaceToLight + surfaceToView);
      vec4 litR = lit(dot(a_normal, surfaceToLight),
                        dot(a_normal, halfVector), u_shininess);
      vec4 outColor = vec4((
      u_lightColor * (diffuseColor * litR.y + diffuseColor * u_ambient +
                    u_specular * litR.z * u_specularFactor)).rgb,
          diffuseColor.a);
      gl_FragColor = outColor;
    }"""

    @programInfo = window.twgl.createProgramInfo @gl, [vs,fs]
    @arrays =
      position: [1, 1, -1, 1, 1, 1, 1, -1, 1, 1, -1, -1, -1, 1, 1, -1, 1, -1, -1, -1, -1, -1, -1, 1, -1, 1, 1, 1, 1, 1, 1, 1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1, 1, -1, 1, -1, -1, 1, 1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, -1, 1, 1, -1, 1, -1, -1, -1, -1, -1],
      normal: [1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1],
      texcoord: [1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1],
      indices: [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7, 8, 9, 10, 8, 10, 11, 12, 13, 14, 12, 14, 15, 16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23]

    @bufferInfo = window.twgl.createBufferInfoFromArrays(@gl, @arrays)
    @tex = window.twgl.createTexture @gl,
      min: @gl.NEAREST
      mag: @gl.NEAREST
      src: [255, 255, 255, 255, 192, 192, 192, 255, 192, 192, 192, 255, 255, 255, 255, 255]
    @uniforms =
      u_lightWorldPos: [1, 8, -10]
      u_lightColor: [1, 0.8, 0.8, 1]
      u_ambient: [0, 0, 0, 1]
      u_specular: [1, 1, 1, 1]
      u_shininess: 50
      u_specularFactor: 1
      u_diffuse: @tex


  paintNewFrame: ->
    # we get the context already with the correct pixel scaling
    # (ALWAYS leave the context with the correct pixel scaling.)
    #@clear()
    #context = @backBufferContext
    #context.translate @width()/2, @height()/2
    #try
    #  @graphicsCode()
    #catch
    #  @graphicsCode = @oldGraphicsCode


    if !window.twgl
      return
    else
      if !@gl or !(new Point @glBuffer.width, @glBuffer.height).equals @extent().scaleBy ceilPixelRatio
        @initialiseWebGLStuff()

    time = Date.now()/300
    #window.twgl.resizeCanvasToDisplaySize @gl.canvas
    # TODO this canvas should be resized when the widget resizes
    @gl.viewport 0, 0, @gl.canvas.width, @gl.canvas.height
    @gl.enable @gl.DEPTH_TEST
    @gl.enable @gl.CULL_FACE
    @gl.clear @gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT
    fov = 30 * Math.PI / 180
    aspect = @gl.canvas.width / @gl.canvas.height
    zNear = 0.5
    zFar = 10
    projection = @m4.perspective fov, aspect, zNear, zFar
    eye = [1,4,-6]
    target = [0,0,0]
    up = [0,1,0]
    camera = @m4.lookAt eye, target, up
    view = @m4.inverse camera
    viewProjection = @m4.multiply projection, view
    world = @m4.rotationY time
    @uniforms.u_viewInverse = camera
    @uniforms.u_world = world
    @uniforms.u_worldInverseTranspose = @m4.transpose @m4.inverse world
    @uniforms.u_worldViewProjection = @m4.multiply viewProjection, world
    @gl.useProgram @programInfo.program
    @bufferInfo.addInstanceProperties = nil
    @bufferInfo.augmentWith = nil
    delete @bufferInfo.addInstanceProperties
    delete @bufferInfo.augmentWith
    window.twgl.setBuffersAndAttributes @gl, @programInfo, @bufferInfo
    window.twgl.setUniforms @programInfo, @uniforms
    @gl.drawElements @gl.TRIANGLES, @bufferInfo.numElements, @gl.UNSIGNED_SHORT, 0

    # clear 2D canvas and paint it solid green first
    # (avoid this if you want to obtain a "paintover" effect)
    @backBufferContext.clearRect 0, 0, 1000, 1000
    @backBufferContext.fillStyle = 'rgb(0,255,0)'
    @backBufferContext.fillRect 0, 0, 1000, 1000

    # Draw WebGL canvas to this canvas.
    @backBufferContext.drawImage @glBuffer, 0, 0
    @changed()


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



    context = @backBufferContext
    if appendedFunctionsStartIndex?
      context.save()


    # odd things happen setting scale to zero
    arg_a = 0.000000001  if arg_a > -0.000000001 and arg_a < 0.000000001
    arg_b = 0.000000001  if arg_b > -0.000000001 and arg_b < 0.000000001
    arg_c = 0.000000001  if arg_c > -0.000000001 and arg_c < 0.000000001

    context.scale arg_a, arg_b

    if appendedFunctionsStartIndex?
      while Utils.isFunction arguments[appendedFunctionsStartIndex]
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

    context.rotate arg_a

    if appendedFunctionsStartIndex?
      while Utils.isFunction arguments[appendedFunctionsStartIndex]
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
      if Utils.isFunction arg_a then appendedFunctionsStartIndex = 0

      d = new Date
      n = d.getTime()

      arg_a = Math.sin(n/150) * 15
      arg_b = Math.cos(n/150) * 15
      arg_c = arg_a
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

    context.translate arg_a, arg_b

    if appendedFunctionsStartIndex?
      while Utils.isFunction arguments[appendedFunctionsStartIndex]
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
      if Utils.isFunction a then appendedFunction = a
      a = 1
      b = 1
      c = 1
    else if typeof b isnt "number"
      if Utils.isFunction b then appendedFunction = b
      b = a
      c = a
    else if typeof c isnt "number"
      if Utils.isFunction c then appendedFunction = c
      c = 1
    else if Utils.isFunction d
      appendedFunction = d

    #context.beginPath()
    #context.lineWidth="6"
    #context.strokeStyle=Color.RED.toString()
    #context.rect(5,5,290,140)
    #context.stroke()

    @backBufferContext.strokeStyle = Color.BLACK.toString()
    @backBufferContext.beginPath()
    @backBufferContext.rect -50,-50,100,100
    @backBufferContext.stroke()

    @changed()

    if appendedFunction? then appendedFunction.apply @
    return
