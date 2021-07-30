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


  # crafty function from https://github.com/search?q=setUpBarycentricCoordinates&type=code
  setUpBarycentricCoordinates: (positions, normals) ->
    # Build new attribute storing barycentric coordinates
    # for each vertex
    centers = []
    # start with all edges disabled
    # Hash all the edges and remember which face they're associated with
    # (Adapted from THREE.EdgesHelper)

    sortFunction = (a, b) ->
      if a[0] - (b[0]) != 0
        a[0] - (b[0])
      else if a[1] - (b[1]) != 0
        a[1] - (b[1])
      else
        a[2] - (b[2])

    f = 0
    while f < positions.length
      centers[f] = 1
      f++
    edge = [0,0]
    hash = {}
    face = undefined
    numEdges = 0

    for i in [0...positions.length / 9]
      a = i * 9
      face = [
        [
          positions[a + 0]
          positions[a + 1]
          positions[a + 2]
        ]
        [
          positions[a + 3]
          positions[a + 4]
          positions[a + 5]
        ]
        [
          positions[a + 6]
          positions[a + 7]
          positions[a + 8]
        ]
      ]
      for j in [0...3]
        console.log "considering an edge"
        k = (j + 1) % 3
        b = j * 3
        c = k * 3
        edge[0] = face[j]
        edge[1] = face[k]
        edge.sort sortFunction
        key = edge[0] + ' | ' + edge[1]
        if !hash[key]?
          hash[key] =
            face1: a
            face1vert1: a + b
            face1vert2: a + c
            face2: undefined
            face2vert1: undefined
            face2vert2: undefined
          numEdges++
        else
          hash[key].face2 = a
          hash[key].face2vert1 = a + b
          hash[key].face2vert2 = a + c
          console.log "one edge in common with two triangles"
    dot = (a, b) => a.map((x, i) => a[i] * b[i]).reduce((m, n) => m + n)
    for key of hash
      `key = key`
      h = hash[key]
      # ditch any edges that are bordered by two coplanar faces
      normal1 = undefined
      normal2 = undefined
      if h.face2 != undefined
        normal1 = [normals[h.face1 + 0], normals[h.face1 + 1], normals[h.face1 + 2]]
        normal2 = [normals[h.face2 + 0], normals[h.face2 + 1], normals[h.face2 + 2]]
        console.log "dot: " + dot(normal1, normal2)
        if dot(normal1, normal2) >= 0.9999
          console.log("skipping co-planar edge")
          continue
      # mark edge vertices as such by altering barycentric coordinates
      otherVert = undefined
      otherVert = 3 - (h.face1vert1 / 3 % 3) - (h.face1vert2 / 3 % 3)
      centers[h.face1vert1 + otherVert] = 0
      centers[h.face1vert2 + otherVert] = 0
      otherVert = 3 - (h.face2vert1 / 3 % 3) - (h.face2vert2 / 3 % 3)
      centers[h.face2vert1 + otherVert] = 0
      centers[h.face2vert2 + otherVert] = 0
    return centers

  barycentricCoordinates: (bufferGeometry, removeEdge) ->
    count = bufferGeometry.length / 9
    barycentric = []
    # for each triangle in the geometry, add the barycentric coordinates
    i = 0
    while i < count
      even = i % 2 == 0
      Q = if removeEdge then 1 else 0
      if !even
        barycentric.push 0, 0, 1, 0, 1, 0, 1, 0, Q
      else
        barycentric.push 0, 1, 0, 0, 0, 1, 1, 0, Q
      i++
    # add the attribute to the geometry
    return barycentric

  initialiseWebGLStuff: ->
    @m4 = window.twgl.m4

    extent = @extent()
    # make a new canvas of the new size
    @glBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
    @gl = @glBuffer.getContext "webgl"

    # needed for fwidth function
    @gl.getExtension('OES_standard_derivatives')

    # TODO which of this code can actually be done only once
    # instead of each time a gl canvas/context is created?


    # wireframe shader/setup from https://github.com/mattdesl/webgl-wireframes
    vs = """uniform mat4 u_worldViewProjection;
      uniform vec3 u_lightWorldPos;
      uniform mat4 u_world;
      uniform mat4 u_viewInverse;
      uniform mat4 u_worldInverseTranspose;

      attribute vec4 position;
      attribute vec3 normal;

      varying vec4 v_position;
      varying vec3 v_normal;
      varying vec3 v_surfaceToLight;
      varying vec3 v_surfaceToView;

      attribute vec3 barycentric;
      attribute float even;
      varying vec3 vBarycentric;
      varying float vEven;

      void main() {
        vBarycentric = barycentric;
        vEven = even;

        v_position = u_worldViewProjection * position;
        v_normal = (u_worldInverseTranspose * vec4(normal, 0)).xyz;
        v_surfaceToLight = u_lightWorldPos - (u_world * position).xyz;
        v_surfaceToView = (u_viewInverse[3] - (u_world * position)).xyz;
        gl_Position = v_position;
      }"""

    fs = """#extension GL_OES_standard_derivatives : enable
      // line above needed for fwidth function
      precision mediump float;
      varying vec3 vBarycentric;
      varying float vEven;
      varying vec2 v_normal;
      varying vec4 v_position;

      uniform float time;
      uniform float thickness;
      uniform float secondThickness;

      uniform float dashRepeats;
      uniform float dashLength;
      uniform bool dashOverlap;
      uniform bool dashEnabled;
      uniform bool dashAnimate;

      uniform bool seeThrough;
      uniform bool insideAltColor;
      uniform bool dualStroke;
      uniform bool noiseA;
      uniform bool noiseB;

      uniform bool squeeze;
      uniform float squeezeMin;
      uniform float squeezeMax;

      uniform vec3 stroke;
      uniform vec3 fill;

      // This is like
      float aastep (float threshold, float dist) {
        float afwidth = fwidth(dist) * 0.5;
        return smoothstep(threshold - afwidth, threshold + afwidth, dist);
      }

      // This function is not currently used, but it can be useful
      // to achieve a fixed width wireframe regardless of z-depth
      //float computeScreenSpaceWireframe (vec3 barycentric, float lineWidth) {
      //  vec3 dist = fwidth(barycentric);
      //  vec3 smoothed = smoothstep(dist * ((lineWidth * 0.5) - 0.5), dist * ((lineWidth * 0.5) + 0.5), barycentric);
      //  return 1.0 - min(min(smoothed.x, smoothed.y), smoothed.z);
      //}

      // This function returns the fragment color for our styled wireframe effect
      // based on the barycentric coordinates for this fragment
      vec4 getStyledWireframe (vec3 barycentric) {
        // this will be our signed distance for the wireframe edge
        float d = min(min(barycentric.x, barycentric.y), barycentric.z);


        // for dashed rendering, we can use this to get the 0 .. 1 value of the line length
        float positionAlong = max(barycentric.x, barycentric.y);
        if (barycentric.y < barycentric.x && barycentric.y < barycentric.z) {
          positionAlong = 1.0 - positionAlong;
        }

        // the thickness of the stroke
        float computedThickness = thickness;

        // if we want to shrink the thickness toward the center of the line segment
        //if (squeeze) {
        //  computedThickness *= mix(squeezeMin, squeezeMax, (1.0 - sin(positionAlong * PI)));
        //}

        // if we should create a dash pattern
        if (dashEnabled) {
          // here we offset the stroke position depending on whether it
          // should overlap or not
          float offset = 1.0 / dashRepeats * dashLength / 2.0;
          if (!dashOverlap) {
            offset += 1.0 / dashRepeats / 2.0;
          }

          // if we should animate the dash or not
          if (dashAnimate) {
            offset += time * 0.22;
          }

          // create the repeating dash pattern
          //float pattern = fract((positionAlong + offset) * dashRepeats);
          //computedThickness *= 1.0 - aastep(dashLength, pattern);
        }

        // compute the anti-aliased stroke edge
        float edge = 1.0 - aastep(computedThickness, d);
        //float edge = 1.0;

        // now compute the final color of the mesh
        vec4 outColor = vec4(0.0);
        if (seeThrough) {
          outColor = vec4(stroke, edge);
          if (insideAltColor && !gl_FrontFacing) {
            outColor.rgb = fill;
          }
        } else {
          vec3 mainStroke = mix(fill, stroke, edge);
          outColor.a = 1.0;
          if (dualStroke) {
            float inner = 1.0 - aastep(secondThickness, d);
            //float inner = 1.0;
            vec3 wireColor = mix(fill, stroke, abs(inner - edge));
            outColor.rgb = wireColor;
          } else {
            outColor.rgb = mainStroke;
          }
        }

        return outColor;
      }

      void main () {
        gl_FragColor = getStyledWireframe(vBarycentric);
      }"""

    @programInfo = window.twgl.createProgramInfo @gl, [vs,fs]

    # ------ un-indexed, 108 positions (6 faces, 2 triangles each, 3 vertexes per triangle, 3 coordinates)
    # this is the only way I can get it to avoid drawing the "inner" wires of the wireframes,
    # because handling those with indexes was
    # tricky (potentially impossible?)
    # The un-indexed data (positions and normals) I just got by doing
    #    new THREE.BoxBufferGeometry(1,1,1);
    # and looking inside of that object.
    @arrays =
      position: [0.5,0.5,0.5,0.5,-0.5,0.5,0.5,0.5,-0.5,0.5,-0.5,0.5,0.5,-0.5,-0.5,0.5,0.5,-0.5,-0.5,0.5,-0.5,-0.5,-0.5,-0.5,-0.5,0.5,0.5,-0.5,-0.5,-0.5,-0.5,-0.5,0.5,-0.5,0.5,0.5,-0.5,0.5,-0.5,-0.5,0.5,0.5,0.5,0.5,-0.5,-0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,-0.5,-0.5,-0.5,0.5,-0.5,-0.5,-0.5,0.5,-0.5,0.5,-0.5,-0.5,-0.5,0.5,-0.5,-0.5,0.5,-0.5,0.5,-0.5,0.5,0.5,-0.5,-0.5,0.5,0.5,0.5,0.5,-0.5,-0.5,0.5,0.5,-0.5,0.5,0.5,0.5,0.5,0.5,0.5,-0.5,0.5,-0.5,-0.5,-0.5,0.5,-0.5,0.5,-0.5,-0.5,-0.5,-0.5,-0.5,-0.5,0.5,-0.5]
      normal: [1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1]
    @arrays.barycentric = @setUpBarycentricCoordinates(@arrays.position, @arrays.normal)


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
      time: 0
      fill: [255,0,0]
      stroke: [0,0,255]
      noiseA: false
      noiseB: false
      dualStroke: false
      seeThrough: false
      insideAltColor: true
      thickness: 0.1
      secondThickness: 0.05
      dashEnabled: true
      dashRepeats: 2.0
      dashOverlap: false
      dashLength: 0.55
      dashAnimate: false
      squeeze: false
      squeezeMin: 0.1
      squeezeMax: 1.0

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

    time = Date.now()/600
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

    world = @m4.multiply (@m4.rotationX time),(@m4.rotationZ time)

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

    window.twgl.drawBufferInfo @gl, @bufferInfo

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
