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
  tex: nil
  uniforms: nil

  cubeBufferInfo: nil
  sphereBufferInfo: nil

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

    # TODO id: REDUNDANT_CODE_TO_LOAD_JS date: 10-Jun-2023
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
    @changed()


  unindexBufferGeometry: (bufferGeometry) ->
    # un-indices the geometry, copying all attributes like position and uv
    indexArray = bufferGeometry.indices
    triangleCount = indexArray.length / 3

    attributes = Object.getOwnPropertyNames bufferGeometry

    removeItemOnce = (arr, value) ->
      index = arr.indexOf(value)
      if index > -1
        arr.splice index, 1
      arr
    attributes = removeItemOnce(attributes, "indices")

    newAttribData = attributes.map((key) ->
      {
        name: key
        array: []
        attribute: bufferGeometry[key]
      }
    )
    for i in [0...triangleCount]
      # indices into attributes
      a = indexArray[i * 3 + 0]
      b = indexArray[i * 3 + 1]
      c = indexArray[i * 3 + 2]
      indices = [a, b, c]
      # for each attribute, put vertex into unindexed list
      newAttribData.forEach (data) ->
        attrib = data.attribute
        dim = 3
        # add [a, b, c] vertices
        for j in [0...indices.length]
          index = indices[j]
          for d in [0...dim]
            v = attrib[index * dim + d]
            data.array.push v
        return


    # now copy over new data
    newAttribData.forEach (data) ->
      bufferGeometry[data.name] = data.array
      return

    bufferGeometry.indices = nil
    delete bufferGeometry.indices

    return

  # check if [x,y,x] is on same plane as p1, p2, p3
  coPlanar: (x1, y1, z1, x2, y2, z2, x3, y3, z3, x, y, z) ->
    # derive a,b,c of the (3d) plane equation a*x + b*y + c*z = 0
    # form the three given points p1, p2, p3
    a1 = x2 - x1
    b1 = y2 - y1
    c1 = z2 - z1
    a2 = x3 - x1
    b2 = y3 - y1
    c2 = z3 - z1
    a = b1 * c2 - (b2 * c1)
    b = a2 * c1 - (a1 * c2)
    c = a1 * b2 - (b1 * a2)
    d = -a * x1 - (b * y1) - (c * z1)
    # check if the 4th point (x,y,z) roughly satisfies
    # the plane equation
    Math.abs(a * x + b * y + c * z + d) < 0.0001

  # This only works with the way Three.js creates the geometry
  barycentricCoordinates: (bufferGeometry, removeEdge) ->
    count = bufferGeometry.length / 9
    barycentric = []
    # for each triangle in the geometry, add the barycentric coordinates
    for i in [0...count]
      even = i % 2 == 0
      pos = bufferGeometry

      # in the previous implementation there were artifacts at the "top" and "bottom"
      # of spheres, where triangles don't define quads "in pairs", and some
      # edges would be missing. I added this additional flag to only enable
      # edge removal when we are on a triangle that is co-planar with the one
      # before or the one after (because to remove an edge you need to treat *both*
      # triangles along an edge, otherwise you still see half an edge)
      # This is sort of a hack because it only works when geometry is generated in a
      # specific way where quads are made of consecutive triangles - while this is
      # not generally true, it works when Three.js generates the geometry, which is what
      # this algorithm was assuming before anyways.
      consecutiveCoPlanarFaces = false
      if i > 0 and i < count - 1
        consecutiveCoPlanarFacesBefore = (@coPlanar pos[i*9 + 0], pos[i*9 + 1], pos[i*9 + 2], pos[i*9 + 3], pos[i*9 + 4], pos[i*9 + 5], pos[i*9 + 6], pos[i*9 + 7], pos[i*9 + 8], pos[(i-1)*9 + 0], pos[(i-1)*9 + 1], pos[(i-1)*9 + 2]) and
        (@coPlanar pos[i*9 + 0], pos[i*9 + 1], pos[i*9 + 2], pos[i*9 + 3], pos[i*9 + 4], pos[i*9 + 5], pos[i*9 + 6], pos[i*9 + 7], pos[i*9 + 8], pos[(i-1)*9 + 3], pos[(i-1)*9 + 4], pos[(i-1)*9 + 5]) and
        (@coPlanar pos[i*9 + 0], pos[i*9 + 1], pos[i*9 + 2], pos[i*9 + 3], pos[i*9 + 4], pos[i*9 + 5], pos[i*9 + 6], pos[i*9 + 7], pos[i*9 + 8], pos[(i-1)*9 + 6], pos[(i-1)*9 + 7], pos[(i-1)*9 + 8])

        consecutiveCoPlanarFacesAfter = (@coPlanar pos[i*9 + 0], pos[i*9 + 1], pos[i*9 + 2], pos[i*9 + 3], pos[i*9 + 4], pos[i*9 + 5], pos[i*9 + 6], pos[i*9 + 7], pos[i*9 + 8], pos[(i+1)*9 + 0], pos[(i+1)*9 + 1], pos[(i+1)*9 + 2]) and
        (@coPlanar pos[i*9 + 0], pos[i*9 + 1], pos[i*9 + 2], pos[i*9 + 3], pos[i*9 + 4], pos[i*9 + 5], pos[i*9 + 6], pos[i*9 + 7], pos[i*9 + 8], pos[(i+1)*9 + 3], pos[(i+1)*9 + 4], pos[(i+1)*9 + 5]) and
        (@coPlanar pos[i*9 + 0], pos[i*9 + 1], pos[i*9 + 2], pos[i*9 + 3], pos[i*9 + 4], pos[i*9 + 5], pos[i*9 + 6], pos[i*9 + 7], pos[i*9 + 8], pos[(i+1)*9 + 6], pos[(i+1)*9 + 7], pos[(i+1)*9 + 8])

        consecutiveCoPlanarFaces = consecutiveCoPlanarFacesBefore or consecutiveCoPlanarFacesAfter

      Q = if removeEdge and consecutiveCoPlanarFaces then 1 else 0

      if even
        barycentric.push 0, 0, 1, 0, 1, 0, 1, 0, Q
      else
        barycentric.push 0, 1, 0, 0, 0, 1, 1, 0, Q
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
    # see also:
    #   https://tchayen.github.io/posts/wireframes-with-barycentric-coordinates
    #   https://catlikecoding.com/unity/tutorials/advanced-rendering/flat-and-wireframe-shading/
    #   any search with "wireframe" and "barycentric"
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

    # Generating the geometries -------------------------------------------------------------
    # Generating geometries that are wireframe-friendly is no trivial business
    # because one needs to add barycentric coordinates.
    # Doing so while doing a good job at "redundant" edge removal (i.e. where
    # quads are split into two triangles and you can see the separation between the two)
    # is non-trivial, because these steps:
    #  1. generate "original" geometry, with indexes
    #  2. de-indexing necessary to calculate barycentric coordinates
    #  3. actually calculating the barycentric coordinates while removing redundant edges
    # ...are non-trivial to get to work harmoniously in a general and elegant way,
    # so what we do instead is we find a specific "pipeline" that just happens to works and
    # call it a day.

    # ---------  box -----------
    verts = {}
    # Un-indexed: 108 positions (6 faces, 2 triangles each, 3 vertexes per triangle, 3 coordinates)
    # This one can be generated programmatically by doing:
    #   verts = window.twgl.primitives.createCubeVertices 1
    #   @unindexBufferGeometry verts
    #   verts.barycentric = @setUpBarycentricCoordinates(verts.position, verts.normal)
    # however the setUpBarycentricCoordinates function is specific just for this, so we removed it
    # on 3/8/2021 and just baked in here the result.
    verts.position = [0.5,0.5,-0.5,0.5,0.5,0.5,0.5,-0.5,0.5,0.5,0.5,-0.5,0.5,-0.5,0.5,0.5,-0.5,-0.5,-0.5,0.5,0.5,-0.5,0.5,-0.5,-0.5,-0.5,-0.5,-0.5,0.5,0.5,-0.5,-0.5,-0.5,-0.5,-0.5,0.5,-0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,-0.5,-0.5,0.5,0.5,0.5,0.5,-0.5,-0.5,0.5,-0.5,-0.5,-0.5,-0.5,0.5,-0.5,-0.5,0.5,-0.5,0.5,-0.5,-0.5,-0.5,0.5,-0.5,0.5,-0.5,-0.5,0.5,0.5,0.5,0.5,-0.5,0.5,0.5,-0.5,-0.5,0.5,0.5,0.5,0.5,-0.5,-0.5,0.5,0.5,-0.5,0.5,-0.5,0.5,-0.5,0.5,0.5,-0.5,0.5,-0.5,-0.5,-0.5,0.5,-0.5,0.5,-0.5,-0.5,-0.5,-0.5,-0.5]
    verts.normal = [1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1,0,0,-1]
    verts.barycentric = [1,1,0,0,1,0,0,1,1,1,0,1,0,1,1,0,0,1,1,1,0,0,1,0,0,1,1,1,0,1,0,1,1,0,0,1,1,1,0,0,1,0,0,1,1,1,0,1,0,1,1,0,0,1,1,1,0,0,1,0,0,1,1,1,0,1,0,1,1,0,0,1,1,1,0,0,1,0,0,1,1,1,0,1,0,1,1,0,0,1,1,1,0,0,1,0,0,1,1,1,0,1,0,1,1,0,0,1]
    @cubeBufferInfo = window.twgl.createBufferInfoFromArrays @gl, verts


    # ---------  ball -----------
    verts = {}
    # geometry obtained via Three.js by doing:
    # myGeometry = new THREE.SphereBufferGeometry(0.7,12,6);
    # console.log(""+myGeometry.index.array)
    # console.log(""+myGeometry.attributes.position.array)
    # console.log(""+myGeometry.attributes.normal.array)
    # see also https://github.com/mrdoob/three.js/blob/master/src/geometries/SphereGeometry.js
    verts.position = [0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,0,0.699999988079071,0,-0.3499999940395355,0.6062178015708923,0,-0.30310890078544617,0.6062178015708923,0.17499999701976776,-0.17499999701976776,0.6062178015708923,0.30310890078544617,-2.1431318265879212e-17,0.6062178015708923,0.3499999940395355,0.17499999701976776,0.6062178015708923,0.30310890078544617,0.30310890078544617,0.6062178015708923,0.17499999701976776,0.3499999940395355,0.6062178015708923,4.2862636531758425e-17,0.30310890078544617,0.6062178015708923,-0.17499999701976776,0.17499999701976776,0.6062178015708923,-0.30310890078544617,6.429395645199886e-17,0.6062178015708923,-0.3499999940395355,-0.17499999701976776,0.6062178015708923,-0.30310890078544617,-0.30310890078544617,0.6062178015708923,-0.17499999701976776,-0.3499999940395355,0.6062178015708923,-8.572527306351685e-17,-0.6062178015708923,0.3499999940395355,0,-0.5249999761581421,0.3499999940395355,0.30310890078544617,-0.30310890078544617,0.3499999940395355,0.5249999761581421,-3.712013365245604e-17,0.3499999940395355,0.6062178015708923,0.30310890078544617,0.3499999940395355,0.5249999761581421,0.5249999761581421,0.3499999940395355,0.30310890078544617,0.6062178015708923,0.3499999940395355,7.424026730491209e-17,0.5249999761581421,0.3499999940395355,-0.30310890078544617,0.30310890078544617,0.3499999940395355,-0.5249999761581421,1.1136040095736813e-16,0.3499999940395355,-0.6062178015708923,-0.30310890078544617,0.3499999940395355,-0.5249999761581421,-0.5249999761581421,0.3499999940395355,-0.30310890078544617,-0.6062178015708923,0.3499999940395355,-1.4848053460982417e-16,-0.699999988079071,4.2862636531758425e-17,0,-0.6062178015708923,4.2862636531758425e-17,0.3499999940395355,-0.3499999940395355,4.2862636531758425e-17,0.6062178015708923,-4.2862636531758425e-17,4.2862636531758425e-17,0.699999988079071,0.3499999940395355,4.2862636531758425e-17,0.6062178015708923,0.6062178015708923,4.2862636531758425e-17,0.3499999940395355,0.699999988079071,4.2862636531758425e-17,8.572527306351685e-17,0.6062178015708923,4.2862636531758425e-17,-0.3499999940395355,0.3499999940395355,4.2862636531758425e-17,-0.6062178015708923,1.2858791290399772e-16,4.2862636531758425e-17,-0.699999988079071,-0.3499999940395355,4.2862636531758425e-17,-0.6062178015708923,-0.6062178015708923,4.2862636531758425e-17,-0.3499999940395355,-0.699999988079071,4.2862636531758425e-17,-1.714505461270337e-16,-0.6062178015708923,-0.3499999940395355,0,-0.5249999761581421,-0.3499999940395355,0.30310890078544617,-0.30310890078544617,-0.3499999940395355,0.5249999761581421,-3.712013365245604e-17,-0.3499999940395355,0.6062178015708923,0.30310890078544617,-0.3499999940395355,0.5249999761581421,0.5249999761581421,-0.3499999940395355,0.30310890078544617,0.6062178015708923,-0.3499999940395355,7.424026730491209e-17,0.5249999761581421,-0.3499999940395355,-0.30310890078544617,0.30310890078544617,-0.3499999940395355,-0.5249999761581421,1.1136040095736813e-16,-0.3499999940395355,-0.6062178015708923,-0.30310890078544617,-0.3499999940395355,-0.5249999761581421,-0.5249999761581421,-0.3499999940395355,-0.30310890078544617,-0.6062178015708923,-0.3499999940395355,-1.4848053460982417e-16,-0.3499999940395355,-0.6062178015708923,0,-0.30310890078544617,-0.6062178015708923,0.17499999701976776,-0.17499999701976776,-0.6062178015708923,0.30310890078544617,-2.1431318265879212e-17,-0.6062178015708923,0.3499999940395355,0.17499999701976776,-0.6062178015708923,0.30310890078544617,0.30310890078544617,-0.6062178015708923,0.17499999701976776,0.3499999940395355,-0.6062178015708923,4.2862636531758425e-17,0.30310890078544617,-0.6062178015708923,-0.17499999701976776,0.17499999701976776,-0.6062178015708923,-0.30310890078544617,6.429395645199886e-17,-0.6062178015708923,-0.3499999940395355,-0.17499999701976776,-0.6062178015708923,-0.30310890078544617,-0.30310890078544617,-0.6062178015708923,-0.17499999701976776,-0.3499999940395355,-0.6062178015708923,-8.572527306351685e-17,-8.572527306351685e-17,-0.699999988079071,0,-7.424026730491209e-17,-0.699999988079071,4.2862636531758425e-17,-4.2862636531758425e-17,-0.699999988079071,7.424026730491209e-17,-5.2491593706793705e-33,-0.699999988079071,8.572527306351685e-17,4.2862636531758425e-17,-0.699999988079071,7.424026730491209e-17,7.424026730491209e-17,-0.699999988079071,4.2862636531758425e-17,8.572527306351685e-17,-0.699999988079071,1.0498318741358741e-32,7.424026730491209e-17,-0.699999988079071,-4.2862636531758425e-17,4.2862636531758425e-17,-0.699999988079071,-7.424026730491209e-17,1.5747477744696127e-32,-0.699999988079071,-8.572527306351685e-17,-4.2862636531758425e-17,-0.699999988079071,-7.424026730491209e-17,-7.424026730491209e-17,-0.699999988079071,-4.2862636531758425e-17,-8.572527306351685e-17,-0.699999988079071,-2.0996637482717482e-32]
    verts.normal = [0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,-0.5,0.8660253882408142,0,-0.4330126941204071,0.8660253882408142,0.25,-0.25,0.8660253882408142,0.4330126941204071,-3.0616171314629196e-17,0.8660253882408142,0.5,0.25,0.8660253882408142,0.4330126941204071,0.4330126941204071,0.8660253882408142,0.25,0.5,0.8660253882408142,6.123234262925839e-17,0.4330126941204071,0.8660253882408142,-0.25,0.25,0.8660253882408142,-0.4330126941204071,9.184850732644269e-17,0.8660253882408142,-0.5,-0.25,0.8660253882408142,-0.4330126941204071,-0.4330126941204071,0.8660253882408142,-0.25,-0.5,0.8660253882408142,-1.2246468525851679e-16,-0.8660253882408142,0.5,0,-0.75,0.5,0.4330126941204071,-0.4330126941204071,0.5,0.75,-5.302876236065149e-17,0.5,0.8660253882408142,0.4330126941204071,0.5,0.75,0.75,0.5,0.4330126941204071,0.8660253882408142,0.5,1.0605752472130298e-16,0.75,0.5,-0.4330126941204071,0.4330126941204071,0.5,-0.75,1.5908628708195447e-16,0.5,-0.8660253882408142,-0.4330126941204071,0.5,-0.75,-0.75,0.5,-0.4330126941204071,-0.8660253882408142,0.5,-2.1211504944260596e-16,-1,6.123234262925839e-17,0,-0.8660253882408142,6.123234262925839e-17,0.5,-0.5,6.123234262925839e-17,0.8660253882408142,-6.123234262925839e-17,6.123234262925839e-17,1,0.5,6.123234262925839e-17,0.8660253882408142,0.8660253882408142,6.123234262925839e-17,0.5,1,6.123234262925839e-17,1.2246468525851679e-16,0.8660253882408142,6.123234262925839e-17,-0.5,0.5,6.123234262925839e-17,-0.8660253882408142,1.8369701465288538e-16,6.123234262925839e-17,-1,-0.5,6.123234262925839e-17,-0.8660253882408142,-0.8660253882408142,6.123234262925839e-17,-0.5,-1,6.123234262925839e-17,-2.4492937051703357e-16,-0.8660253882408142,-0.5,0,-0.75,-0.5,0.4330126941204071,-0.4330126941204071,-0.5,0.75,-5.302876236065149e-17,-0.5,0.8660253882408142,0.4330126941204071,-0.5,0.75,0.75,-0.5,0.4330126941204071,0.8660253882408142,-0.5,1.0605752472130298e-16,0.75,-0.5,-0.4330126941204071,0.4330126941204071,-0.5,-0.75,1.5908628708195447e-16,-0.5,-0.8660253882408142,-0.4330126941204071,-0.5,-0.75,-0.75,-0.5,-0.4330126941204071,-0.8660253882408142,-0.5,-2.1211504944260596e-16,-0.5,-0.8660253882408142,0,-0.4330126941204071,-0.8660253882408142,0.25,-0.25,-0.8660253882408142,0.4330126941204071,-3.0616171314629196e-17,-0.8660253882408142,0.5,0.25,-0.8660253882408142,0.4330126941204071,0.4330126941204071,-0.8660253882408142,0.25,0.5,-0.8660253882408142,6.123234262925839e-17,0.4330126941204071,-0.8660253882408142,-0.25,0.25,-0.8660253882408142,-0.4330126941204071,9.184850732644269e-17,-0.8660253882408142,-0.5,-0.25,-0.8660253882408142,-0.4330126941204071,-0.4330126941204071,-0.8660253882408142,-0.25,-0.5,-0.8660253882408142,-1.2246468525851679e-16,-1.2246468525851679e-16,-1,0,-1.0605752472130298e-16,-1,6.123234262925839e-17,-6.123234262925839e-17,-1,1.0605752472130298e-16,-7.498798786105971e-33,-1,1.2246468525851679e-16,6.123234262925839e-17,-1,1.0605752472130298e-16,1.0605752472130298e-16,-1,6.123234262925839e-17,1.2246468525851679e-16,-1,1.4997597572211942e-32,1.0605752472130298e-16,-1,-6.123234262925839e-17,6.123234262925839e-17,-1,-1.0605752472130298e-16,2.2496396358317913e-32,-1,-1.2246468525851679e-16,-6.123234262925839e-17,-1,-1.0605752472130298e-16,-1.0605752472130298e-16,-1,-6.123234262925839e-17,-1.2246468525851679e-16,-1,-2.9995195144423884e-32]
    verts.indices = [0,13,14,1,14,15,2,15,16,3,16,17,4,17,18,5,18,19,6,19,20,7,20,21,8,21,22,9,22,23,10,23,24,11,24,25,14,13,27,13,26,27,15,14,28,14,27,28,16,15,29,15,28,29,17,16,30,16,29,30,18,17,31,17,30,31,19,18,32,18,31,32,20,19,33,19,32,33,21,20,34,20,33,34,22,21,35,21,34,35,23,22,36,22,35,36,24,23,37,23,36,37,25,24,38,24,37,38,27,26,40,26,39,40,28,27,41,27,40,41,29,28,42,28,41,42,30,29,43,29,42,43,31,30,44,30,43,44,32,31,45,31,44,45,33,32,46,32,45,46,34,33,47,33,46,47,35,34,48,34,47,48,36,35,49,35,48,49,37,36,50,36,49,50,38,37,51,37,50,51,40,39,53,39,52,53,41,40,54,40,53,54,42,41,55,41,54,55,43,42,56,42,55,56,44,43,57,43,56,57,45,44,58,44,57,58,46,45,59,45,58,59,47,46,60,46,59,60,48,47,61,47,60,61,49,48,62,48,61,62,50,49,63,49,62,63,51,50,64,50,63,64,53,52,66,52,65,66,54,53,67,53,66,67,55,54,68,54,67,68,56,55,69,55,68,69,57,56,70,56,69,70,58,57,71,57,70,71,59,58,72,58,71,72,60,59,73,59,72,73,61,60,74,60,73,74,62,61,75,61,74,75,63,62,76,62,75,76,64,63,77,63,76,77,66,65,79,67,66,80,68,67,81,69,68,82,70,69,83,71,70,84,72,71,85,73,72,86,74,73,87,75,74,88,76,75,89,77,76,90]
    @unindexBufferGeometry verts
    verts.barycentric = @barycentricCoordinates verts.position, true

    @sphereBufferInfo = window.twgl.createBufferInfoFromArrays @gl, verts



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

    for bufferInfo in [@cubeBufferInfo, @sphereBufferInfo]
      #for bufferInfo in [@cubeBufferInfo]

      lastUsedProgramInfo = nil
      lastUsedBufferInfo = nil

      # "draw multiple things" in a reasonably optimised way
      # and yet keeping things simple, using the mechanism suggested here:
      #   https://webglfundamentals.org/webgl/lessons/webgl-drawing-multiple-things.html
      # There would be a more optimised way called "instanced drawing", see:
      #   https://webglfundamentals.org/webgl/lessons/webgl-instanced-drawing.html
      # which uses a webgl extension available practically everywhere (see drawArraysInstancedANGLE)
      # however the benefit is unclear because it usually pays-off when a ton of stuff
      # needs drawing, in which case the bottleneck is on the "fill" rather than here.
      # see comment towards the end of the blogpost here:
      #   https://blog.tojicode.com/2013/07/webgl-instancing-with.html
      # We can still do that later if profiler shows there is a bottleneck here.
      for i in [1...3]
        #for i in [1...2]
        setBuffersAndAttributes = false

        if @programInfo != lastUsedProgramInfo
          lastUsedProgramInfo = @programInfo
          @gl.useProgram @programInfo.program
          setBuffersAndAttributes = true

        if setBuffersAndAttributes or lastUsedBufferInfo != bufferInfo
          lastUsedBufferInfo = bufferInfo
          bufferInfo.addInstanceProperties = nil
          bufferInfo.augmentWith = nil
          delete bufferInfo.addInstanceProperties
          delete bufferInfo.augmentWith
          window.twgl.setBuffersAndAttributes @gl, @programInfo, bufferInfo

        eye = [1,4,-6]
        target = [0,0,0]
        up = [0,1,0]
        camera = @m4.lookAt eye, target, up
        view = @m4.inverse camera
        viewProjection = @m4.multiply projection, view

        world = @m4.multiply (@m4.rotationX time*i/2),(@m4.rotationZ time*i/2)

        @uniforms.u_viewInverse = camera
        @uniforms.u_world = world
        @uniforms.u_worldInverseTranspose = @m4.transpose @m4.inverse world
        @uniforms.u_worldViewProjection = @m4.multiply viewProjection, world

        window.twgl.setUniforms @programInfo, @uniforms
        window.twgl.drawBufferInfo @gl, bufferInfo

    # clear 2D canvas and paint it solid green first
    # (avoid this if you want to obtain a "paintover" effect)
    @backBufferContext.clearRect 0, 0, 1000, 1000
    @backBufferContext.fillStyle = 'rgb(0,255,0)'
    @backBufferContext.fillRect 0, 0, 1000, 1000

    # Draw WebGL canvas to this canvas.
    @backBufferContext.drawImage @glBuffer, 0, 0


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
