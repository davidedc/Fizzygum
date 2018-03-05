# like a SimpleRectangularButtonMorph but it contains code that can be
# injected into another morph

class CodeInjectingSimpleRectangularButtonMorph extends SimpleRectangularButtonMorph

  # Why don't we store just a Function, why are we dealing with strings here?
  # 1) because the user inputs a string
  # 2) because we NEED to keep the Coffeescript source code around, if
  #    we just hold the Function then we lose the CS source

  sourceCodeToBeInjected: ""
  morphWhereToInject: nil
  morphToBeNotifiedForNewCode: nil

  constructor: (@morphToBeNotifiedForNewCode, @morphWhereToInject, face) ->
    super true, @, 'injectCodeIntoTarget', face

  editInjectableSource: ->
    @textPrompt "Code", @, "modifyCodeToBeInjected", @sourceCodeToBeInjected

  # this happens when pressed, the source code is injected
  injectCodeIntoTarget: ->
    @morphWhereToInject.injectProperties @sourceCodeToBeInjected

  modifyCodeToBeInjected: (unused,textMorph) ->
    @sourceCodeToBeInjected = textMorph.text
    @morphToBeNotifiedForNewCode.newCodeToInjectFromButton? @
