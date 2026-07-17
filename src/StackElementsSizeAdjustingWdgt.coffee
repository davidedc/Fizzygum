# this file is excluded from the fizzygum homepage build

class StackElementsSizeAdjustingWdgt extends LayoutChromeWdgt


  category: 'Widgetic-Layouts'


  constructor: ->
    super()
    @noticesTransparentClick = true
    #@setColor Color.LIME
    @setMinAndMaxBoundsAndSpreadability (new Point 5,5) , (new Point 5,5), LayoutSpec.SPREADABILITY_HANDLES
    @minimumExtent = new Point 0,0

  @includeInNewWidgetMenu: ->
    # Return true for all classes that can be instantiated from the menu
    return false

  detachesWhenDragged: ->
    return false

  grabsToParentWhenDragged: ->
    return false

  # Re-apportion the split so my left edge lands EXACTLY where the pointer says -- solved in closed
  # form, not approached by an empirical gain.
  #
  # WHY a closed form exists. A divider can only bite in _reLayout's THIRD width regime ("more space
  # than needed or desired", Widget.coffee:4874-4896) -- regimes 1 and 2 hand out width from min/desired
  # alone, so max widths are INERT there. In that regime each stack cell gets
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
  # WHAT THIS REPLACED (~2015): an empirical fudge,
  #     deltaX = Δscreen.x * biggestMaxOfTheTwo^1.07 * 500 / (@parent.width() * 700) * (totalMax/biggestMaxOfTheTwo)
  # i.e. a gain of totalMax/@parent.width() scaled by 0.714 * biggest^0.07 -- constants fitted so that
  # product lands near 1 for the mid-range demo stacks (biggest ~220 => ~1.04), which is why it worked
  # at all. It was ~1.8x too fast for a stack holding a LayoutSpacerWdgt (whose max is ~1e6), its gain
  # DRIFTED mid-drag (biggestMaxOfTheTwo is re-read each move, and the maxes are exactly what the drag
  # changes), and totalMax summed ALL @parent.children -- including non-stack ones like the holder's
  # HandleWdgt. Measured against the pointer on an in-bounds 150px drag: max 44px / mean 7.4px error,
  # now 0.00px at every step.
  #
  # WHY ABSOLUTE, NOT INCREMENTAL. The old code integrated deltaDragFromPreviousCall, so every move
  # rejected or halved at a limit discarded that mouse travel FOREVER: drag past the bound and back and
  # the divider settled 91px away from the pointer, permanently. Taking the target from the absolute
  # pointer position (the idiom HandleWdgt:307-315 and SliderButtonWdgt:75-84 already use) re-syncs
  # perfectly instead. It also makes the split's landing place robust to the sub-pixel rounding in the
  # placement loop, which used to knock this drag onto a wholly different trajectory
  # (docs/archive/fractional-widget-bounds-investigation-plan.md).
  #
  # ⚠ WHY NOT THE OBVIOUS "read @left(), move it to the pointer". I defer settling, so ~13 pointer moves
  # are drained per frame against ONE end-of-cycle layout pass (docs/tooling/coalescing-measurement.md) -- my
  # @left() is STALE for every move but the last of a frame, so a @left()-based solve re-applies the
  # same correction N times and overshoots (measured 238px error at 5 moves/frame). The A/B form above
  # reads only maxWidth/desired FIELDS, which update synchronously, and never the laid-out pixels -- so
  # it is exact at any cadence (0.00px at 1, 2, 5, 13 and 40 moves per layout). That trap is very likely
  # why this was incremental in the first place: deltas are immune to stale geometry too, they just drift.
  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->

    # the user is in the process of dragging but didn't actually move the mouse yet. Kept for the "a
    # plain click does nothing" contract -- and it costs nothing now: the solve is ABSOLUTE, so a
    # skipped move's travel is recovered in full by the very next one.
    if !deltaDragFromPreviousCall?
      return

    leftWidget = @lastSiblingBeforeMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    rightWidget = @firstSiblingAfterMeSuchThat (m) ->
      m.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED

    return unless leftWidget? and rightWidget?

    # Where the pointer says my LEFT EDGE should be, in MY plane. nonFloatDragPositionWithinWdgtAtStart
    # is the grab grip, captured in my plane at drag start (ActivePointerWdgt.coffee:1096-1099).
    # Affine transforms §7.12: this REPLACES the old inverse-linear-part mapping of the screen DELTA (a
    # delta had to be mapped as the difference of two plane-mapped points, or the translation
    # double-applies) -- an absolute target needs no such care, and screenPointToMyPlane is identity off
    # any island, so the ex-@_isInsideNonIdentityIsland gate that kept the dormant path off the ancestor
    # walk is no longer worth its own branch here.
    targetLeft = (@screenPointToMyPlane pos).x - nonFloatDragPositionWithinWdgtAtStart.x

    # ONE walk of the stack children: D/sumMax over the WHOLE stack, A/B up to me. (These are
    # @parent.getRecursiveDesiredDim().x and @parent.getRecursiveMaxDim().x, inlined so the four sums
    # cost one walk rather than four. D needs no .min(sumMax) clamp: getMaxDim is literally
    # max(@maxWidth, getDesiredDim), so max_C >= des_C for every child and sumMax >= D always.)
    D = 0
    sumMax = 0
    A = 0
    B = 0
    beforeMe = true
    for C in @parent.children
      continue unless C.layoutSpec == LayoutSpec.ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED
      des = C.getDesiredDim().x
      max = C.getMaxDim().x
      D += des
      sumMax += max
      if C == @
        beforeMe = false
      else if beforeMe
        A += des
        B += max - des

    extraSpace = @parent.width() - D
    maxMargin = sumMax - D
    # Outside the third width regime there is no spare to apportion and max widths are inert, so the
    # drag genuinely cannot move anything -- bail rather than mutate to no visible effect.
    return unless extraSpace > 0 and maxMargin > 0

    delta = (targetLeft - @parent.left() - A) * maxMargin / extraSpace - B

    # FEASIBLE INTERVAL: neither cell may be pushed below its content (desired) width, where getMaxDim
    # clamps UP to getDesiredDim so the +delta/-delta stop cancelling and the conservation this solve
    # rests on breaks. CLAMP into the interval rather than REJECTING the whole move (what the old
    # `prev == newone` float-equality predicate did): clamping lands the divider exactly ON the bound and
    # leaves it re-synced the moment the pointer comes back, where rejecting dropped the move's entire
    # travel. lo <= 0 <= hi always (getMaxDim >= getDesiredDim), so delta = 0 is always feasible -- and,
    # unlike the `until deltaX = deltaX/2` halving loop this replaces, it cannot spin: that loop never
    # exited when a flanking cell was COLLAPSED (getMaxDim then returns 0,0 -- Widget.coffee:4677-4678),
    # because halving a negative underflows to -0 and `-0 > 0` is false forever. Dragging a divider
    # toward a collapsed neighbour used to hang the world.
    lmdd = leftWidget.getMaxDim()
    rmdd = rightWidget.getMaxDim()
    lo = leftWidget.getDesiredDim().x - lmdd.x
    hi = rmdd.x - rightWidget.getDesiredDim().x
    delta = Math.min(hi, Math.max(lo, delta))
    # at a bound (or on a pointer move too small to shift the split) there is nothing to do -- and this
    # costs ZERO mutations, where the old predicate still paid two on an accepted-but-pointless move.
    return if delta == 0

    # drag-move STREAM: the _-private deferred-settle entrypoint (restricted to stream handlers like this one by
    # check-layering [O]), which DECLARES intentional per-move deferred settling onto the one end-of-cycle flush
    # instead of reaching into the private _setMaxDimNoSettle core. Measured warranted here (~13 moves/frame
    # -> ~26 muts/frame; see docs/tooling/coalescing-measurement.md); toggle world.deferredSettlingEnabled to
    # self-settle-per-move and A/B it. (the plain setMaxDim self-settles, for discrete callers.)
    # (end-of-cycle-flush-drawdown -- CONVERT)
    leftWidget._setMaxDimDeferredSettle new Point lmdd.x + delta, lmdd.y
    rightWidget._setMaxDimDeferredSettle new Point rmdd.x - delta, rmdd.y


  # TODO: this mechanism to show the right cursor is 90%
  # there but could be better. The cursor changes to normal
  # as soon as the pointer gets out of the adjuster, which
  # happens while nonFloatDragging. It's not a big deal
  # and it's simpler, but something one could improve.
  mouseEnter: ->
    document.getElementById("world").style.cursor = "col-resize"
  
  mouseLeave: ->
    document.getElementById("world").style.cursor = "auto"


  # The size-adjuster's glyph: a grey filled circle. (The shared background
  # fill + clip + translate live in
  # LayoutChromeWdgt.paintIntoAreaOrBlitFromBackBuffer.)
  drawLayoutChrome: (aContext) ->
    aContext.fillStyle = @color.toString()
    
    centerX = @bounds.width() / 2
    centerY = @bounds.height() / 2
    radius = Math.min centerX, centerY
    radius = radius - radius / 20
    aContext.beginPath()
    aContext.arc centerX, centerY, radius, 0, 2 * Math.PI
    aContext.fillStyle = Color.GRAY.toString()
    aContext.fill()
    aContext.closePath()

