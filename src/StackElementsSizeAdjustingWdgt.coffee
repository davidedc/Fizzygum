class StackElementsSizeAdjustingWdgt extends LayoutChromeWdgt


  category: 'Widgetic-Layouts'

  # what a person calls the bar dragged to re-apportion a split
  colloquialName: -> "splitter"


  # I am a grab strip between stacked elements, layoutAdjusterThickness across the split, one flat
  # plate with only my grip dots on it (SplitPieceAppearance): every pixel of that strip has to drag,
  # between the dots as on them, or the divider is unusable.
  catchesPointerAt: (aPoint) ->
    @boundsContainPoint aPoint

  # My division box is layoutAdjusterThickness on both sides: the stack stretches the side along
  # the split (its cross axis), so which side is my thickness follows from the axis I am added on.
  constructor: ->
    super()
    thickness = WorldWdgt.theme.layoutAdjusterThickness
    @setMinAndMaxBoundsAndSpreadability (new Point thickness, thickness), (new Point thickness, thickness), DivisionStackLayoutSpec.SPREADABILITY_HANDLES
    @minimumExtent = new Point 0,0

  # my look: a split's piece, one flat plate (LayoutChromeWdgt.createAppearance)
  createAppearance: -> new SplitPieceAppearance @

  # I LEFT THE STACK I DIVIDE -- picked out, attached elsewhere or destroyed -- told by it (an
  # inspector row: InspectorRowWdgt._reactToChildRemoved): the button joined to me stays in its header
  # and is no piece with me any more, so we part (LayoutChromeWdgt.joinedPiece's rule) and I stand as a
  # divider alone; the row's next divider before that button's inspector is joined to it by that
  # inspector's reconcile.
  noteLeftMyStack: ->
    @notePartedFrom @joinedPiece

  # the part joined to me (LayoutChromeWdgt._myJoinedPiece): the button I hold, while it says I am the
  # part joined to it -- a button that does not lead its inspector's header, or that leads the header
  # of an inspector I do not stand before, joins nothing
  _myJoinedPiece: ->
    @joinedPiece  if @joinedPiece?._myJoinedPiece() is @

  detachesWhenDragged: ->
    return false

  grabsToParentWhenDragged: ->
    return false

  # I am CHROME: a drag that starts on me re-apportions the split I sit in, which is the only thing I
  # am for, and nothing competes for it. The hand asks this of a press's ancestry
  # (ActivePointerWdgt._touchPressArmsAtOnce) to know whether a FINGER must press and hold before its
  # drag means what a mouse drag means — on a divider it never does (ruling I2).
  ownsDragsStartingOnMe: -> true

  # A drag on me: re-apportion the split so my left edge lands EXACTLY where the pointer says. The
  # pointer is mapped into my plane on the line that reads it, my grab point taken off it, and the
  # split this asks for is my query's (_maxDimsPuttingMyLeadingEdgeAt, below); I make its two writes
  # myself, the declared deferrer of my own stream. (Between two columns of an inspector browser's set
  # nothing is apportioned: the column divider there, InspectorColumnDividerWdgt, a kind of me, sizes
  # the column on its left by a drag of its own, and the split button joined to it asks that divider's
  # solve, never mine.)
  #
  # WHY ABSOLUTE, NOT INCREMENTAL. The old code integrated deltaDragFromPreviousCall, so every move
  # rejected or halved at a limit discarded that mouse travel FOREVER: drag past the bound and back and
  # the divider settled 91px away from the pointer, permanently. Taking the target from the absolute
  # pointer position (the idiom HandleWdgt:307-315 and SliderButtonWdgt:75-84 already use) re-syncs
  # perfectly instead. It also makes the split's landing place robust to the sub-pixel rounding in the
  # placement loop, which used to knock this drag onto a wholly different trajectory
  # (docs/archive/fractional-widget-bounds-investigation-plan.md).
  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->

    # the user is in the process of dragging but didn't actually move the mouse yet. Kept for the "a
    # plain click does nothing" contract -- and it costs nothing now: the solve is ABSOLUTE, so a
    # skipped move's travel is recovered in full by the very next one.
    if !deltaDragFromPreviousCall?
      return

    # MY division axis, as my query reads it: "left" reads as "before me along the axis".
    horizontal = (@layoutSpec?.axis ? 'x') == 'x'
    mainOf = (point) -> if horizontal then point.x else point.y

    # Where the pointer says my LEADING EDGE should be, in MY plane. nonFloatDragPositionWithinWdgtAtStart
    # is the grab grip, captured in my plane at drag start (ActivePointerWdgt.determineGrabs). An ABSOLUTE
    # target maps as a point (screenPointToMyPlane), where a screen DELTA would have to be mapped as the
    # difference of two plane-mapped points or the translation applies twice; off any mapped plane
    # screenPointToMyPlane returns the point itself, so the dormant path needs no branch of its own.
    targetLeft = mainOf(@screenPointToMyPlane pos) - mainOf(nonFloatDragPositionWithinWdgtAtStart)

    split = @_maxDimsPuttingMyLeadingEdgeAt targetLeft
    return unless split?

    # drag-move STREAM: the _-private deferred-settle entrypoint (restricted to stream handlers like this one by
    # check-layering [O]), which DECLARES intentional per-move deferred settling onto the one end-of-cycle flush
    # instead of reaching into the private _setMaxDimNoSettle core. Measured warranted here (~13 moves/frame
    # -> ~26 muts/frame; see docs/tooling/coalescing-measurement.md); toggle world.deferredSettlingEnabled to
    # self-settle-per-move and A/B it. (the plain setMaxDim self-settles, for discrete callers.)
    # (end-of-cycle-flush-drawdown -- CONVERT)
    split.before._setMaxDimDeferredSettle split.beforeMax
    split.after._setMaxDimDeferredSettle split.afterMax

  # THE SPLIT that puts my LEADING EDGE at `targetLeft` (in MY plane, along my division axis): the two
  # division cells flanking me and the max dims the split asks of them, as {before, beforeMax, after,
  # afterMax} -- or undefined when the split cannot move: no cell on one side of me, a holder outside
  # the third regime, or nothing to move once the move is clamped. A QUERY: it reads the cells' box
  # FIELDS and changes nothing; my drag handler above, which asks it, makes the two max-dim writes
  # itself. Solved in closed form, not approached by an empirical gain.
  #
  # WHY a closed form exists. A divider can only bite in the THIRD regime of the division arrange
  # (StackLayoutEngine.arrange, "max-margin fill": the min and the desired both fit) -- regimes 1
  # and 2 hand out width from min/desired alone, so max widths are INERT there. In that regime each
  # stack cell gets
  #     w_C = des_C + extraSpace * (max_C - des_C) / maxMargin
  # with, over the holder's stack children, D = Σ des (getRecursiveDesiredDim), sumMax = Σ max
  # (getRecursiveMaxDim), extraSpace = W - D and maxMargin = sumMax - D. Children are then placed
  # edge-to-edge from the holder's left (no inset), so MY left edge sits at
  #     x = @parent.left() + A + (extraSpace/maxMargin) * B
  # where A = Σ des before me and B = Σ (max - des) before me. The move below adds +delta to the left
  # cell's max and -delta to the right cell's, which CONSERVES sumMax (hence maxMargin) and D (hence
  # extraSpace) -- so B is the only term that moves, by exactly +delta. Inverting for a wanted left
  # edge T is therefore exact, for any stack shape:
  #     delta = (T - @parent.left() - A) * maxMargin / extraSpace - B
  # The per-move gain is just maxMargin/extraSpace.
  #
  # WHAT THIS REPLACED (~2015): a hand-fitted empirical gain constant that drifted mid-drag and blew up
  # around large max widths (measured max 44px / mean 7.4px error on a 150px drag; the closed form above is 0.00px).
  #
  # ⚠ WHY NOT THE OBVIOUS "read @left(), move it to the pointer". I defer settling, so ~13 pointer moves
  # are drained per frame against ONE end-of-cycle layout pass (docs/tooling/coalescing-measurement.md) -- my
  # @left() is STALE for every move but the last of a frame, so a @left()-based solve re-applies the
  # same correction N times and overshoots (measured 238px error at 5 moves/frame). The A/B form above
  # reads only maxWidth/desired FIELDS, which update synchronously, and never the laid-out pixels -- so
  # it is exact at any cadence (0.00px at 1, 2, 5, 13 and 40 moves per layout). That trap is very likely
  # why this was incremental in the first place: deltas are immune to stale geometry too, they just drift.
  _maxDimsPuttingMyLeadingEdgeAt: (targetLeft) ->

    # MY division axis: in an 'x' row I split widths dragging horizontally; in a 'y'
    # division stack I split heights dragging vertically. Same closed form, transposed —
    # "left/right" below reads as "before/after me along the axis".
    horizontal = (@layoutSpec?.axis ? 'x') == 'x'
    mainOf = (point) -> if horizontal then point.x else point.y

    leftWidget = @lastSiblingBeforeMeSuchThat (m) ->
      m.layoutSpec?.isDivisionElement?()

    rightWidget = @firstSiblingAfterMeSuchThat (m) ->
      m.layoutSpec?.isDivisionElement?()

    return unless leftWidget? and rightWidget?

    # ONE walk of the stack children: D/sumMax over the WHOLE stack, A/B up to me. (These are
    # the main components of @parent.getRecursiveDesiredDim() and .getRecursiveMaxDim(), inlined so the
    # four sums cost one walk rather than four. D needs no .min(sumMax) clamp: getMaxDim is literally
    # max(box max, getDesiredDim), so max_C >= des_C for every child and sumMax >= D always.)
    D = 0
    sumMax = 0
    A = 0
    B = 0
    beforeMe = true
    for C in @parent.children
      continue unless C.layoutSpec?.isDivisionElement?()
      des = mainOf C.getDesiredDim()
      max = mainOf C.getMaxDim()
      D += des
      sumMax += max
      if C == @
        beforeMe = false
      else if beforeMe
        A += des
        B += max - des

    parentMainExtent = if horizontal then @parent.width() else @parent.height()
    parentMainLo = if horizontal then @parent.left() else @parent.top()
    extraSpace = parentMainExtent - D
    maxMargin = sumMax - D
    # Outside the third regime there is no spare to apportion and the maxes are inert, so the
    # drag genuinely cannot move anything -- bail rather than mutate to no visible effect.
    return unless extraSpace > 0 and maxMargin > 0

    delta = (targetLeft - parentMainLo - A) * maxMargin / extraSpace - B

    # FEASIBLE INTERVAL: neither cell may be pushed below its content (desired) width, where getMaxDim
    # clamps UP to getDesiredDim so the +delta/-delta stop cancelling and the conservation this solve
    # rests on breaks. CLAMP into the interval rather than REJECTING the whole move (what the old
    # `prev == newone` float-equality predicate did): clamping lands the divider exactly ON the bound and
    # leaves it re-synced the moment the pointer comes back, where rejecting dropped the move's entire
    # travel. lo <= 0 <= hi always (getMaxDim >= getDesiredDim), so delta = 0 is always feasible -- and,
    # unlike the `until deltaX = deltaX/2` halving loop this replaces, it cannot spin: that loop never
    # exited when a flanking cell was COLLAPSED (Widget.getMaxDim then returns 0,0),
    # because halving a negative underflows to -0 and `-0 > 0` is false forever. Dragging a divider
    # toward a collapsed neighbour used to hang the world.
    lmdd = leftWidget.getMaxDim()
    rmdd = rightWidget.getMaxDim()
    lo = mainOf(leftWidget.getDesiredDim()) - mainOf(lmdd)
    hi = mainOf(rmdd) - mainOf(rightWidget.getDesiredDim())
    delta = Math.min(hi, Math.max(lo, delta))
    # at a bound (or on a pointer move too small to shift the split) there is nothing to do -- and this
    # costs ZERO mutations, where the old predicate still paid two on an accepted-but-pointless move.
    return if delta == 0

    # the two max dims, the left cell's raised by delta and the right cell's lowered by it, along my axis
    if horizontal
      {before: leftWidget, beforeMax: (new Point lmdd.x + delta, lmdd.y), after: rightWidget, afterMax: (new Point rmdd.x - delta, rmdd.y)}
    else
      {before: leftWidget, beforeMax: (new Point lmdd.x, lmdd.y + delta), after: rightWidget, afterMax: (new Point rmdd.x, rmdd.y - delta)}

  # my hover shows the resize cursor of my axis (LayoutChromeWdgt.hoverEntered): across a row's split,
  # down a column's
  _resizeCursor: ->
    if (@layoutSpec?.axis ? 'x') == 'x' then "col-resize" else "row-resize"


  # MY PLATE'S CORNERS (SplitPieceAppearance): square, ends included -- a divider is a strip from
  # cell to cell, and the tab joined to me meets my edge with no step
  _plateCornerRadii: -> 0

  # MY MARK (SplitPieceAppearance paints it, in layoutAdjusterGripMark): the house's grip dots, as a
  # band's strip shows them, in my box kept layoutChromeGripDotsInset in from every edge -- at most
  # layoutAdjusterGripDotsAlong along my long side, down a strip standing between a row's cells,
  # across one lying between a column's, and as many as fit across (two at layoutAdjusterThickness,
  # fewer on a strip squeezed thinner, none on one too thin for a dot), answered as [the field, the
  # most dots along] (Appearance._paintGripDots's field and opts). Paint, not a control: every pixel of
  # my box drags, between the dots as on them.
  _gripDotFieldOnMyPlate: ->
    theme = WorldWdgt.theme
    field = (new Rectangle 0, 0, @width(), @height()).insetBy theme.layoutChromeGripDotsInset
    along = theme.layoutAdjusterGripDotsAlong
    if @height() >= @width() then [field, {mostRows: along}] else [field, {mostColumns: along}]

