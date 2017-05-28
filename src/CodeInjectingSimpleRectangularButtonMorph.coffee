# CodeInjectingSimpleRectangularButtonMorph ////////////////////////////////////////////////////////

# like a SimpleRectangularButtonMorph but it contains code that can be
# injected into another morph

class CodeInjectingSimpleRectangularButtonMorph extends SimpleRectangularButtonMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  codeToBeInjected: ""
  morphWhereToInject: null

  constructor: (@morphWhereToInject, face) ->
    super true, @, 'injectCodeIntoTarget', face

  editInjectableSource: ->
    debugger
    @textPrompt "Code", @, "modifyCodeToBeInjected", @codeToBeInjected

  injectCodeIntoTarget: ->
    debugger
    @morphWhereToInject.injectProperties @codeToBeInjected

  modifyCodeToBeInjected: (unused,textMorph) ->
    debugger
    @codeToBeInjected = textMorph.text