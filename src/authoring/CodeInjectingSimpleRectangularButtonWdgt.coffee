# like a SimpleRectangularButtonWdgt but it contains code that can be
# injected into another widget. The TARGET is resolved at PRESS time by the
# button's owner (Frame-model plan §5.D: the paint toolbar resolves the
# painting overlay of the frame it is docked in, or of the focused widget --
# so one toolbar serves any image, replacing the construction-bound target
# this button used to carry).

class CodeInjectingSimpleRectangularButtonWdgt extends SimpleRectangularButtonWdgt

  # Why don't we store just a Function, why are we dealing with strings here?
  # 1) because the user inputs a string
  # 2) because we NEED to keep the Coffeescript source code around, if
  #    we just hold the Function then we lose the CS source

  sourceCodeToBeInjected: ""
  wdgtToBeNotifiedForNewCode: nil

  constructor: (@wdgtToBeNotifiedForNewCode, face) ->
    super true, @, 'injectCodeIntoTarget', face
    @strokeColor = Color.BLACK
    @setColor Color.create 150, 150, 150
    @toolTipMessage = face.toolTipMessage

  editInjectableSource: ->
    @textPrompt "Code", @, "modifyCodeToBeInjected", @sourceCodeToBeInjected

  # this happens when pressed, the source code is injected into the target the
  # owner resolves NOW (nil = nothing paintable in reach: the press is a
  # visual-only selection change)
  injectCodeIntoTarget: ->
    @wdgtToBeNotifiedForNewCode.resolveInjectionTarget?()?.injectProperties @sourceCodeToBeInjected

  modifyCodeToBeInjected: (unused,textWidget) ->
    @sourceCodeToBeInjected = textWidget.text
    @wdgtToBeNotifiedForNewCode.newCodeToInjectFromButton? @
