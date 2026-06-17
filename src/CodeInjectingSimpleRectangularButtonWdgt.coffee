# like a SimpleRectangularButtonWdgt but it contains code that can be
# injected into another widget

class CodeInjectingSimpleRectangularButtonWdgt extends SimpleRectangularButtonWdgt

  # Why don't we store just a Function, why are we dealing with strings here?
  # 1) because the user inputs a string
  # 2) because we NEED to keep the Coffeescript source code around, if
  #    we just hold the Function then we lose the CS source

  sourceCodeToBeInjected: ""
  wdgtWhereToInject: nil
  wdgtToBeNotifiedForNewCode: nil

  constructor: (@wdgtToBeNotifiedForNewCode, @wdgtWhereToInject, face) ->
    super true, @, 'injectCodeIntoTarget', face
    @strokeColor = Color.BLACK
    @setColor Color.create 150, 150, 150
    @toolTipMessage = face.toolTipMessage

  editInjectableSource: ->
    @textPrompt "Code", @, "modifyCodeToBeInjected", @sourceCodeToBeInjected

  # this happens when pressed, the source code is injected
  injectCodeIntoTarget: ->
    @wdgtWhereToInject.injectProperties @sourceCodeToBeInjected

  modifyCodeToBeInjected: (unused,textWidget) ->
    @sourceCodeToBeInjected = textWidget.text
    @wdgtToBeNotifiedForNewCode.newCodeToInjectFromButton? @
