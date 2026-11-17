# THE PAINT SURFACE ("the glass"): the transparent canvas over a drawing's canvas. A paint tool shows
# its feedback on me and lays its paint on the canvas under me (@underlyingCanvasWdgt).
#
# I TAKE MY TOOL UP WHEN I AM USED. A tool is a source of `name = value` assignments
# (PaintToolbarWdgt's stock sources, or the person's edit of one) that I carry as INSTANCE members:
# `applyToolAt` and its helpers. The pointer reaches me through my two class entries, hoverMoved and
# pressMoved, and each asks, at that very event, which tool I should carry now: none while my drawing
# sits in view-mode content, else the one my nearest holder holds (_toolHolder: the nearest window
# whose content I stand in and that wears drawing tools, else the person). Nothing pushes a tool onto
# me and nothing has to tell me when the answer changes, so no change of hand, of window, of docking,
# of nesting or of mode can leave me carrying a stale one.

class CanvasGlassTopWdgt extends CanvasWdgt

  underlyingCanvasWdgt: undefined
  defaultRejectDrags: true

  # the TOOTHPASTE tool's rolling buffer of recent pointer positions: the tool's handlers
  # (PaintToolbarWdgt.TOOTHPASTE_TOOL_SOURCE) are injected onto me and run with @ bound to me, so
  # the buffer is mine. Built lazily on first use and drained as the stroke is laid down. Declared
  # undefined, never [] — the lazy build keys off `if !@queue?`, and a prototype array would be
  # shared by every instance.
  queue: undefined

  # THE SOURCE MY TOOL MEMBERS CAME FROM: the tool source I last took up, undefined while I carry
  # none. My take-up compares it with the one I should carry now, and on a change removes exactly the
  # members it assigns before injecting the next. A plain saved field: after a load or a copy it still
  # names what the restored members came from, so the first use after either compares truly.
  _takenUpToolSource: undefined

  # MY TWO ENTRIES, the names no tool source may assign: a tool assigns applyToolAt, which both of them
  # run. An instance member of either name would shadow my class entry, and the drawing would then
  # never take its tool up again. Read by the save of a tool's code, which refuses such a source
  # (refuseToolCodeAssigningMyEntries).
  # hand-list-sanctioned: SystemTest_macroToolCodeSaveRefusesCodeThatDoesNotCompile saves a tool's code
  # assigning each of these names and fails unless the save is refused and my class entries still run
  @TOOL_ENTRIES: ["hoverMoved", "pressMoved"]

  # what a person calls me: the surface a drawing is painted on
  colloquialName: -> "paint surface"

  # I clear myself to FULLY TRANSPARENT, so my CanvasAppearance's per-pixel answer (which I would
  # otherwise take, as every CanvasWdgt does) is "the pointer is never on me" — and hover would stop
  # registering the moment the paint surface is clean. My whole box takes the pointer instead:
  # that is what makes me the glass over the canvas. ⚠ It belongs HERE and not in whichever
  # client builds me (ImageWdgt today) — set from outside, a second client, or one dropped line,
  # silently gets a dead paint surface.
  catchesPointerAt: (aPoint) ->
    @boundsContainPoint aPoint

  # I lay no paper: my raster starts clear, so the canvas under me shows through me (CanvasWdgt
  # lays its role's paper when it holds no colour of its own; as glass, I answer none).
  _surfaceFill: ->
    undefined

  constructor: ->
    super
    # the overlay canvas is usually attached to a Canvas
    # which unfortunately is a Panel (it shouldn't, it should
    # just clip at its bounds as a ClippingWdgt TODO ). So, usually
    # things inside a Panel can be dragged-out of it, so we have
    # to avoid that here
    @isLockingToPanels = true

  # ===== the tool, taken up at use =====

  # A drawing surface is one of the few widgets with business on BOTH pointer-move channels, and both
  # run one body, the tool's applyToolAt: a HOVER move shows where the tool would land, and a PRESSED
  # move carries the button as a fact -- the primary button lays paint down, any other previews
  # exactly as a hover does. A finger has no hover, so the press path alone must take the tool up,
  # and it does.
  hoverMoved: (pos) ->
    @_applyToolInReach pos

  pressMoved: (pos, mouseButton) ->
    @_applyToolInReach pos, mouseButton

  # don't leave any trace behind when the pointer moves out: the feedback lives on me, the paint on
  # the canvas under me
  hoverExited: ->
    context = @backBuffer.canvasContext
    context.setTransform 1, 0, 0, 1, 0, 0
    context.clearRect 0, 0, @width() * ceilPixelRatio, @height() * ceilPixelRatio
    @_changed()

  # Carry the tool I should carry now, then let it act. No tool (view mode, an empty holder) means no
  # applyToolAt, so nothing paints and nothing previews.
  _applyToolInReach: (pos, mouseButton) ->
    @_takeUpToolInReach()
    @applyToolAt? pos, mouseButton

  # Bring my injected tool members in line with the tool I should carry NOW. A string compare when
  # nothing changed; on a change, every member the previous source assigned goes (the toothpaste's
  # pressEnded with it) before the new source's are injected, so two tools never mix on me.
  _takeUpToolInReach: ->
    wanted = @_sourceOfToolInReach()
    return if wanted is @_takenUpToolSource
    # public-call-sanctioned: removeOwnProperty and injectProperties are the edit verbs of my own
    # instance members -- settle-free, touching no geometry -- and taking a tool up IS editing them
    if @_takenUpToolSource?
      @removeOwnProperty each.name for each in Widget.compilePropertyAssignments @_takenUpToolSource
    @injectProperties wanted if wanted?
    @_takenUpToolSource = wanted

  # The source of the tool I should carry now, or undefined for none: none while my drawing sits in
  # view-mode content (Widget.sitsInViewModeContent: the canvas under me holds my drawing's mode, which
  # the container coordinating it sets -- a Drawings Maker's edit toggle reaches it there), else what
  # my holder's key means now (the person's edit of that tool, else the stock one:
  # PaintToolbarWdgt.sourceForToolKey); a holder holding no key gives none.
  _sourceOfToolInReach: ->
    return undefined if @sitsInViewModeContent()
    toolKey = @_toolHolder().armedDrawingTool
    return undefined unless toolKey?
    PaintToolbarWdgt.sourceForToolKey toolKey

  # WHO HOLDS MY TOOL: climbing my ancestors, the first window whose CONTENT I stand in (its contents
  # is the child the climb came up through -- a band is no window's content) and that wears drawing
  # tools (ToolbarWdgt.wearsDrawingTools); none, and the person does. The nearer holder wins: a
  # drawing inside a window wearing a palette follows that window, never the hand.
  _toolHolder: ->
    cameThrough = @
    holder = @parent
    while holder?
      return holder if holder.isFrame?() and holder.contents is cameThrough and ToolbarWdgt.wearsDrawingTools holder
      cameThrough = holder
      holder = holder.parent
    world.user

  # Refuse a tool's code that assigns one of my entries (TOOL_ENTRIES), by throwing before anything is
  # stored -- the way Widget.compilePropertyAssignments refuses code outside its assignments: the
  # refusal reads like a compile error (`isCompileError`) placed on its line as typed (`typedLocation`,
  # a line and no column), which the saving gesture tells the person (Widget._savingTypedCode).
  # `assignments` is what compilePropertyAssignments read in `codeBlurb`, so the decision is its reading
  # (a line in a ### block assigns nothing); the line named is the first typed line that opens such an
  # assignment.
  @refuseToolCodeAssigningMyEntries: (codeBlurb, assignments) ->
    reserved = (each.name for each in assignments when each.name in CanvasGlassTopWdgt.TOOL_ENTRIES)
    return if reserved.length is 0
    name = reserved[0]
    typedLines = codeBlurb.replace(/\r\n?/g, "\n").split "\n"
    typedLine = typedLines.findIndex (eachLine) -> /^([a-zA-Z_$][0-9a-zA-Z_$]*)[ \t]*=/.exec(eachLine)?[1] is name
    refusal = new Error "line #{typedLine + 1} of the code assigns #{name}",
      cause: new Error "a tool's code assigns applyToolAt, never #{name}: the paint surface owns #{name}"
    refusal.isCompileError = true
    refusal.typedLocation = line: typedLine
    throw refusal
