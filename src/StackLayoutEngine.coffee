# StackLayoutEngine

# The DIVISION-stack arrange — class-side only, never instantiated: siblings carrying
# DivisionStackLayoutSpecs jointly divide their container's MAIN axis by the three-point
# constraint box (min / desired / max), in three regimes:
#   1. under-min shrink   (available < Σmin: every child scaled below its minimum)
#   2. desired-margin     (Σmin ≤ available < Σdesired: min + a proportional share of the margin)
#   3. max-margin fill    (available ≥ Σdesired: desired + the spare apportioned by max−desired —
#                          the ONLY regime where max widths bite, which is why the divider
#                          (StackElementsSizeAdjustingWdgt) trades max and solves in closed form)
# One shared placement loop applies each child's chosen main extent; the CROSS axis is the
# container's full granted extent (stretch).
#
# AXIS-PARAMETERIZED: axis 'x' = a horizontal row dividing the container's width (cross:
# full height); axis 'y' = a vertical division stack dividing its height (cross: full
# width). The math is axis-blind — only the accessor pairing changes (main:
# width()/left()/right() vs height()/top()/bottom()).
#
# Invoked from base Widget._reLayout when a widget has division children; obeys the
# engine rulebook (docs/architecture/layout.md §8): one pass, idempotent, no read-backs —
# every input is a synchronously-maintained spec field, never laid-out pixels.
class StackLayoutEngine

  @arrange: (container, newBounds, axis = 'x') ->
    container._addOrRemoveAdders axis

    horizontal = axis == 'x'
    mainOf = (point) -> if horizontal then point.width() else point.height()

    minMain = mainOf container.getRecursiveMinDim()
    desiredMain = mainOf container.getRecursiveDesiredDim()
    maxMain = mainOf container.getRecursiveMaxDim()
    availMain = if horizontal then newBounds.width() else newBounds.height()

    # Each of the three regimes below differs ONLY in the per-child MAIN extent it hands
    # out, so each sets a childMainFor(C) closure (case preamble math hoisted); the ONE
    # shared placement loop underneath walks the division children and lays each out.
    if minMain >= availMain
      # we are forced into a space smaller than the minimum needed. We obey — we don't
      # want to rely on clipping what's beyond the allocated space (clipping has special
      # status in this implementation). E.g. available 10 vs Σmin 50 ⇒ every minimum is
      # further reduced by 1/5 to fit.
      reductionFraction = availMain / minMain
      childMainFor = (C) -> mainOf(C.getMinDim()) * reductionFraction

    # the min fits but the desired does not: more space than strictly needed, less than
    # desired — give every child its min, then redistribute what is left proportionally
    # to the desired margins.
    else if desiredMain >= availMain
      desiredMargin = desiredMain - minMain
      if desiredMargin != 0
        fraction = (availMain - minMain) / desiredMargin
      else
        fraction = 0
      childMainFor = (C) ->
        minC = mainOf C.getMinDim()
        desC = mainOf C.getDesiredDim()
        minC + (desC - minC) * fraction

    # min and desired both fit: allocate all the desired extents, and apportion the extra
    # space by the max margins.
    else
      maxMargin = maxMain - desiredMain
      totDesired = desiredMain
      extraSpace = availMain - desiredMain
      if extraSpace < 0
        console.error "this shouldn't happen, extraSpace is negative: " + extraSpace

      if maxMargin > 0
        fillByDesiredFraction = 0
      else if maxMargin == 0
        fillByDesiredFraction = 1
      else
        console.error "this shouldn't happen, maxMargin negative: " + maxMargin + " max: " + maxMain + " desired: " + desiredMain
        fillByDesiredFraction = 0

      childMainFor = (C) ->
        maxC = mainOf C.getMaxDim()
        desC = mainOf C.getDesiredDim()
        if (maxC - desC) > 0
          xtra = extraSpace * ((maxC - desC)/maxMargin)
        else
          xtra = 0
        desC + xtra + fillByDesiredFraction * (availMain - desiredMain) * (desC / totDesired)

    # The shared placement loop. The overflow guard runs for every case but only regime
    # 3's max-based fill can trip it: regimes 1 and 2 distribute to EXACTLY availMain
    # (their per-child extents telescope), so the running edge lands on the bound and
    # never exceeds it.
    childMainLo = if horizontal then newBounds.left() else newBounds.top()
    mainHiBound = if horizontal then newBounds.right() else newBounds.bottom()
    for C in container.children
      if !C.layoutSpec?.isDivisionElement?() then continue
      # Integer placement (Layer A): childMainFor() is a proportional (fractional) extent,
      # so round each child's lo/hi BOUNDARY to commit an integer @bounds -- but carry the
      # EXACT running position forward, so the children still telescope to the available
      # extent with no accumulated rounding drift and adjacent children share the one
      # rounded boundary. NB the rounding shifts the divider-drag reproportion onto a
      # different (still deterministic) trajectory —
      # docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
      childMainHi = childMainLo + childMainFor(C)
      # CROSS axis: 'stretch' fills the container's whole cross extent; 'start'/'center'/
      # 'end' give the cell its own cross-axis desired extent (recursive for a nested
      # container) at the chosen edge/middle of the band. Integer placement: crossLo is
      # composed from the (integer) granted bounds + a floored centring offset.
      crossLo = if horizontal then newBounds.top() else newBounds.left()
      crossExtent = if horizontal then newBounds.height() else newBounds.width()
      align = C.layoutSpec.crossAlign ? 'stretch'
      if align == 'stretch'
        crossHi = crossLo + crossExtent
      else
        crossDes = if horizontal then C.getDesiredDim().y else C.getDesiredDim().x
        cellCross = Math.min crossExtent, crossDes
        crossLo = switch align
          when 'center' then crossLo + Math.floor((crossExtent - cellCross)/2)
          when 'end' then crossLo + crossExtent - cellCross
          else crossLo
        crossHi = crossLo + cellCross
      if horizontal
        childBounds = new Rectangle \
          Math.round(childMainLo),
          crossLo,
          Math.round(childMainHi),
          crossHi
      else
        childBounds = new Rectangle \
          crossLo,
          Math.round(childMainLo),
          crossHi,
          Math.round(childMainHi)
      childMainLo = childMainHi
      if childMainLo > mainHiBound + 5
        console.error "division-stack distribution overflowed its allocated extent by " + (childMainLo - mainHiBound)
      # layout-apply-sanctioned: this IS the arrange — the engine is the extracted body of
      # Widget._reLayout's division branch, re-laying each child it just placed
      C._reLayout childBounds
    return
