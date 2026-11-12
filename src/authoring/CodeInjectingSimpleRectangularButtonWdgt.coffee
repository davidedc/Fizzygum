# A PALETTE'S TOOL: a SimpleRectangularButtonWdgt carrying the editable source its command injects
# into another widget. The INJECTION target is resolved by the palette that owns me (Frame-model
# plan §5.D: the paint toolbar resolves the painting overlay of the frame it is docked in, or of
# the focused widget -- so one toolbar serves any image, replacing the construction-bound target
# this button used to carry), and WHEN it is injected is the palette's business too: my press only
# tells the palette to choose me, and the palette arms whatever the choice leaves selected -- one
# write, from the one fact.
#
# I LOOK LIKE EVERY OTHER TOOL: I paint nothing of my own -- my face is my picture, in the
# toolbarGlyph ink (my palette inks it), and my hover / press state shows on the tool cell I stand
# in (lightsAToolCell, notePointerStateChanged), which also shows whether I am the ACTIVE tool, the
# one in the person's hand (isActiveTool).

class CodeInjectingSimpleRectangularButtonWdgt extends SimpleRectangularButtonWdgt

  # Why don't we store just a Function, why are we dealing with strings here?
  # 1) because the user inputs a string
  # 2) because we NEED to keep the Coffeescript source code around, if
  #    we just hold the Function then we lose the CS source

  sourceCodeToBeInjected: ""

  # WHICH COMMAND I AM, as the person's hand names it ('pencil' | 'brush' | …): the key my palette
  # hands to world.user.armDrawingTool, and the key it looks me up by when the hand changes. A
  # KEY rather than my identity, because the fact outlives every palette that shows it (User).
  drawingToolKey: undefined

  # I act on my own press rather than standing in a cell waiting to be dragged out, so the tool
  # grid puts no glass LID over me and a tap on my cell reaches me (ToolPanelWdgt._addNoSettle,
  # and the dispatch law on CommandSpec).
  actionableAsThumbnail: true

  # WHAT I AM AS A TOOL, in a word: my face's (the icon's toolName -- "pencil", "brush"), which I show
  # as my tooltip too, and by which a toolbar's overflow row names me (OverflowChevronButtonWdgt).
  toolName: undefined

  # `palette` lands in the inherited @target, which is BOTH the receiver of my press (the four-slot
  # dispatch hands it ME in slot 1, so it knows which tool was pressed) and the widget I tell about
  # newly edited source. ONE back-reference: they are one object, and two fields holding it could
  # disagree. `face` is the icon I show; `drawingToolKey` names the command I am.
  constructor: (palette, face, @drawingToolKey) ->
    super target: palette, action: "selectTool", face: face
    # no rectangle and no border: the undefined appearance paints nothing at all, and my whole box
    # still catches the pointer (Widget.catchesPointerAt)
    @appearance = undefined
    @strokeColor = undefined
    @toolName = face.toolName
    @toolTipMessage = face.toolName

  # MY HOVER AND PRESS show on the tool cell I stand in, never on me (GlassBoxBottomWdgt.fillForToolState
  # asks this of the widget whose state a cell shows).
  lightsAToolCell: ->
    true

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): I paint
  # nothing of my own, so I tell the cell I stand in, which repaints over me. A parent that is no cell
  # answers nothing.
  notePointerStateChanged: ->
    @parent?.noteItemStateChanged?()

  # MY FACE IS A PICTURE (Widget.isPointerTargetAt, AM-I-A-PICTURE): nothing in it is a pointer
  # target, so a press on it is a press on me, and the press, the release and the click all reach me
  # together -- my cell shows pressed while the press lasts, and once it ends, hovered or at rest by
  # where the pointer is (the hand's answers about me). My edit mark is no picture: it takes its own
  # presses.
  _showsChildAsAPicture: (child) ->
    child is @faceWidget

  # Am I the ACTIVE tool, the one in the person's hand? My palette answers (it keeps no record of
  # its own: it reads the hand), and my cell asks at every derivation of its look.
  isActiveTool: ->
    @target?.holdsInHand?(@) ? false

  # A tool press is about the palette that owns me and about nothing above it, so the click ENDS
  # here rather than climbing the strip -- the shape every other toolbar tool has (a creator button
  # and an editor-property button both end their clicks the same way).
  activated: ->
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()

  editInjectableSource: ->
    @textPrompt "Code", @, "modifyCodeToBeInjected", defaultContents: @sourceCodeToBeInjected

  # Push MY source onto the surface the palette resolves now -- what an EDIT to my source needs, so
  # that a tool already chosen picks the new code up without being re-pressed. Choosing a tool goes
  # the other way round: the palette reads the source off the chosen tool
  # (PaintToolbarWdgt._sourceOfSelectedTool). undefined target = nothing paintable in reach.
  injectCodeIntoTarget: ->
    @target.resolveInjectionTarget?()?.injectProperties @sourceCodeToBeInjected

  # The textPrompt callback: the prompt delivers ONE argument, the composed source text
  # (CodePromptWdgt.deliverValue — the same value delivery every prompt makes).
  # The new source is CHECKED before it is stored -- first compiled as the person typed it, which
  # places an error in the text they see, then read as a blurb exactly as it will be injected
  # (Widget.compilePropertyAssignments): code outside its `name = value` assignments is refused by
  # its line, and each assignment is compiled. Source that fails either throws here, stores nothing,
  # and the prompt reports it (CodePromptWdgt.deliverValue). Without this, an unarmed tool would keep
  # it silently: code that does not compile would throw at every later arm, and code outside an
  # assignment would never run.
  modifyCodeToBeInjected: (newSource) ->
    compileFGCode newSource, true
    Widget.compilePropertyAssignments newSource
    @sourceCodeToBeInjected = newSource
    @target.newCodeToInjectFromButton? @
