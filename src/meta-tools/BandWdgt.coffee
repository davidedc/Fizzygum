# A BAND: one row of controls across the widget that holds me -- an inspector's header, a member
# list's row of toggles, its row of buttons. I am `height` tall, my rule included, and as wide as I
# am given; my controls keep their own sizes, centred down me -- unless a control says where it stands
# down a band (crossAlignInABand: a split button turned a quarter hangs from my top, under the divider
# above its inspector) --, in the order written, with the gaps written between them, and my spring --
# or a text that gives, in its place -- takes the slack.
#   I have no layout of my own: every piece of mine is an element of a horizontal DIVISION row
# (StackLayoutEngine). So my least width is my pieces' together, which the stack derives
# (Widget.getRecursiveMinDim), and the least width of whatever holds me follows from it.
#   An item is a widget (a CONTROL, fixed at its own preferredExtent, centred down me or where it
# says), a number (a GAP that many px wide), BandWdgt.SPRING (BandSpaceWdgt makes a gap and a spring),
# or `{gives: aText}`, a line of text that GIVES WAY. A gap is as tall as I am, and that is what makes
# me that tall: a division row is as tall as its tallest element, whatever its own box says.
#   Every fixed piece is FIXED: a control's least, desired and most size are all its preferredExtent,
# with no spreadability at all (SPREADABILITY_NONE still leaves a tenth of the desired size to take
# slack, and a "fixed" control would wobble a px as my width changes). So is my own HEIGHT: my box
# pins it, so a stack holding me hands me none of its slack while another of its cells can take it;
# a stack none of whose cells can shares it by desired sizes, mine among them (StackLayoutEngine, its
# third regime), which is why an inspector keeps its view's place.
#   ONE piece of mine takes my SLACK: my spring, or a text that gives. A text that gives IS my spring:
# its least and desired width are both only what its box can shrink to (its minimumExtent: a box is
# never committed narrower, so a smaller least would let the text run past the cell it was given),
# its height its one line's (StringWdgt.linePitch at the size it is set in), and its spreadability a
# spacer's, so it takes all the width my fixed pieces leave, its box running up to the piece after
# it. Its text stays in a StringWdgt's own fitting: cropped with "…" where its box is narrower than
# the text, standing at its box's start where the box is wider. Its length claims nothing: a desired
# width is what a division row's regime is decided by and what a split between two of its cells
# stops at, so a text that would merely like its width states none, and my least and desired widths
# are my fixed pieces' and that floor, whatever the text. The form is the plainest that says it: the
# item is the text itself, marked, so the piece my build adds is that same widget, and a holder that
# re-leads me before it still finds it among my children (_replacePiecesBeforeNoSettle).
#   A band written with neither gets a spring at its end: without one the slack would go to my
# controls. A band written with BOTH is refused at its build, loudly: two takers share the slack in
# proportion to their margins, so which one a person sees grow would follow from two spreadabilities
# rather than from what the band was written to say, and a spring written beside a text that gives
# says nothing the text does not.
#   I paint nothing but my RULE (ruleEdge): a line along my top or my bottom edge, inspectorRuleWidth
# thick, INSIDE my height. It is the line between me and the pane beside me, mine because what
# stands beside me is not mine to know: I paint it as a container paints its seams
# (SeamRulesAppearance over _seamRects), under my pieces, so a control as tall as I am stands over
# it (visual-design-system §4.1). Drops: a band and its spaces take none (Widget's own answer).
class BandWdgt extends Widget

  # the item that stands for my spring
  @SPRING: "spring"

  # the edge my rule lies along, "top" or "bottom", or undefined for none
  ruleEdge: undefined
  # my height, my rule included: what my box pins, and how tall my gaps and my spring stand
  bandHeight: undefined

  #: initialization

  # `height` and `items` are my identity; opts.rule names the edge my rule lies along
  constructor: (height, items, opts = {}) ->
    super()
    @bandHeight = height
    @ruleEdge = opts.rule
    @appearance = new SeamRulesAppearance @
    # my own box pins my height; its width is no input while I have pieces (the stack sums theirs),
    # so the most it says, 0, leaves my most width my desired one
    @setMinAndMaxBoundsAndSpreadability (new Point 0, height), (new Point 0, height), 0
    @_buildAndConnectChildren items

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns
  # settled). The items are handed to the build and kept nowhere: what I keep of them is my pieces,
  # my children, which a holder may re-lead later (_replacePiecesBeforeNoSettle), so a record of the
  # list I was built from would go stale -- hence the argument, where the canonical pair reads a field.
  _buildAndConnectChildren: (items) ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle items

  # every piece added in this ONE settle, a spring at my end when the items name no taker of my slack
  # (a row half built, a spring alone in it, would divide by its desired widths' sum); items naming
  # two takers, a spring and a text that gives, are refused (my header says why)
  _buildAndConnectChildrenNoSettle: (items) ->
    holdsAGivingText = items.some (item) -> item?.gives?
    if holdsAGivingText and BandWdgt.SPRING in items
      throw new Error "BandWdgt: a band takes its slack in ONE piece -- a text that gives IS its spring, so it is written with no BandWdgt.SPRING beside it"
    items = items.concat [BandWdgt.SPRING]  unless holdsAGivingText or BandWdgt.SPRING in items
    for item in items
      piece = @_pieceFor item
      @_addNoSettle piece, layoutSpec: piece.divisionBox()
    @_invalidateLayout()

  #: structure

  # MY LEAD AGAIN: every piece of mine before `piece` taken away (destroyed), and the pieces `items`
  # write put in their place, before it, each made as my build makes it. A holder re-leads me with it
  # (an inspector's header, which opens with a split button exactly while a splitter stands before
  # its inspector: InspectorWdgt._reconcileSplitGripNoSettle). A lead is gaps and controls: the one
  # piece that takes my slack was written in my build, and a lead adds no second one. A core that
  # opens no settle, and the only pieces it makes are gaps and the controls the holder made, none of
  # which settles as it is made, so a holder's copy and restore hooks may call it too.
  _replacePiecesBeforeNoSettle: (piece, items) ->
    at = @children.indexOf piece
    return if at < 0
    each._fullDestroyNoSettle() for each in @children[...at]
    for item, i in items
      lead = @_pieceFor item
      @_addNoSettle lead, atIndex: i, layoutSpec: lead.divisionBox()
    return

  #: layout

  # the piece an item makes: a gap or a spring for a number or SPRING; for a widget, a control fixed
  # at its own size; for a text that gives, that text as my spring, at its box's least width and its
  # line's height (the header says why); either widget centred down me, or where it says it stands down
  # a band (crossAlignInABand: "start", "center" or "end"), through the spec's NoSettle core (its public
  # setter settles)
  _pieceFor: (item) ->
    return new BandSpaceWdgt 1, @bandHeight, springs: true  if item is BandWdgt.SPRING
    return new BandSpaceWdgt item, @bandHeight  if typeof item is "number"
    if item.gives?
      piece = item.gives
      floor = new Point piece.getMinimumExtent().x, piece.linePitch piece.originallySetFontSize
      piece.setMinAndMaxBoundsAndSpreadability floor, floor, DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    else
      piece = item
      extent = piece.preferredExtent()
      piece.setMinAndMaxBoundsAndSpreadability extent, extent, 0
    piece.divisionBox()._setCrossAlignNoSettle (piece.crossAlignInABand?() ? "center")
    piece

  #: drawing

  # My one seam: my rule, inside my height, along my ruleEdge (none without one).
  _seamRects: ->
    return [] unless @ruleEdge?
    thickness = WorldWdgt.theme.inspectorRuleWidth
    if @ruleEdge is "top"
      [new Rectangle 0, 0, @width(), thickness]
    else
      [new Rectangle 0, @height() - thickness, @width(), @height()]
