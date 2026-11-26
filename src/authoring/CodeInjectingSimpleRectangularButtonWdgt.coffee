# A PALETTE'S TOOL: a SimpleRectangularButtonWdgt naming one paint tool by its KEY (drawingToolKey).
# I answer my own press: I set my key on my HOLDER -- the window whose edge slot my toolbar occupies
# while it is docked, the person while it floats (ToolbarWdgt.hostWindowOf) -- and I am the ACTIVE
# tool exactly while my holder holds my key. Both holders answer the same pair (armedDrawingTool,
# armDrawingTool), so I never ask which kind I found. I push nothing onto any drawing: a paint surface
# takes its tool up when it is used, from its own nearest holder (CanvasGlassTopWdgt).
#
# WHAT A PERSON EDITS OF ME is the person's tool my key names (_memberToEdit: DrawingTool.of, one per
# key per person), opened on its applyToolAt: my EDIT MARK opens the inspector on it, and so does my
# menu's "Edit code" row (Widget.inspectMemberToEdit). A Save there writes the person's ONE table of
# edited tools (DrawingToolBase.sourceChanged -> User.overrideDrawingTool), so every palette's cell for
# my key, docked or floating, opens the same tool, and every surface using my key takes the edit up at
# its next use.
#
# I LOOK LIKE EVERY OTHER TOOL: I paint nothing of my own -- my face is my picture, in the
# toolbarGlyph ink (my palette builds it so), and my hover / press state shows on the tool cell I
# stand in (lightsAToolCell, notePointerStateChanged), which also shows whether I am the ACTIVE tool
# (isActiveTool).

class CodeInjectingSimpleRectangularButtonWdgt extends SimpleRectangularButtonWdgt

  # WHICH COMMAND I AM, as a holder names it ('pencil' | 'brush' | …): the key I set on my holder,
  # and the key my edit mark edits. A KEY rather than my identity, because the fact outlives every
  # palette that shows it (User).
  drawingToolKey: undefined

  # I act on my own press rather than standing in a cell waiting to be dragged out, so the tool
  # grid puts no glass LID over me and a tap on my cell reaches me (ToolPanelWdgt._addNoSettle,
  # and the dispatch law on CommandSpec).
  actionableAsThumbnail: true

  # MY FACE IS A PICTURE that fills the room my box gives it, so the tool cell I stand in -- whose whole
  # square is my target -- names the side it is drawn at (GlassBoxBottomWdgt._reLayoutSelf, the mark
  # box), and I seat my face in that side (_faceBoundsIn).
  drawsFaceInToolMarkBox: true

  # THE SIDE MY FACE IS DRAWN AT inside my box: the tool cell I stand in writes it as it seats me, my
  # box staying the cell's whole target; unset, my face fills the room my padding leaves.
  glyphSize: undefined

  # WHAT I AM AS A TOOL, in a word: my face's (the icon's toolName -- "pencil", "brush"), which I show
  # as my tooltip too, and by which a toolbar's overflow row names me (OverflowChevronButtonWdgt).
  toolName: undefined

  # `face` is the icon I show; `drawingToolKey` names the command I am. No target and no action: I
  # answer my own press (activated), so the inherited trigger has nothing to dispatch.
  constructor: (face, @drawingToolKey) ->
    super face: face
    # no rectangle and no border: the undefined appearance paints nothing at all, and my whole box
    # still catches the pointer (Widget.catchesPointerAt)
    @appearance = undefined
    @strokeColor = undefined
    @toolName = face.toolName
    @toolTipMessage = face.toolName

  # WHAT A PERSON CALLS ME: the tool my key names, in the very words that tool answers
  # (DrawingToolBase.colloquialNameForKey: "pencil tool"), so my own menu's title, the row naming me in a
  # hierarchy menu or a chooser, and an inspector's window title say what my edit mark opens.
  colloquialName: ->
    DrawingToolBase.colloquialNameForKey @drawingToolKey

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

  # MY FACE'S BOX in the room my padding leaves (ButtonWdgt._reLayout's soft hook): the mark box my cell
  # names (glyphSize), centred, never larger than the room; all of the room while no cell has named one.
  _faceBoundsIn: (room) ->
    return room unless @glyphSize?
    side = Math.min @glyphSize, room.width(), room.height()
    origin = new Point room.left() + Math.round((room.width() - side) / 2), room.top() + Math.round((room.height() - side) / 2)
    origin.extent new Point side, side

  # WHO HOLDS MY TOOL: the window my toolbar works for, else the person. Read at every asking, never
  # stored, so a palette that docks or floats away is answered by its new holder at once.
  _holder: ->
    ToolbarWdgt.hostWindowOf(@) ? world.user

  # Am I the ACTIVE tool -- does my holder hold my key? My cell asks at every derivation of its look,
  # and an overflow row standing for my cell ticks by the same answer.
  isActiveTool: ->
    holder = @_holder()
    holder.armedDrawingTool? and holder.armedDrawingTool is @drawingToolKey

  # A tool press is about my holder and about nothing above me, so the click ENDS here rather than
  # climbing the strip -- the shape every other toolbar tool has (a creator button and an
  # editor-property button both end their clicks the same way). A tap on my cell and my overflow row
  # (OverflowChevronButtonWdgt.triggerToolFromMenu) both arrive here. THE SECOND TAP'S MEANING IS
  # MINE: tapping the tool my holder already holds puts it DOWN, which is a fact about the GESTURE --
  # the holder's verb only states what is held, so nothing that merely re-states a tool, a restored
  # snapshot included, can be mistaken for a second tap.
  #   No settle here: the person's write is an ANNOUNCEMENT the cycle's dataflow drain delivers to
  # every palette, and a window's write tells its docked palettes itself (FrameWdgt.armDrawingTool).
  activated: ->
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    holder = @_holder()
    holder.armDrawingTool (if @drawingToolKey is holder.armedDrawingTool then undefined else @drawingToolKey)
    return

  # WHAT A PERSON EDITS OF ME: the person's tool my key names (DrawingTool.of: one per key per person,
  # whichever palette's cell asks, docked or floating), opened on applyToolAt, the one body a tool
  # runs at every pointer move (CanvasGlassTopWdgt). Asked by my edit mark and by my menu's "Edit code"
  # row (Widget.inspectMemberToEdit). A key naming no tool answers nothing.
  _memberToEdit: ->
    tool = DrawingTool.of @drawingToolKey
    {subject: tool, member: "applyToolAt"}  if tool?
