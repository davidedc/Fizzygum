# CodeInjectingSimpleRectangularButtonMorph ////////////////////////////////////////////////////////

# like a SimpleRectangularButtonMorph but it contains code that can be
# injected into another morph

class CodeInjectingSimpleRectangularButtonMorph extends SimpleRectangularButtonMorph

  codeToBeInjected: ""
  morphWhereToInject: nil

  constructor: (@morphWhereToInject, face) ->
    super true, @, 'injectCodeIntoTarget', face

  editInjectableSource: ->
    @textPrompt "Code", @, "modifyCodeToBeInjected", @codeToBeInjected

  injectCodeIntoTarget: ->
    @morphWhereToInject.injectProperties @codeToBeInjected

  modifyCodeToBeInjected: (unused,textMorph) ->
    @codeToBeInjected = textMorph.text