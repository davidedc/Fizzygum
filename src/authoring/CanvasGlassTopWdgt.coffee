# THE PAINT SURFACE ("the glass"): the transparent canvas over a drawing's canvas. A paint tool shows
# its feedback on me and lays its paint on the canvas under me (@underlyingCanvasWdgt).
#
# I TAKE MY TOOL UP WHEN I AM USED. A tool is the person's DrawingTool for a key (DrawingTool.of: made
# from the person's edit of that tool, else from PaintToolbarWdgt's stock members), whose members --
# `applyToolAt` and its helpers -- I carry as INSTANCE members of mine while I carry it, each compiled
# on me from its source. The pointer reaches me through my two class entries, hoverMoved and
# pressMoved, and each asks, at that very event, which tool I should carry now: none while my drawing
# sits in view-mode content, else the one my nearest holder holds (_toolHolder: the nearest window
# whose content I stand in and that wears drawing tools, else the person). Nothing pushes a tool onto
# me and nothing has to tell me when the answer changes, so no change of hand, of window, of docking,
# of nesting, of mode or of the person's edit can leave me carrying a stale one.

class CanvasGlassTopWdgt extends CanvasWdgt

  underlyingCanvasWdgt: undefined
  defaultRejectDrags: true

  # the TOOTHPASTE tool's rolling buffer of recent pointer positions: the tool's members
  # (PaintToolbarWdgt.TOOTHPASTE_TOOL) are put on me and run with @ bound to me, so the buffer is
  # mine. Built lazily on first use and drained as the stroke is laid down. Declared undefined, never
  # [] — the lazy build keys off `if !@queue?`, and a prototype array would be shared by every
  # instance.
  queue: undefined

  # THE CODE MY TOOL MEMBERS CAME FROM: the member code (DrawingToolBase.memberCode, a JSON text of
  # member name -> source) of the tool I last took up, undefined while I carry none. My take-up
  # compares it with the code of the tool I should carry now, and takes the next tool up on a change.
  # A plain saved field: after a load or a copy it still names what my restored members came from, so
  # the first use after either compares truly.
  _takenUpToolCode: undefined
  # THE MEMBERS I PUT ON ME at that take-up, by name, in its order: the members of that code I took up
  # and made (_takeUpToolInReach), and the names my next change removes, so what I remove is exactly
  # what I put on me. A plain saved field, as the code beside it.
  _takenUpMemberNames: undefined

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

  # Bring my tool members in line with the tool I should carry NOW. COST PER POINTER MOVE, while nothing
  # changed: the tool asked of my holder (DrawingTool.of: a lookup and an identity compare) and one
  # string compare of its member code with the one I took up -- the same string, so equal by
  # reference. On a change, every member I put on me at my last take-up goes (the toothpaste's
  # pressEnded with it), read from my own saved field, before the new tool's members are compiled on me
  # from their sources, never shared as the tool's own functions: a `=>` a person types binds me, and a
  # copied or loaded drawing compiles its own from its {"$src"} either way. So two tools never mix on me.
  #   The member code is read ONCE, where it is parsed, and filtered there: a member under a name I
  # already answer is NEVER put on me (DrawingToolBase.nameTheSurfaceAnswers), whatever brought it into
  # the tool -- a file's record, code run elsewhere -- since standing over a name of mine would break me;
  # such a record is inert on every surface, while the inspector on the tool still lists the member and
  # its Remove removes it. Each other member is put on me in its own try, and the code and the names I
  # made are recorded whatever happened, so no failure is tried again at the next move; a member that
  # fails (its text throws as it is evaluated: DrawingToolBase._standInFor) is simply absent from me,
  # and after all of them the first failure is rethrown, ONCE, to the pointer event's catch, which says
  # it in the Error log.
  _takeUpToolInReach: ->
    wanted = @_toolInReach()?.memberCode()
    return if wanted is @_takenUpToolCode
    # public-call-sanctioned: removeOwnProperty and injectProperty are the edit verbs of my own
    # instance members -- settle-free, touching no geometry -- and taking a tool up IS editing them
    @removeOwnProperty name for name in @_takenUpMemberNames ? []
    @_takenUpToolCode = wanted
    @_takenUpMemberNames = made = []
    firstFailure = undefined
    for own name, source of (if wanted? then JSON.parse wanted else {}) when !DrawingToolBase.nameTheSurfaceAnswers name
      try
        @injectProperty name, source
        made.push name
      catch error
        firstFailure ?= error
    throw firstFailure if firstFailure?
    return

  # The tool I should carry now, or undefined for none: none while my drawing sits in view-mode content
  # (Widget.sitsInViewModeContent: the canvas under me holds my drawing's mode, which the container
  # coordinating it sets -- a Drawings Maker's edit toggle reaches it there -- and view mode around the
  # drawing reaches in too, up to the nearest window with an edit toggle), else the person's tool for
  # my holder's key (DrawingTool.of: the person's edit of that tool, else the stock one); a holder
  # holding no key gives none.
  _toolInReach: ->
    return undefined if @sitsInViewModeContent()
    toolKey = @_toolHolder().armedDrawingTool
    DrawingTool.of toolKey  if toolKey?

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
