# like a SimpleRectangularButtonWdgt but it carries editable code that can be injected into
# another widget. The TARGET is resolved by the button's owner (Frame-model plan §5.D: the paint
# toolbar resolves the painting overlay of the frame it is docked in, or of the focused widget --
# so one toolbar serves any image, replacing the construction-bound target this button used to
# carry), and WHEN it is injected is the owner's business too: I am a switch's face, so my press
# only flips that switch, and the owner arms whatever the flip leaves selected.

class CodeInjectingSimpleRectangularButtonWdgt extends SimpleRectangularButtonWdgt

  # Why don't we store just a Function, why are we dealing with strings here?
  # 1) because the user inputs a string
  # 2) because we NEED to keep the Coffeescript source code around, if
  #    we just hold the Function then we lose the CS source

  sourceCodeToBeInjected: ""
  wdgtToBeNotifiedForNewCode: undefined

  constructor: (@wdgtToBeNotifiedForNewCode, face) ->
    # UNWIRED, like the bare SimpleRectangularButtonWdgt the demos build: I am a FACE carrying
    # editable source, not a command. My press escalates to the switch I am a face of, and my
    # owner arms whichever tool that leaves selected -- one write, from the one fact. A press
    # action here would be a second, parallel write of the same thing.
    super face: face
    @strokeColor = Color.BLACK
    @setColor Color.create 150, 150, 150
    @toolTipMessage = face.toolTipMessage

  editInjectableSource: ->
    @textPrompt "Code", @, "modifyCodeToBeInjected", defaultContents: @sourceCodeToBeInjected

  # Push MY source onto the target the owner resolves now -- what an EDIT to my source needs, so
  # that a tool already selected picks the new code up without being re-pressed. Selecting a tool
  # goes the other way round: the owner reads the source off the selected face
  # (PaintToolbarWdgt._sourceOfSelectedTool). undefined target = nothing paintable in reach.
  injectCodeIntoTarget: ->
    @wdgtToBeNotifiedForNewCode.resolveInjectionTarget?()?.injectProperties @sourceCodeToBeInjected

  # The textPrompt callback: the prompt delivers ONE argument, the composed source text
  # (CodePromptWdgt.deliverValue — the same value delivery every prompt makes).
  modifyCodeToBeInjected: (newSource) ->
    @sourceCodeToBeInjected = newSource
    @wdgtToBeNotifiedForNewCode.newCodeToInjectFromButton? @
