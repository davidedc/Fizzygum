# Class ////////////////////////////////////////////////////////////

class Class
  @allClasses: []
  nonStaticPropertiesSources: nil
  staticPropertiesSources: nil
  name: ""
  superClassName: nil
  augmentedWith: nil
  superClass: nil
  subClasses: nil
  

  # adds code into the constructor, such that when a
  # Morph is created, it registers itself as in instance
  # on the Class it belongs to AND TO ALL THE SUPERKLASSES
  # The way it's added to all the superclasses is via
  # the constructor always calling "super", so constructors
  # up the chain cause the object to register itself
  # with all the superclasses.
  # this mechanism can be tested by opening an AnalogClockMorph and
  # then from the console:
  #  world.children[0].constructor.instances[0] === world.children[0]
  # or
  #  AnalogClockMorph.instances[0] === world.children[0]
  # or
  #  AnalogClockMorph.instances
  # to check whether AnalogClockMorph was removed from the superclass'
  # (i.e. Morph) list:
  #  AnalogClockMorph.__super__.instances.map((elem)=>elem.constructor.name).filter((name)=>name === "AnalogClockMorph");
  # Note that only Morphs have that kind
  # of tracking and hence the existence check of
  # the registerThisInstance function
  _addInstancesTracker: (aString) ->
    # the regex to get the actual spacing under the constructor
    # is:
    # [ \t]*constructor:[ \t]*->.*$\n([ \t]*)
    # but let's keep it simple: there are going to be four spaces under for the
    # body of the constructor
    aString += "\n    return\n"
    aString.replace(/^([ \t]*)return/gm, "$1this.registerThisInstance?();\n$1return")
    
  _equivalentforSuper: (fieldName, aString) ->
    if window.srcLoadCompileDebugWrites then console.log "removing super from: " + aString
    # coffeescript won't compile "super" unless it's an instance
    # method (i.e. if it comes inside a class), so we need to
    # translate that manually into valid CS that doesn't use super.
    aString = aString.replace(/super\(\)/g, @name + ".__super__." + fieldName + ".call(this)")
    aString = aString.replace(/super /g, @name + ".__super__." + fieldName + ".call this, ")
    aString = aString.replace(/super\(/g, @name + ".__super__." + fieldName + ".call(this, ")
    aString = aString.replace(/super$/gm, @name + ".__super__." + fieldName + ".apply(this, arguments)")

  # Coffeescript adds some helper functions at the top of the compiled code:
  #
  #  slice = [].slice
  #  indexOf = [].indexOf
  #  hasProp = {}.hasOwnProperty
  #
  # here we remove them them all, because they mangle the code,
  # also we just have them all in the global scope by now so
  # they are not needed multiple times

  _removeHelperFunctions: (aString) ->
    aString = aString.replace /^var(.|\n)*?\(function/, "(function"

    if (aString.indexOf "[].indexOf") != -1 or
     (aString.indexOf "{}.hasProp") != -1 or
     (aString.indexOf "[].slice") != -1
      alert "code contains a helper var, it shouldn't: " +  aString
      debugger

    return aString

  # not used as of now because we prefer to load the comments
  # as part of the sources. Note that the presence of multiline
  # comments (and strings, for that matter) could mangle the
  # parsing.
  # Maybe a more correct way of doing this is to remove
  # only multiline comments and strings into a "clean version",
  # and maintaining line-to-line correspondence between this
  # "clean" version and the original version.
  # Then do the regexing on the "clean"
  # version, but getting the source from the "original"
  # version (which should be relatively easy if we know from which
  # line to which line each field is defined in)
  removeComments: (source) ->
    splitSource = source.split "\n"
    sourceWithoutComments = ""
    multilineComment = false
    for eachLine in splitSource
      #console.log "eachLine: " + eachLine
      if /^[ \t]*###/m.test(eachLine)
        multilineComment = !multilineComment

      if (! /^[ \t]*#/m.test(eachLine)) and (!multilineComment)
        sourceWithoutComments += eachLine + "\n"
    return sourceWithoutComments

  # You can create a Class in 3 main "modes" of use:
  #  1. you want to load up the CS source, turn it to JS
  #     and eval the JS so to create the class:
  #        generatePreCompiledJS == true
  #        createClass == true
  #  2. you want to load up the CS source, turn it to JS
  #     and just store the JS somewhere to generate the
  #     pre-compiled JS sources:
  #        generatePreCompiledJS == true
  #        createClass == false
  #  3. you want to just load up the CS source so it
  #     appears all neat in the inspectors:
  #        generatePreCompiledJS == false
  #        createClass == false
  constructor: (source, generatePreCompiledJS, createClass) ->

    if !window.classDefinitionAsJS?
      window.classDefinitionAsJS = []

    @nonStaticPropertiesSources = {}
    @staticPropertiesSources = {}
    @subClasses = []

    # find the class name
    classRegex = /^class[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
    if (m = classRegex.exec(source))?
        m.forEach((match, groupIndex) ->
            if window.srcLoadCompileDebugWrites then console.log("Found match, group #{groupIndex}: #{match}")
        )
        @name = m[1]
        if window.srcLoadCompileDebugWrites then console.log "name: " + @name

    # find if it extends some other class
    extendsRegex = /^class[ \t]*[a-zA-Z_$][0-9a-zA-Z_$]*[ \t]*extends[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/m
    if (m = extendsRegex.exec(source))?
        m.forEach((match, groupIndex) ->
            if window.srcLoadCompileDebugWrites then console.log("Found match, group #{groupIndex}: #{match}")
        )
        @superClassName = m[1]
        @superClass = window[@superClassName].class

        if window.srcLoadCompileDebugWrites then console.log "superClassName: " + @superClassName

    # find which mixins need to be mixed-in
    @augmentedWith = []
    augmentRegex = /^  @augmentWith[ \t]*([a-zA-Z_$][0-9a-zA-Z_$]*)/gm
    while (m = augmentRegex.exec(source))?
        if (m.index == augmentRegex.lastIndex)
            augmentRegex.lastIndex++
        m.forEach((match, groupIndex) ->
            if window.srcLoadCompileDebugWrites then console.log("Found match, group #{groupIndex}: #{match}")
        )
        @augmentedWith.push m[1]
        if window.srcLoadCompileDebugWrites then console.log "augmentedWith: " + @augmentedWith


    # remove the augmentations because we don't want
    # them to mangle up the parsing
    source = source.replace(/^  @augmentWith[ \t]*([a-zA-Z_$][0-9a-zA-Z_$, @]*)/gm,"")

    if window.srcLoadCompileDebugWrites then console.log "source ---------\n" + source

    source += "\n  $$$STOPTOKEN_LASTFIELD :"

    # Now find all the fields definitions
    # note that the constructor, methods, properties and static properties
    # are ALL fields definitions, so we are basically going to cycle through
    # everything

    # to match a valid JS variable name (we just ignore the keywords):
    #    [a-zA-Z_$][0-9a-zA-Z_$]*
    regex = /^  (@?[a-zA-Z_$][0-9a-zA-Z_$]*) *: *([^]*?)(?=^  (@?[a-zA-Z_$][0-9a-zA-Z_$]*) *:)/gm
    while (m = regex.exec(source))?
        if (m.index == regex.lastIndex)
            regex.lastIndex++
        m.forEach((match, groupIndex) ->
            if window.srcLoadCompileDebugWrites then console.log("Found match, group #{groupIndex}: #{match}")
        )

        if m[1].valueOf() == "$$$STOPTOKEN_LASTFIELD "
          break
        else
          if window.srcLoadCompileDebugWrites then console.log "not the stop field: " + m[1].valueOf()

        if m[1].substring(0, 1) == "@"
          @staticPropertiesSources[m[1].substring(1, m[1].length)] = m[2]
        else
          @nonStaticPropertiesSources[m[1]] = m[2]


    if generatePreCompiledJS or createClass
      # --------------------
      # OK we collected all the fields definitions, now go through them
      # and put them into action
      # --------------------

      # collect all the definitions in JS form here
      JS_string_definitions = "// class " + @name + "\n\n"

      # the class itself is a constructor function, the constructor.
      # we have to find its source (if it exists), and
      # we have to slightly modify it and then we have to
      # actually create this function, hence creating the class.
      if window.srcLoadCompileDebugWrites then console.log "adding the constructor"
      if @nonStaticPropertiesSources.hasOwnProperty('constructor')

        if window.srcLoadCompileDebugWrites then console.log "CS sources of constructor: " + @nonStaticPropertiesSources["constructor"]
        # if there is a source for the constructor
        constructorDeclaration = @_equivalentforSuper "constructor", @nonStaticPropertiesSources["constructor"]
        constructorDeclaration = @_addInstancesTracker constructorDeclaration
        if window.srcLoadCompileDebugWrites then console.log "constructor declaration CS:\n" + constructorDeclaration

        compiled = compileFGCode constructorDeclaration, true

        constructorDeclaration = @_removeHelperFunctions compiled
        constructorDeclaration = "window." + @name + " = " + constructorDeclaration
      else
        # there is no constructor source, so we
        # just have to synthesize one that does:
        #  constructor ->
        #    super
        #    register instance
        constructorDeclaration = """
          window.#{@name} = ->
            # first line here is equivalent to "super" the one
            # passing all the arguments
            window.#{@name}.__super__.constructor.apply this, arguments
            # register instance (only Morphs have this method)
            @registerThisInstance?()
            return
        """
        if window.srcLoadCompileDebugWrites then console.log "constructor declaration CS:\n" + constructorDeclaration
        constructorDeclaration = compileFGCode constructorDeclaration, true

      if window.srcLoadCompileDebugWrites then console.log "constructor declaration JS: " + constructorDeclaration
      #if @name == "StringMorph2" then debugger
      JS_string_definitions += constructorDeclaration + "\n"

      # if you declare a constructor (i.e. a Function) like this then you don't
      # get the "name" property set as it normally is when
      # defining functions in ways that specify the name, so
      # we add the name manually here.
      # the name property is tricky, see:
      # see http://stackoverflow.com/questions/5871040/how-to-dynamically-set-a-function-object-name-in-javascript-as-it-is-displayed-i
      # just doing this is not sufficient: window[@name].name = @name

      # analogous to
      # Object.defineProperty(window[@name], 'name', { value: @name })
      JS_string_definitions += "Object.defineProperty(window.#{@name}, 'name', { value: '#{@name}' });" + "\n"

      # analogous to
      # window[@name].instances = []
      JS_string_definitions += "window.#{@name}.instances = [];" + "\n"

      # if the class extends another one
      if @superClassName?
        if window.srcLoadCompileDebugWrites then console.log "extend: " + @name + " extends " + @superClassName
        # analogous to
        #window[@name].__super__ = window[@superClassName].prototype
        #window[@name] = extend window[@name], window[@superClassName]
        JS_string_definitions += "window.#{@name}.__super__ = window.#{@superClassName}.prototype;" + "\n"
        JS_string_definitions += "window.#{@name} = extend(window.#{@name}, window.#{@superClassName});" + "\n"
      else
        if window.srcLoadCompileDebugWrites then console.log "no extension (extends Object) for " + @name
        # analogous to
        #window[@name].__super__ = Object.prototype
        JS_string_definitions += "window.#{@name}.__super__ = Object.prototype;" + "\n\n"


      # if the class is augmented with one or more Mixins
      for eachAugmentation in @augmentedWith
        if window.srcLoadCompileDebugWrites then console.log "augmentedWith: " + eachAugmentation
        # analogous to
        #window[@name].augmentWith window[eachAugmentation], @name
        JS_string_definitions += "window.#{@name}.augmentWith(window.#{eachAugmentation}, '#{@name}');" + "\n"

      # non-static fields, which are put in the prototype
      for own fieldName, fieldValue of @nonStaticPropertiesSources
        if fieldName != "constructor" and fieldName != "augmentWith" and fieldName != "addInstanceProperties"
          if window.srcLoadCompileDebugWrites then console.log "building field " + fieldName + " ===== "

          #if fieldName == "invalidateFullBoundsCache"
          #  debugger

          fieldDeclaration = @_equivalentforSuper fieldName, fieldValue

          compiled = compileFGCode fieldDeclaration, true

          fieldDeclaration = @_removeHelperFunctions compiled
          fieldDeclaration = "window." + @name + ".prototype." + fieldName + " = " + fieldDeclaration

          if window.srcLoadCompileDebugWrites then console.log "field declaration: " + fieldDeclaration
          #if @name == "StringMorph2" then debugger
          JS_string_definitions += fieldDeclaration + "\n"

      # now the static fields, which are put in the constructor
      # rather than in the prototype
      for own fieldName, fieldValue of @staticPropertiesSources
        if fieldName != "constructor" and fieldName != "augmentWith" and fieldName != "addInstanceProperties"
          if window.srcLoadCompileDebugWrites then console.log "building STATIC field " + fieldName + " ===== "

          fieldDeclaration = @_equivalentforSuper fieldName, fieldValue

          compiled = compileFGCode fieldDeclaration, true

          fieldDeclaration = @_removeHelperFunctions compiled
          fieldDeclaration = "window." + @name + "." + fieldName + " = " + fieldDeclaration

          if window.srcLoadCompileDebugWrites then console.log fieldDeclaration
          JS_string_definitions += fieldDeclaration + "\n"


      JSSourcesContainer.content += JS_string_definitions + "\n"

      if createClass
        try
          if window.srcLoadCompileDebugWrites then console.log "actually evalling " + @name + " to crete Class"
          eval.call window, JS_string_definitions
        catch err
          console.log " error " + err + " evaling : " + JS_string_definitions
          alert " error " + err + " evaling : " + JS_string_definitions


      window.classDefinitionAsJS.push JS_string_definitions

    # OK now that we have created the Class
    # (or if already created anyways, in pre-compiled mode)
    # then add the .class field
    window[@name].class = @
    if @superclass? 
      @superclass.subClasses.push @


    #if @name == "LCLCodePreprocessor" then debugger

  notifyInstancesOfSourceChange: (propertiesArray)->
    for eachInstance in window[@name].instances
      eachInstance.sourceChanged()
  
    for eachProperty in propertiesArray
      for eachSubClass in @subClasses
        # if a subclass redefined a property, then
        # the change doesn't apply, so there is no
        # notification to propagate
        if !eachSubClass.nonStaticPropertiesSources[eachProperty]?
          eachSubClass.notifyInstancesOfSourceChange([eachProperty])

