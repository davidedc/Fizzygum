# The scrolling VIEWPORT — invisible in EFFECT, not by abstention: my color/alpha MIMIC the
# plane's (see _buildViewportChromeNoSettle), so my own painted rect always lies under the
# plane, indistinguishable. I own three pieces of chrome: the contents panel (the PLANE its
# content lives on — PINNED: scrolling never moves it; the stored scrollOffsetX/Y applies as
# a paint-time translation, see _writeScrollOffset/_scrollTranslation) and two SliderWdgt
# bars. NOT a PanelWdgt: a
# panel is a SURFACE whose children are content, while my children are chrome — my content
# lives one level down, on the plane — so the panel-family answers (its menu rows, its
# lock-granting, its drop slots) are wrong here, and the few panel facts I do mean are stated
# explicitly below (scroll-frame role plan P4).
class ViewportWdgt extends Widget

  # I clip my chrome (and through it the scrolled content) at my bounds — the same mixin
  # PanelWdgt wears, taken directly now (as FrameWdgt does). It also decides hit-testing
  # together with the RectangularAppearance the constructor sets: opaque inside my bounds,
  # even though my own rect is always painted UNDER the plane — occluded, not skipped.
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  # the panel facts I genuinely mean, restated off PanelWdgt:
  # around-the-content padding a caller can add via setContents (reads: the arrange,
  # scrollCaretIntoView)
  extraPadding: 0
  # an EMPTY generic viewport accepts drops (wantsDropOfChild consults the contents' veto)
  _acceptsDrops: true
  # a viewport is an editing surface: FrameWdgt shows the pencil off its contents'
  # answer, and the edit-mode focus walk climbs to the first opinion
  providesAmenitiesForEditing: true

  autoScrollTrigger: undefined
  hasVelocity: true
  padding: 0 # around the scrollable area
  isTextLineWrapping: false
  isScrollingByfloatDragging: true

  # ── SCROLL POLICY ──────────────────────────────────────────────────────────
  # 'auto'  — scroll iff content overflows. Bars are not a mode, they are the
  #           visible CONSEQUENCE of overflow: a fitting viewport already hides
  #           both bars and escalates every wheel, so it is behaviorally a
  #           plain panel with nothing to flip.
  # 'never' — behave as a plain cropping panel: every scroll path refuses at
  #           the movement cores (scrollX/scrollY), the bars never show, the
  #           wheel always escalates, and no scroll gesture engages. Contents
  #           sizing is DELIBERATELY unchanged — the contents panel still
  #           grows to its merged bounds and the overflow is clipped at my
  #           viewport, which IS plain-panel semantics.
  # Flipped live via setScrollPolicy (menu: toggleScrollPolicyFromMenu) with
  # no widget-tree change — policy over structure, the same verdict the
  # pop-ups reached for their unconditional rows viewport
  # (PopUpRowsViewportWdgt).
  scrollPolicy: 'auto'

  # Only the GENERIC viewport offers the crop⇄scroll flip in its menu:
  # the dedicated subclasses (list, toolbar, text, stack, pop-up rows) design
  # their scroll behavior in, so there the row would be menu rent plus a
  # footgun (cropping an inspector's list pane hides properties with no cue).
  # Each opts out with a one-line reason at its own declaration.
  offersScrollPolicyToggle: true
  scrollBarsThickness: undefined
  contents: undefined
  vBar: undefined
  hBar: undefined

  # ── THE SCROLL INDICATORS (program ruling G4) ─────────────────────────────────────────────
  # My two bars are OVERLAY INDICATORS: THIN and untouchable while my content overflows, absent
  # when it does not, and fattened into real controls while a pointer hovers my scroll band.
  # Everything here is presentation — what can be SCROLLED is asked of overflow (isScrollableNow),
  # never of a bar's visibility.
  #   Visibility is a pure DERIVATION from overflow: no activity stamps, no clock, nothing
  # time-driven on any path. An indicator on an overflowing pane is therefore the same pixels at
  # rest as it is a second after a scroll, which is what makes a capture of one reproducible and
  # what makes scrollability discoverable without a gesture.
  #
  # is a pointer hovering my scroll band right now (which fattens the indicators)
  _pointerInScrollBand: false

  # Hovering does not ride a file: a restored world wakes with no pointer in any band, exactly as
  # a freshly built one does. (The thin/absent state needs no transient — it is re-derived from
  # overflow at the first arrange.)
  @serializationTransients: [
    "_pointerInScrollBand"
  ]

  # Capability query: is aWdgt one of MY scrollbars? A SliderWdgt asks this of its parent to know whether
  # it is CHROME (a scrollbar → excluded from the editor-focus selection overlay) or content (a dropped
  # value control → framable). Only my actual bars match, so a content slider dropped into my content stays
  # framable. See SliderWdgt.excludedFromEditorFocusTracking.
  isMyScrollBar: (aWdgt) ->
    aWdgt is @vBar or aWdgt is @hBar

  # Role query, the plane-side twin of isMyScrollBar: is aWdgt the contents panel I clip and
  # scroll? THE one place the viewport topology is stated — the chokepoints
  # (_amITheContentsPanelOfAViewport, _amIDirectlyInsideViewport, the hierarchy
  # menu) ask this rather than pattern-matching the composite's shape, so ANY class serving as
  # my plane (the default ScrolledPaneWdgt, a FolderPanelWdgt, a ToolPanelWdgt, a stack)
  # answers uniformly. (scroll-frame role plan P3; type-test-elimination ε.)
  isMyContentsPanel: (aWdgt) ->
    aWdgt is @contents

  # Do my plane's DIRECT children live there as LOOSE scrollable content — things a drag may
  # scroll-or-detach, a caret follows into view, a lone text child offers soft-wrap for, a
  # container re-fit climbs through? True for a generic viewport; a ListWdgt answers false —
  # its pane holds the list's own rows machinery, not loose content — which is the exclusion
  # `_amIDirectlyInsideViewport`'s consumers relied on as `!(instanceof ListWdgt)`.
  contentsPanelHoldsLooseContent: ->
    true

  # My contents panel is internal structure — hide it from the ancestor hierarchy
  # (disambiguation) menu. Asked by Widget.hierarchyMenuWidgets via ?(); replaces two of its
  # structural exclusions (plain-panel-in-viewport, stack-in-stack-viewport — the
  # stack IS its viewport's contents). FolderWindowWdgt declares the third the same way.
  hidesContainedWidgetFromHierarchyMenu: (aWdgt) ->
    @isMyContentsPanel aWdgt

  # ── the plane's up-relays (scroll-frame role plan P3) ─────────────────────────────────────
  # My paint values MIMIC my contents' (I DO paint every repaint, at alpha 1 once
  # _buildViewportChromeNoSettle adopts the contents' own — but always UNDER the plane, so no
  # pixel of mine is ever visible; menus and readers still see my fields), and the plane keeps
  # them true by notifying me when it is recolored directly. Bare field writes: there is
  # nothing of me to invalidate — my own paint is always fully occluded, and the plane's own
  # super covers every visible recoloured pixel. Guarded on a real value: Widget.setColor
  # returns undefined on a no-change call, and writing that through would clobber the mimic.
  _reactToChildColorChanged: (child, aColor) ->
    return unless child is @contents and aColor?
    return if @color?.equals aColor
    @color = aColor

  _reactToChildAlphaChanged: (child, alpha) ->
    return unless child is @contents and alpha?
    unless @alpha == alpha
      @alpha = alpha

  # Two independent scroll-by-drag flags (only live while scrollbars show): drag the
  # contents, or drag the background — independently, e.g. useful for a geographic map.
  canScrollByDraggingBackground: false
  canScrollByDraggingForeground: false

  constructor: (
    @contents,
    @scrollBarsThickness = (WorldWdgt.preferencesAndSettings.scrollBarsThickness),
    @sliderColor
    ) ->
    # seed alpha 0 here; _buildViewportChromeNoSettle immediately overwrites it with the
    # contents' own (which defaults to 1) — my own values just MIMIC the plane's, and my
    # painted rect ends up fully occluded under the plane and bars, not skipped
    @alpha = 0
    super()
    # the appearance also decides hit-testing: an appearance-bearing widget answers opaque
    # inside its tight bounds. It DOES paint every repaint (once the mimic below adopts the
    # contents' alpha, typically 1) -- just always fully occluded under the plane and bars;
    # the colors seed the mimic until _buildViewportChromeNoSettle adopts the contents' own
    @appearance = new RectangularAppearance @
    @color = WorldWdgt.preferencesAndSettings.defaultPanelsBackgroundColor
    @strokeColor = WorldWdgt.preferencesAndSettings.defaultPanelsStrokeColor
    @_buildViewportChrome()

  # Build the viewport (contents + h/v scrollbars) via the NoSettle core, settling ONCE at the end
  # (orphan-settledness: `new ViewportWdgt` returns settled). The name is deliberately DISTINCT from the
  # leaf builder `_buildAndConnectChildren`: ViewportWdgt is a base whose subclass ListWdgt OVERRIDES
  # `_buildAndConnectChildren` to build its list CONTENTS, and CoffeeScript binds a subclass's constructor
  # params (@elements, …) only AFTER super(). If THIS base constructor called the (virtual)
  # `_buildAndConnectChildren`, `new ListWdgt` would dispatch into ListWdgt's contents-core during super()
  # with @elements still undefined → crash. So the base builds only its own chrome here (a name ListWdgt
  # does not override); ListWdgt's constructor builds its contents via `_buildAndConnectChildren` AFTER super().
  _buildViewportChrome: ->
    @_settleLayoutsAfter => @_buildViewportChromeNoSettle()

  _buildViewportChromeNoSettle: ->
    @contents = new ScrolledPaneWdgt() unless @contents?
    # _addNoSettle (NOT the self-settling public add): we are building our own innards
    # during construction; I am not parented yet, so a flush here would be a
    # redundant whole-world relayout (and would throw if we are built during a layout pass).
    @_addNoSettle @contents

    # the Viewport paints every repaint just like any RectangularAppearance widget, but always
    # fully occluded under its own contents+bars -- so what matters is that its values MIMIC
    # the contained Panel's
    @color = @contents.color
    @alpha = @contents.alpha

    @hBar = new SliderWdgt 1, 100, 50, 10, color: @sliderColor
    @hBar._applyHeight @scrollBarsThickness
    @_addNoSettle @hBar

    @vBar = new SliderWdgt 1, 100, 50, 10, color: @sliderColor
    @vBar._applyWidth @scrollBarsThickness
    @_addNoSettle @vBar

    # Bind each bar with the PUBLIC wire verb any other citizen would use — the RECIPROCAL one, since
    # a scrollbar both drives my scroll pin and must follow it. The old direct @target/@action
    # assignment kept the forward edge outside the wire vocabulary, and made the reverse one a
    # hand-rolled push into these two fields — which is why only these two bars ever learned anything
    # (connector plan §P8, complaint ①). trackTarget also takes the initial value FROM me rather than
    # pushing the bar's constructed default at me.
    @hBar.trackTarget @, "setScrollX"
    @vBar.trackTarget @, "setScrollY"

    @_reLayoutScrollbars()

  wantsDropOfChild: (aWdgt) ->
    # the CONTENTS vetoes raw drops into the viewport (a folder's contents are managed by the
    # folder-window machinery) — capability via ?(), instead of `@contents instanceof FolderPanelWdgt`
    # (type-test-elimination ε)
    return false if @contents?.vetoesViewportDrops?()
    return @_acceptsDrops

  colloquialName: ->
    # the CONTENTS names the construct ("folder"/"toolbar") — capability via ?(), was two
    # `@contents instanceof` tests (type-test-elimination ε)
    @contents?.viewportColloquialName?() ? "viewport"

  # ── THE SCROLL PINS ──────────────────────────────────────────────────────────────────────────
  # How far my content is scrolled inside my viewport, along each axis: 0 at the top/left, growing
  # to the overflow. These are the numbers my scrollbars drive and show, and until §P8 they were
  # reachable only by direct assignment — no connect menu offered them, and nothing could read them.
  #
  # ⚠ READABLE, where Widget's `width`/`height` deliberately are not (widget-authoring-guidelines
  # §11): a reader is a licence to BIND, and geometry is where the one-way layout↔dataflow law makes
  # that expensive. A scrollbar is precisely the case that needs it — it must FOLLOW what it drives —
  # so §P8 pays that price here and nowhere else, and `_reLayoutScrollbars` below is where the bill
  # comes due.

  getScrollX: -> @scrollOffsetX

  getScrollY: -> @scrollOffsetY

  # ── THE STORED SCROLL OFFSET (paint-time-scroll-translation plan §3.1) ────────────────────
  # THE scroll state: how far the visible window sits into the content FRAME, per axis —
  # `windowOrigin_in_plane = @contents.position() + offset`. INTEGER, ≥ 0, clamped to
  # [0, max(0, contentExtent − windowExtent)] (_keepScrollOffsetInBounds). Scrolling never moves
  # the plane: children keep their plane coordinates forever, and the offset is applied as a
  # paint-time translation (the content-recursion override below) and consumed by the
  # screen↔plane mapping walks through scrollTranslationOfChild. Two scalar prototype
  # defaults — scalars, NOT a Point (⛔ a class-level constant may never reference another
  # class, docs/architecture/immutable-value-classes.md §3), and scalars serialize
  # own-only-when-scrolled (the spreadsheet's viewOriginCol/Row pattern).
  scrollOffsetX: 0
  scrollOffsetY: 0

  # The plane→screen translation for my contents subtree: the visible window's plane rect is
  # [contents.position() + offset, … + my extent] and it renders at my own box, so a plane
  # point p appears at p + t with t below. Measured from the FRAME's origin (not my own
  # position) so a frame the arrange legitimately extends above/left of my origin — loose
  # content dragged past the top edge — keeps its old reachability arithmetic: the offset
  # grows with the frame (the arrange's origin-shift bookkeeping) and t stays 0 until a real
  # scroll happens.
  _scrollTranslation: ->
    new Point @left() - (@contents.left() + @scrollOffsetX), @top() - (@contents.top() + @scrollOffsetY)

  # The per-child-edge capability hook the screen↔plane walks ask of every ancestor they
  # climb through (plan §3.2; the walks: Widget's mapRectToScreen / screenPointToMyPlane /
  # localPointToScreen / screenBounds / _enclosingMappedPlaneRoot, and the clipThrough
  # translation edge). Answers ONLY for my contents edge — my bars are FIXED children of the
  # same parent, so the §7.6 fixed-vs-scrolled-children split is answered structurally, per
  # child edge, with no stored role — and ONLY when the translation is real: at (0,0) the
  # answer is `undefined`, the walks contribute nothing, and their same-object dormant
  # returns are preserved.
  scrollTranslationOfChild: (child) ->
    return undefined unless child is @contents
    t = @_scrollTranslation()
    return undefined if t.x is 0 and t.y is 0
    t

  # The paint-time scroll (plan §3.3), intercepted at the same content-recursion point the
  # island composites at: self (the mimic rect) and the BAR children paint in place; the
  # CONTENTS subtree paints through the scroll translation — the shadow-pass two-step (cull
  # rect moved opposite the paint, ctx translated with it; both integer × dpr, so the CTM
  # composition is FP-exact). Culling needs nothing more: each descendant intersects the
  # descending rect with its own plane-local bounds, so scrolled-out content prunes exactly
  # as clipped-out content does. Zero translation takes the stock clipping path — dormancy —
  # via PanelWdgt's injected mixin copy (`super` here would bind to base Widget's un-clipping
  # version: the mixin is injected onto THIS prototype, and a class-body member shadows it).
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    t = @_scrollTranslation()
    if t.x is 0 and t.y is 0
      return PanelWdgt::_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow.call @, aContext, clippingRectangle, appliedShadow
    damagedPartOfFrame = @boundingBox().intersect clippingRectangle
    if !damagedPartOfFrame.isEmpty()
      if aContext == world.worldCanvasContext
        @_recordDrawnAreaForNextDamageRects()
      @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
      translatedCull = damagedPartOfFrame.translateBy t.neg()
      @children.forEach (child) =>
        if child is @contents
          aContext.save()
          aContext.translate t.x * ceilPixelRatio, t.y * ceilPixelRatio
          child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, translatedCull, appliedShadow
          aContext.restore()
        else
          child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow

  # The SHADOW-pass twin of the interception above (paint-time scroll review F3): the mixin's
  # own-shadow entry enumerates children itself — bypassing the content pass — so without this
  # a viewport wearing its OWN shadow, painting translucent (alpha != 1, the one case whose
  # silhouette depends on the children), while scrolled, would silhouette the UNTRANSLATED
  # content. Same two-step around the contents child, same dormant delegation to the injected
  # mixin copy (`super` would bind to base Widget's un-clipping version).
  _fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    t = @_scrollTranslation()
    if t.x is 0 and t.y is 0
      return PanelWdgt::_fullPaintIntoAreaOrBlitFromBackBufferJustShadow.call @, aContext, clippingRectangle, appliedShadow
    # from here: the mixin's JustShadow body (kept in lockstep with it), with the contents
    # child painted through the scroll translation
    clippingRectangle = clippingRectangle.translateBy appliedShadow.offset.neg()
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      damagedPartOfFrame = @boundingBox().intersect clippingRectangle
      if !damagedPartOfFrame.isEmpty()
        aContext.save()
        aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio
        @paintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
        # opaque short-circuit as in the mixin: a fully opaque box's silhouette IS its box
        if @alpha != 1
          shadowTranslatedCull = damagedPartOfFrame.translateBy t.neg()
          @children.forEach (child) =>
            if child is @contents
              aContext.save()
              aContext.translate t.x * ceilPixelRatio, t.y * ceilPixelRatio
              child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, shadowTranslatedCull, appliedShadow
              aContext.restore()
            else
              child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, damagedPartOfFrame, appliedShadow
        aContext.restore()

  # The pin-setter contract (widget-authoring-guidelines §11): every delivery passes ONE argument,
  # the value.
  #   ⚠ CLAMPED, through the same `scrollX`/`scrollY` every other scroll path uses. The predecessor
  # moved the content raw, which could commit an over-scrolled state no gesture can produce (the
  # defect `scrollTo`'s own comment records). It also matters now that the bars are really wired: a
  # bar that is hidden because there is nothing to scroll still holds its constructed default, and
  # clamping is what makes delivering that a no-op instead of shoving the content off its viewport.
  setScrollX: (num) ->
    num = parseFloat num  unless typeof num is "number"
    return  if isNaN num
    if @scrollX @scrollOffsetX - num
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()
    return num

  setScrollY: (num) ->
    num = parseFloat num  unless typeof num is "number"
    return  if isNaN num
    if @scrollY @scrollOffsetY - num
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()
    return num

  # ⭐ Both ANNOUNCE, and the audit behind that word is short only because the class is built so that
  # it can be: EVERY path that moves my content — a wheel, a thumb drag, a track click, a caret
  # scrolled into view, a drop that re-fits me, `scrollTo`, `scrollToBottom`, the two setters above —
  # ends at `_reLayoutScrollbars`, and that is where the announcement is raised. So a follower is
  # woken whatever moved the scroll, which is exactly the promise `announces` makes.
  #   ⚠ The promise is about the FUNNEL, not about the setters. A class whose setter announces but
  # whose gesture path does not would be announcing a subset and saying so with the same word — see
  # PaletteWdgt, whose own audit found precisely that shape.
  pins: -> super().concat [
    new PinSpec "scroll x", "numerical", set: "setScrollX", get: "getScrollX", announces: true
    new PinSpec "scroll y", "numerical", set: "setScrollY", get: "getScrollY", announces: true
  ]

  # What SCALE does this pin of mine live on, for a slider bound to it? (SliderWdgt.reflectTarget.)
  # The VALUE itself the slider reads through the pin's own reader; these are the three numbers a
  # thumb needs besides it — which is why the reverse edge carries no payload of its own.
  sliderRangeForPin: (pin) ->
    switch pin.label
      when "scroll x" then @_scrollRangeAlong @width(), @contents.width()
      when "scroll y" then @_scrollRangeAlong @height(), @contents.height()
      else undefined

  # One axis' scale: I can be scrolled along it exactly when my content overflows my viewport — the
  # same test that decides whether the bar shows at all — the scale runs from 0 to that overflow, and
  # the thumb covers the visible fraction of it. `undefined` when there is nothing to scroll: a bar
  # showing an empty scale means nothing, and a zero-width one divides by zero in the thumb geometry.
  _scrollRangeAlong: (viewport, content) ->
    # under 'never' there is no scale to live on — a bound external slider gets
    # the same "nothing to scroll" answer as the fitting case
    return undefined if @scrollPolicy is 'never'
    return undefined unless content >= viewport + 1
    stop = content - viewport
    new SliderRange 0, stop, viewport / content * stop

  # The runtime crop⇄scroll flip: validate, assign, then INVALIDATE inside a
  # settle — the flush re-lays me (my _reLayout is 'super; @_reLayoutChildren'),
  # so a flip on a live overflowing viewport shows/hides its bars and re-clamps
  # its contents in one pass, through the standard deferred shape. The scroll
  # pins stay advertised under 'never' (a policy flip mid-life must not sever
  # wires) — a delivery simply no-ops at the refused cores.
  setScrollPolicy: (policy) ->
    return unless policy is 'auto' or policy is 'never'
    return policy if policy is @scrollPolicy
    @scrollPolicy = policy
    @_settleLayoutsAfter => @_invalidateLayout()
    return policy

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu for the shape): the
  # menu items carry no arguments, and dispatch fills the leading slots with
  # the menu item + the enclosing panel's target, so the real setter must not
  # be wired directly.
  toggleScrollPolicyFromMenu: (ignored, ignored2) ->
    @setScrollPolicy (if @scrollPolicy is 'never' then 'auto' else 'never')

  setColor: (aColor) ->
    aColor = super aColor
    # keep in sync the color of the content.
    # Note that the container Viewport
    # paints every repaint too (mimicking this color) but is always occluded underneath it.
    @contents.setColor aColor
    return aColor

  setAlphaScaled: (alpha) ->
    alpha = super
    # update the alpha of the Viewport - note that I paint it every repaint too (always
    # occluded under the contents), so keep updating it so its value mimics the
    # contained Panel's
    @contents.setAlphaScaled alpha
    return alpha

  # CAN I be scrolled right now: is there overflow to move, and does my policy allow moving it?
  # This is the question every scroll GESTURE asks — deliberately NOT "is a bar visible". Under
  # ruling G4 an indicator is a THIN hairline the pointer passes through, so keying a gesture to
  # a bar's visibility would key it to presentation.
  isScrollableNow: ->
    return false if @scrollPolicy is 'never'
    (@contents.width() >= @width() + 1) or (@contents.height() >= @height() + 1)

  # Would a plain drag pressed anywhere in me be MINE — a scroll of my pane? The hand asks this of
  # a press's ancestry to know whether a finger has to HOLD before its drag can mean what a mouse
  # drag means (ruling I2: a hold is demanded only where a plain drag already means scroll). It is
  # the same three facts my scroll-drag step is installed on — I take drags at all, my policy allows
  # scrolling, and there is overflow to move — asked before the press instead of during it.
  claimsPlainDragsForScrolling: ->
    @isScrollingByfloatDragging and @isScrollableNow()

  # ── the indicator derivation (ruling G4) ──────────────────────────────────────────────────

  # thin at rest, my full bar thickness once a hovering pointer has fattened the indicators
  _indicatorThickness: ->
    if @_pointerInScrollBand
      @scrollBarsThickness
    else
      WorldWdgt.preferencesAndSettings.scrollIndicatorThickness

  # Hand the bars the presentation my state implies. _-tier: my own arrange is the only caller and
  # the only one there can be — the look is settled in the same pass that decided which bars show
  # at all, so there is nothing left for anyone else to advance and nothing steps.
  _refreshScrollIndicators: ->
    mode = if @_pointerInScrollBand then 'fat' else 'thin'
    for bar in [@hBar, @vBar]
      continue unless bar?.showAsScrollIndicator?
      continue unless @_barIsMineToPresent bar
      bar.showAsScrollIndicator mode
    return

  # Is this bar CHROME I present? My @hBar/@vBar fields deliberately survive the bar being picked
  # up off me (it keeps driving me from wherever it lands — that is the point of the dataflow
  # edge), so the field alone does not say. Parentage does: a bar outside my children is a plain
  # slider somebody put on the desktop, and its look and its thickness are its own business.
  _barIsMineToPresent: (bar) ->
    bar.parent is @

  # THE HOVER PASS. A thin indicator is not a target (ruling G3), so it can never notice the
  # pointer itself — I notice for it, and I can: I am in the hand's mouse-over ancestry for
  # anything under my content, so I get the moves. A pointer within a fat bar's width of my
  # scroll edges fattens both indicators; anywhere else, or leaving me, thins them again.
  #   ⚠ The `pos` parameter is deliberately NOT read: a move over my scrolled CONTENT can
  # escalate here with the position still in the ROW's plane, offset-pixels away from mine —
  # the same trap mouseDownLeft documents. Re-derive it from the hand with the mapped read.
  mouseMove: ->
    @_updatePointerInScrollBand @screenPointToMyPlane world.hand.position()

  mouseLeave: ->
    @_updatePointerInScrollBand undefined

  _updatePointerInScrollBand: (pos) ->
    band = @scrollBarsThickness
    inBand = pos? and @boundsContainPoint(pos) and
      ((pos.x >= @right() - band) or (pos.y >= @bottom() - band))
    return if inBand is @_pointerInScrollBand
    @_pointerInScrollBand = inBand
    # the flip changes the bars' THICKNESS as well as their look, so it goes through the
    # arrange that owns their geometry rather than through _refreshScrollIndicators alone
    @_reLayoutScrollbars()

  # The width my @contents must lay itself out within: my viewport width. Asked via ?() by
  # content that wraps to its container (ToolPanelWdgt's row-wrap). Capability, was
  # `parent instanceof ViewportWdgt` at the caller (type-test-elimination ε).
  widthContentsMustFitWithin: ->
    @width()

  # The height twin, for content that fits to BOTH axes of the box it is given (a toolbar
  # grid deciding how many cells its strip shows before the rest go behind the chevron).
  heightContentsMustFitWithin: ->
    @height()

  # Pressing a slider's TRACK jump-drags the button to the press point when the slider is
  # chrome its parent owns (my scrollbars) — SliderWdgt.mouseDownLeft asks its parent via ?().
  # PromptWdgt gives its input slider the same policy. Capability, was
  # `(parent instanceof ViewportWdgt) or (parent instanceof PromptWdgt)` (type-test-elimination ε).
  sliderTrackPressJumpsButton: ->
    true

  # (no childrenCanLockToMe here: my direct children are chrome, not user-lockable content, and
  # the lock-menu row keys on the capability EXISTING — see PanelWdgt.childrenCanLockToMe —
  # so a viewport simply not defining it is the opt-out)

  # Am I a content-sizing viewport — one whose content frame derives from a PURE measure
  # of @contents's children (§4.1 Stage C, see _positionAndResizeChildren)? The two dedicated
  # subclasses (TextAreaWdgt / VerticalStackViewportWdgt) always
  # are; a plain viewport is when text-wrapping. Class-level query, was two self-instanceof
  # tests at the arrange site (type-test-elimination ε).
  isContentSizing: ->
    @isTextLineWrapping

  _reLayoutScrollbars: ->
    # §4.2 Stage 3 (structural arrange): the bars below apply their geometry via the NON-notifying
    # arrange twins (_applyExtentBase / _applyMoveToBase), not the notifying setters -- they are
    # chrome I own and place from my own size, never affecting my content-fit, so notifying would
    # only trigger a redundant confirm pass. The @_adjustingContentsBounds save/restore this used to
    # need is gone along with the notify-by-mutation seam it guarded against.
    # See docs/archive/proper-layouts-4.2-structural-arrange-plan.md.

    # one typically has both scrollbars in view, plus a resizer
    # in bottom right corner, so adjust the width/height of the
    # scrollbars so that there is no overlap between the three things
    spaceToLeaveOnOneSide = Math.max(@scrollBarsThickness, WorldWdgt.preferencesAndSettings.handleSize) + 2 * @padding
    hWidth = @width() - spaceToLeaveOnOneSide
    vHeight = @height() - spaceToLeaveOnOneSide

    # the indicator's CROSS-axis size: thin at rest, my full bar thickness while a hovering
    # pointer has fattened it back into a control (ruling G4)
    barThickness = @_indicatorThickness()

    @_changed()

    # this check is to see whether the bar actually belongs to this Viewport: a bar can survive
    # detached from its original Viewport A (it's referenced as a property, not a child, so
    # duplicating A into B does not retarget or duplicate the bar), leaving B referencing A's bar. We
    # ask the bar whether it drives ME before touching it, so a stray duplicate never resizes/hides a
    # scrollbar that belongs to a different panel. (`isWiredTo` since §P4 — a controller owns a LIST
    # of wires, so "do you drive me" is a search, not a field comparison.)
    #   ⚠ SOAKED, and that is not decoration: this guard is the gate for everything below it, so it has
    # to answer for a @hBar that is not (yet) a live controller — mid-deserialization a widget reference
    # can still be unresolved, which is the same case SliderWdgt.unitSize guards for on its own @button.
    # The field comparison this replaced was total by accident (`<anything>.target == @` is just false);
    # asking a METHOD is not, and a bar that cannot answer is exactly a bar I must not touch.
    if @hBar.isWiredTo? @
      # a 'never' viewport shows no bars whatever the overflow — same hide arm the
      # fitting case takes
      if @scrollPolicy isnt 'never' and @contents.width() >= @width() + 1
        @hBar.show()
        # chrome I own and place -- apply via the non-notifying twin as above (see the method-top
        # comment). _applyExtentBase == _applyWidth/Height minus the seam; preserves height/width by
        # passing the current other axis.
        # the cross axis is INDICATOR presentation, so it is imposed only on a bar I still hold;
        # one picked up onto the desktop keeps the thickness it left with (_barIsMineToPresent).
        hThickness = if @_barIsMineToPresent @hBar then barThickness else @hBar.height()
        @hBar._applyExtentBase new Point(hWidth, hThickness)  if @hBar.width() isnt hWidth or @hBar.height() isnt hThickness
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # Viewport, otherwise we don't move it.
        if @hBar.parent == @
          @hBar._applyMoveToBase new Point @left(), @bottom() - @hBar.height()
        # I placed and sized the bar through the NON-notifying twins, so re-laying it is MINE to do
        # -- the same rule I follow for @contents in _positionAndResizeChildren. A slider's THUMB is
        # derived from its frame (SliderButtonWdgt._reLayoutSelf reads its parent's height and
        # position), so a bar whose frame I just changed and whose thumb nobody re-lays is left
        # INTERNALLY INCONSISTENT -- which the arrange-idempotence census correctly reports as a
        # mover. The retired four-number push happened to do this on its way past; it is a LAYOUT
        # obligation, not a dataflow one, so it stays here where the frame changes.
        @hBar._reLayoutSelfAndButton()
      else
        @hBar.hide()

    # see comment on equivalent if line above.
    if @vBar.isWiredTo? @
      # 'never' shows no bars — see the hBar above
      if @scrollPolicy isnt 'never' and @contents.height() >= @height() + 1
        @vBar.show()
        # §4.2 Stage 3: same as the hBar above -- non-notifying twin (chrome I own, never affects content-fit).
        # the cross axis is presentation — imposed only on a bar I still hold (see the hBar above)
        vThickness = if @_barIsMineToPresent @vBar then barThickness else @vBar.width()
        @vBar._applyExtentBase new Point(vThickness, vHeight)  if @vBar.height() isnt vHeight or @vBar.width() isnt vThickness
        # we check whether the bar has been detached. If it's still
        # attached then we possibly move it, together with the
        # Viewport, otherwise we don't move it.
        if @vBar.parent == @
          @vBar._applyMoveToBase new Point @right() - @vBar.width(), @top()
        # same as the hBar above: I changed its frame through the non-notifying twins, so its thumb
        # is mine to re-lay.
        @vBar._reLayoutSelfAndButton()
      else
        @vBar.hide()

    # the bars that show have just been sized and placed; give them the look that goes with the
    # state they show in (thin, or fat under a hovering pointer)
    @_refreshScrollIndicators()

    # ── THE REVERSE EDGE (connector plan §P8) ────────────────────────────────────────────────
    # My scroll geometry just settled, so ANNOUNCE it and let whoever tracks me re-read it — instead
    # of pushing four numbers into the two bars I happen to hold fields for. Everything above this
    # line is still field business, and rightly: SHOWING, SIZING and PLACING the bars is chrome I own
    # and only my own two are mine to place. The four NUMBERS are not chrome, they are the state, and
    # any number of bars may want them — a duplicate, a bar someone unplugged onto the desktop, one
    # belonging to nobody. That is complaint ① closed.
    #   markNonValueChange, not markStale: my scroll offset is not my VALUE (I declare no principal
    # pin — a viewport has no one number), and this wakes only the edges that asked to re-read me,
    # so it is DARK when nothing tracks me.
    # ⚠ This is a LAYOUT station marking DATAFLOW, which the engine's standing one-way law otherwise
    # forbids. It is deliberate, and it is option (c) of §P3's reframed table: announce here, drain
    # whenever the drain next runs.
    # ⭐ MEASURED (§P8, .scratch/p8-scroll-shear-probe.js), because the objection to (c) was that a
    # tracking pair would SHEAR by a frame under fast motion. It does not, and the reason is the
    # CYCLE ORDER read the other way round: doOneCycle plays input BEFORE the dataflow station, so a
    # scroll driven by a wheel, a thumb drag or a track click announces itself in time for the SAME
    # cycle's drain — measured lag ZERO frames, at every fling rate. The one-frame lag is real only
    # for a change that originates INSIDE recalculateLayouts (a content re-fit changing the bar's
    # RANGE) — measured at exactly 1 frame — which is the case with no motion to shear against.
    # So (d)'s second drain+layout pass would buy nothing on the only path that moves.
    world.dataflow.markNonValueChange @

  # when you add things to the ViewportWdgt they actually
  # end up in the plane inside it.
  # This would also apply to resizing handles - so we need to
  # correct for that case
  add: (aWdgt, opts = {}) ->
    # annotation + handle both attach to the viewport directly (was their two instanceof)
    # (type-test-elimination campaign). Keyed off the WIDGET, not the layoutSpec argument:
    # handles are added with no explicit spec (defaultLayoutSpecWhenAddedTo resolves it inside
    # the add), so the argument is undefined exactly for the widgets this must catch.
    if aWdgt.attachesToViewportDirectly?()
      super
    else
      # crossing the plane edge: opts.positionInPlane arrives expressed in MY plane (the drop
      # dispatcher maps it for the drop TARGET, which is me on this path) — re-express it in
      # the CONTENTS plane, or a scrolled plane's insert-index compare is short by exactly the
      # scroll translation (paint-time scroll review F2). Inverse = subtract, the same
      # arithmetic screenPointToMyPlane applies at this edge; no-op when unscrolled.
      if opts.positionInPlane? and (translation = @scrollTranslationOfChild @contents)?
        opts = Object.assign {}, opts, positionInPlane: opts.positionInPlane.subtract translation
      @contents.add aWdgt, opts
      # Intentional synchronous APPLY (not an off-settle trigger to defer): add / addMany /
      # showResizeAndMoveHandlesAndLayoutAdjusters are public content-change ENDPOINTS, idempotent
      # with this viewport's own _reLayout ('super; @_reLayoutChildren'), distinct from the seam sites
      # (raw-mutator / gesture triggers), which DO defer -- see
      # docs/archive/deferred-layout-residuals-audit.md. Deferring this re-fit was tried and rejected
      # (diverges nested-scroll geometry for zero gain) -- see
      # docs/archive/layout-system-architecture-assessment.md, "Do not revisit (already falsified)".
      # layout-apply-sanctioned: public content-change endpoint, idempotent w/ _reLayout (OVERVIEW §11 PROOF 2)
      @_reLayoutChildren()

  # thin-wrap-exempt: SYNCHRONOUS content-change endpoint -- @contents.addMany + immediate @_reLayoutChildren
  # (re-reading APPLIED geometry is load-bearing; deferring it diverges nested-scroll geometry, exactly as
  # for add() -- see docs/archive/layout-system-architecture-assessment.md, "Do not revisit"). The
  # _addManyNoSettle twin below is the non-settling core for in-flush callers (createToolsPanel), NOT a
  # settle the public form should route through.
  addMany: (widgetsToBeAdded) ->
    @contents.addMany widgetsToBeAdded
    @_reLayoutChildren() # layout-apply-sanctioned: public content-change endpoint -- see add() (OVERVIEW §11 PROOF 2)

  # NON-settling core: forward to @contents' addMany core (the buttons attach to the scrolled ToolPanelWdgt, NOT
  # this viewport -- like add() -> @contents.add above), then SCHEDULE this viewport's re-fit. The enclosing wrapper's
  # flush applies it -- vs the public addMany's synchronous @_reLayoutChildren endpoint (which is off-settle).
  _addManyNoSettle: (widgetsToBeAdded) ->
    @contents._addManyNoSettle widgetsToBeAdded
    @_invalidateLayout()


  # Override the NON-settling CORE (the public showResizeAndMoveHandlesAndLayoutAdjusters wrapper is inherited from
  # Widget and self-settles once around the whole show-handles tree). super adds the handles + climbs; @_reLayout
  # Children re-fits my contents+scrollbars synchronously, riding that outer settle. (end-of-cycle-flush-drawdown.)
  _showResizeAndMoveHandlesAndLayoutAdjustersNoSettle: ->
    super
    @_reLayoutChildren() # layout-apply-sanctioned: public content-change endpoint -- see add() (OVERVIEW §11 PROOF 2)

  
  setContents: (aWdgt, extraPadding = 0) ->
    @extraPadding = extraPadding
    # the outgoing contents is construction scaffold (every caller replaces a
    # just-built default with the real content) -- destroy it outright: closing
    # it instead would file unreferenced debris into the bin on every panel build.
    @contents.fullDestroyChildren()
    @contents._applyMoveTo @position()
    # fresh content: any prior scroll state is meaningless
    @_writeScrollOffset 0, 0

    aWdgt._applyMoveTo @position().add @padding + @extraPadding

    @add aWdgt


  # SCROLL-POSITION POLICY, not a child re-lay (schedule-valve V1): a REAL immediate resize of a
  # text-wrapping viewport resets its scroll to the content origin (offset := 0 — the shipped
  # reset-scroll-on-resize behaviour; re-wrapped text re-reads from the top), while a re-lay at an
  # unchanged viewport must never touch the scroll position. The reset lives AT the resize event
  # because only the event knows the delta — a scheduled/settle re-lay enters _reLayout with the
  # extent already committed, so an extent-delta gate inside _reLayout structurally cannot see an
  # immediate resize. Resetting BEFORE super is safe (the plane never moves; only the offset
  # zeroes); the arrange that follows (via the resize re-lay) then merges and clamps as usual.
  # A plane that keeps its scroll across resizes (a wrapping STACK, whose scroll position the
  # arrange's clamp owns and normalizes) declares itself out — managesOwnScrollPinning, the P5
  # contract: under the offset model the seam is purely this reset POLICY per plane kind, no
  # longer a question of who may write the plane's position (nobody moves a plane any more).
  _applyExtent: (aPoint) ->
    if !aPoint.equals(@extent()) and @isTextLineWrapping and !@contents.managesOwnScrollPinning?()
      @_writeScrollOffset 0, 0
    super aPoint


  # Gesture-driven container re-fit (a widget was dropped into / grabbed out of me): DEFER it to the
  # cycle via _reFitContainer -> _scheduleRelayoutRespectingPhase. These are dispatched from
  # ActivePointerWdgt.drop/grab AFTER a self-settling add, so they always run OUTSIDE any layout pass --
  # the off-pass arm (invalidate self; my _reLayout is 'super; @_reLayoutChildren', so the cycle re-fits
  # me identically) is what runs. The in-pass arm (a no-climb enqueue, for a caller that DOES fire
  # mid-pass) is never exercised here. See deferred-layout-residuals-audit.md fam 2.
  _reactToChildDropped: ->
    @_reFitContainer()

  _reactToChildGrabbed: (child) ->
    @_reFitContainer()

  # Re-fit my contents area and my scrollbars: the named "re-fit me" pair, shared
  # by every trigger that changes what I contain (drops, grabs, attaches, a
  # contained panel's notification). Inherited by ListWdgt and the other viewports
  # -- they all re-fit the same way (the ListWdgt opt-out below is ONLY
  # for the contained-panel notification, not for this pair).
  _reLayoutChildren: ->
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # ===== Phase 3b (Slice 1): re-fit on the _reLayout cycle =====
  # A viewport re-fits its contents+scrollbars during recalculateLayouts (deferred),
  # not only via the inline _reLayoutChildren triggers. super (Widget::_reLayout) applies
  # MY OWN new bounds FIRST -- consuming @desired* and, on a real resize, re-fitting via the
  # _applyExtent override -- and THEN we re-fit to the (now-applied) viewport. Establishing
  # own bounds before re-fitting the contents is the DETERMINISM.md case-3c discipline (a
  # custom _reLayout must apply its own bounds before laying out what it contains). On a pure
  # resize the re-fit here is redundant with the _applyExtent override and idempotent; on a
  # content-only change (Phase 3b Slice 2, when the inline triggers become _invalidateLayout)
  # it is the one that runs.
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()

  # implementsDeferredLayout is `@_reLayout != Widget::_reLayout`, so the _reLayout above would
  # otherwise flip it true and change TWO read sites: (A) _setWidthSizeHeightAccordingly
  # (invalidate-on-resize) and, the load-bearing one, (B) subWidgetsMergedFullBounds -- a
  # deferred-layout child contributes only its viewport rect, not its scrolled subtree, which would
  # shrink a NESTED viewport's reported content size and regress nested-scroll (the proven 16->18
  # Path-A trap). We pin it PERMANENTLY to false, re-examined and reconfirmed through the sizing-model
  # unification arc (U3/U4): do not un-pin without a driving defect. See
  # docs/archive/sizing-model-unification-plan.md.
  implementsDeferredLayout: ->
    false

  _reLayoutChildrenAndScrollbars: ->
    @_reLayoutChildren()

  # A contained panel (e.g. a vertical stack acting as my @contents) tells me
  # its set of children changed, so I re-fit. I return true so the panel knows I
  # took over its re-layout (my _positionAndResizeChildren already re-lays my contents
  # out) and needn't do its own. This is the polymorphic replacement for
  # VerticalStackPanelWdgt testing `@amIPanelOfScrollPanelWdgt()`: the
  # stack just notifies its parent, and only a viewport reacts. NB kept
  # SEPARATE from _reLayoutChildrenAndScrollbars / _reactToChildDropped / _reactToChildGrabbed on
  # purpose -- a ListWdgt opts OUT of THIS notification (see ListWdgt) yet still
  # re-fits on its own drops/grabs/attaches.
  _reLayOutAfterContainedPanelChange: ->
    @_reLayoutChildrenAndScrollbars()
    return true

  _positionAndResizeChildren: ->

    # if the viewport has isTextLineWrapping set, it means that you don't want the text widget
    # to extend indefinitely as you are typing. Rather, the width will be constrained and the
    # text will wrap.
    padding = Math.floor @extraPadding + @padding
    totalPadding = 2*padding

    # The scrolled-content CONTRACT (scroll-frame role plan P5): the plane DECLARES its sizing
    # relationship to me — width ownership, interior-arrange delegation, the measure — and I
    # read declarations here instead of testing its class.
    if @contents.arrangesOwnScrolledChildren?()
      # (schedule-valve V1) a WIDTH-CONSTRAINING stack's width is MY contract (it tracks the
      # viewport; macroWindowCellsInConstrainedScrollStackReflow regressed without this), its
      # height falls out of the merge-commit below. A FREE-width stack OWNS its width -- the
      # whole point of the horizontal scrollbar -- so normalizing it would valve-schedule a
      # re-grow every arrange and ping-pong onto the end-of-cycle flush (the capstone gate
      # caught exactly that on macroFreeWidthScrollStackShowsHorizontalScrollbar). Width-only:
      # nothing between here and the commit reads the stack's height.
      if @contents.viewportConstrainsMyWidth?() and @contents.width() != @width()
        @contents._applyWidth @width()
      # arrange the content stack's children; I OWN its frame regardless (I size it from the §4.1 pure
      # measure -- subBounds -> the frame commit below), and the stack's terminal self-resize notifies nobody
      # (the notify-by-mutation seam is deleted).
      @contents._positionAndResizeChildren()
    else if @isTextLineWrapping
      # (schedule-valve V1) wrap width derives from MY viewport, not @contents.width(): the two are
      # equal at the fixpoint (the merge-commit below pins contents width to mine for wrap viewports),
      # but mid-transient — my frame just resized, contents not yet re-committed — only @width() is
      # current. The re-wrap itself is the plane's (?.-dispatched; only a default plane defines it).
      @contents._reWrapTextChildrenTo? @width() - totalPadding

    # §4.1 Stage C (proper-layouts): a content-sizing viewport (text-wrapping / vertical-stack / plain-text)
    # derives its content frame from a PURE measure of @contents's children (subWidgetsMergedPreferredBounds)
    # rather than mutating them and reading their merged APPLIED bounds back. This breaks the frame-sizing's
    # dependency on the children having been resized first -- the mutate-then-read-back the re-fit seam exists
    # for (assessment §2.4) -- yet is byte-identical (measured extent == applied at the fixed point; Stage-C
    # probe 0/1429 converged mismatches). The stack measures at its own width (it subtracts its own padding);
    # a bare text panel measures its children at the scroll-padding-inset width (== the _applyWidth re-wrap
    # above). The else-branch (folder / toolbar) is NOT a content-sizing target and keeps the applied read-back.
    # The MEASURE is the plane's own declaration (scrolledContentMeasure — a stack measures at
    # its own width, a plain plane at the hint; the P5 contract), the width hint is mine.
    isContentSizing = @isContentSizing()
    if isContentSizing
      # (schedule-valve V1) same viewport-derived width hint as the re-wrap above — see that comment.
      subBounds = (@contents.scrolledContentMeasure? @width() - totalPadding)?.ceil()
    else
      # (D4, U3-A) the ONE named state-read: user-placed free-floating children's positions
      # are state, and nothing above mutated them -- see subWidgetsMergedFullBounds's comment.
      subBounds = @contents.subWidgetsMergedFullBounds()?.ceil()
    if subBounds

      # add-in the content's own external padding
      if @contents.externalPadding?
        subBounds = subBounds.expandBy @contents.externalPadding

      # For a content-sizing stack/text panel: never stretch the view past the end of @contents (e.g.
      # after deleting text while scrolled to the bottom -- we don't want to reveal vacant space, we
      # want to shrink up and keep the bottom in view). So size first to the components' minimum area,
      # then grow only enough to fill the viewport.
      if isContentSizing
        newBounds = subBounds.expandBy(padding).ceil()

        # A plane whose measure IS its whole frame (a tight both-axes hug — CommandPanelWdgt,
        # the P5 contract's scrolledContentMeasureIsMyFrame declaration) gets the measure
        # committed VERBATIM: the width floor and grow-to-fill below suit a tight:false plane,
        # and against a tight hug they manufacture a two-writer fight whenever the viewport is
        # transiently larger than the hug (measured in the menu-sandwich dissolution's Phase 0:
        # menu-compose and duplication livelocks).
        unless @contents.scrolledContentMeasureIsMyFrame?()
          # Anchor to the frame's own left/top even when subBounds starts elsewhere (e.g. a single
          # centered icon) -- otherwise merging bounds that start off-origin would shift the panel so
          # the icon's left aligns with the frame's left, un-centering it. The merge rect spans my
          # full width but only 1px of height, so it also guarantees newBounds.width() >= @width() --
          # only the height may still fall short of the viewport:
          newBounds = newBounds.merge new Rectangle @contents.left(), @contents.top(), @contents.left() + @width(), @contents.top() + 1

          if newBounds.height() < @height()
            newBounds = newBounds.growBy new Point 0, @height() - newBounds.height()
      else
        # the frame must cover at least the visible WINDOW, expressed in the frame's plane
        # (frame origin + offset — identical to my own box when unscrolled with the frame
        # at my origin, which is the common resting state). A frame extending above/left of
        # my origin is a designed state (the D2 island-overhang scroll-reachability), which
        # is why the offset is measured from the FRAME origin rather than mine.
        windowInPlane = new Rectangle @contents.left() + @scrollOffsetX, @contents.top() + @scrollOffsetY,
          @contents.left() + @scrollOffsetX + @width(), @contents.top() + @scrollOffsetY + @height()
        newBounds = subBounds.expandBy(padding).merge windowInPlane.ceil()
    else
      newBounds = @boundingBox()?.ceil()

    unless @contents.boundingBox().equals newBounds
      # frame-origin bookkeeping (paint-time scroll): the window's plane position is
      # frame origin + offset, so a commit that MOVES the frame's origin (content grew
      # above/left of it, or shrank away from the top) must slide the offset by the same
      # amount to keep the VISIBLE window put — the moved-plane model got this for free.
      # A resulting negative offset is the _keepScrollOffsetInBounds clamp's business (below).
      originShift = @contents.position().subtract newBounds.origin
      @_writeScrollOffset @scrollOffsetX + originShift.x, @scrollOffsetY + originShift.y
      # §4.2 Stage 3 (structural arrange): I OWN my content's frame -- I computed newBounds from the §4.1 pure
      # measure (subBounds), so apply it via the NON-notifying twin. The old _commitBounds fired the re-fit
      # seam back at ME (Intent-2 self-re-enqueue = the capstone's Pattern D), redundant since I am the one sizing
      # the content; the seam only delivered a confirm pass that the §4.1 measure already makes a no-op.
      @contents._commitBounds newBounds
      @contents._reLayoutSelf()
      # (schedule-valve V1; gate made STRUCTURAL by §9-N4, docs/archive/ordered-downwalk-stage-b-plan.md)
      # a contents WITH ITS OWN ARRANGE places its children in its _reLayout (ToolPanelWdgt wraps its
      # buttons); committing its new frame via the non-notifying twin re-fits only its SELF layer, so
      # schedule its full re-lay through the phase-valve -- in-pass the same flush's next round heals
      # it, off-pass the wrapping settle does. The engine heals the interior; this arrange never
      # re-lays it synchronously. (Also covers the FrameWdgt early-settle route, where the later
      # engine re-visit sees no frame delta for the injection to act on.) The gate is
      # implementsDeferredLayout, NOT children.length: a base-_reLayout contents (the plain PanelWdgt
      # of every ordinary viewport) gets nothing from a full re-lay beyond the _reLayoutSelf
      # above, and this arrange is ALSO reached off-settle by the sanctioned synchronous
      # content-change endpoints (public add/addMany -> _reLayoutChildren) and the drag-to-scroll
      # step -- a children.length gate made every such call push the contents onto the end-of-cycle
      # flush (34 careless pushes across 10 scroll tests, plan §11).
      if @contents.implementsDeferredLayout()
        @contents._scheduleRelayoutRespectingPhase()

    # Always run this check even when @contents.boundingBox() already equals newBounds: a stack can
    # resize itself in the foreach loop above without changing the outer frame, so the view can still
    # need fixing. Cheap to check when there's nothing to do.
    @_keepScrollOffsetInBounds()

  # THE offset write funnel (paint-time scroll): every `@scrollOffsetX/Y` change in the class
  # routes through here. The offset is MAPPING state — part of the screen↔plane translation the
  # version-keyed derived-geometry caches (clipThrough / clippedThroughBounds / fullClippedBounds)
  # fold in — so a change must break them exactly as a bounds write does (__breakMoveResizeCaches).
  # Paint needs no such break (it reads the offset live), but HIT-TESTING reads those caches:
  # a scrolled row whose stale clip box is EMPTY paints perfectly and is hit-INVISIBLE — clicks
  # fall through to the viewport (measured on the inspector list, plan §3.2). Never write the
  # fields bare and rely on a neighboring bounds commit to bump the version: whether one happens
  # is accidental (a 1-px scroll may not move the quantized thumb; the clamp fires on unchanged
  # frames too). Returns whether the offset actually moved — the cores' caller contract.
  _writeScrollOffset: (newX, newY) ->
    return false if newX is @scrollOffsetX and newY is @scrollOffsetY
    @scrollOffsetX = newX
    @scrollOffsetY = newY
    WorldWdgt.geometryVersion++
    @_changed()
    true

  # §4.2 Stage 3 (structural arrange): the SCROLL CLAMP keeping the visible window inside the
  # content frame — the offset stays in [0, max(0, content − window)] per axis, so a shrink
  # at the bottom scrolls back up (no vacant space revealed) and fitting content rests at 0.
  # The plane itself never moves; only the offset clamps. Callers pair with
  # _reLayoutScrollbars as every scroll path does.
  _keepScrollOffsetInBounds: ->
    newX = Math.min (Math.max 0, @scrollOffsetX), (Math.max 0, @contents.width() - @width())
    newY = Math.min (Math.max 0, @scrollOffsetY), (Math.max 0, @contents.height() - @height())
    @_writeScrollOffset newX, newY

  # ViewportWdgt scrolling by floatDragging:
  scrollX: (steps) ->
    # under 'never' every scroll path refuses HERE, at the movement core: the
    # pin setters, scrollTo/scrollToBottom, the edge auto-scroll and the
    # momentum glide all route through this pair, and callers read the boolean
    # as "did the content actually move".
    return false if @scrollPolicy is 'never'
    # positive steps scroll the view back toward the content origin (the historical
    # "move the contents right" direction); the offset moves opposite the steps.
    # Math.round at the write funnel: the offset is INTEGER by contract (plan §4.3 —
    # fractional offsets are the fracplane bug class), and glide deltas arrive decayed.
    newX = Math.round @scrollOffsetX - steps
    newX = Math.min (Math.max 0, newX), (Math.max 0, @contents.width() - @width())
    # Return true iff the view actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
    @_writeScrollOffset newX, @scrollOffsetY

  # Scroll so CONTENT-point `whereTo` sits at my top-left. FRAME-RELATIVE (offset from my own
  # origin), so the result is independent of where I am in the world -- a caller's scroll survives
  # my being moved/resized (e.g. the sample-slide edit->view container shift). Not `-whereTo.x/.y`
  # (absolute world coords): those only land right for a frame at the world origin -- the root
  # of a real mis-scrolled-slide bug. SampleSlideApp is the sole caller.
  #
  # CLAMPED like every other scroll path: the request is expressed as deltas and routed through
  # scrollX/scrollY, so a target past the content's edge stops AT the edge -- a raw move here let a
  # too-far request commit an over-scrolled state no gesture can produce, with the contents frame
  # no longer covering the viewport (the arrange's own fit rule). After a real scroll, re-fit
  # contents + scrollbars, the standard post-scroll pair.
  scrollTo: (whereTo) ->
    scrolledX = @scrollX @scrollOffsetX - whereTo.x
    scrolledY = @scrollY @scrollOffsetY - whereTo.y
    if scrolledX or scrolledY
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()


  scrollToBottom: ->
    if @scrollY -100000
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      # — the same moved-gated post-scroll arrange every other scroll path runs (scrollTo, the
      # pin setters, the drag step); the non-content-sizing arrange folds the offset into its
      # window merge, so it must re-run after a real scroll
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()
  
  scrollY: (steps) ->
    # 'never' refuses at the core — see scrollX (which also explains the sign and the
    # integer-offset rounding).
    return false if @scrollPolicy is 'never'
    newY = Math.round @scrollOffsetY - steps
    newY = Math.min (Math.max 0, newY), (Math.max 0, @contents.height() - @height())
    # Return true iff the view actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
    @_writeScrollOffset @scrollOffsetX, newY

  # A drag-scroll step handed OUTWARD by a pane inside me that is already at its edge: the drag twin
  # of the wheel's at-edge escalation, reached by the same parent climb (escalateEvent). I take it as
  # my own step and hand on whatever I cannot absorb either, so a stack of nested panes passes the
  # leftover outward one level at a time. Scrolling from here is not inside anyone's step function,
  # so it settles its own content and bars, exactly as scrollTo does.
  scrollByDragDelta: (deltaX, deltaY) ->
    scrolledX = deltaX isnt 0 and @scrollX deltaX
    scrolledY = deltaY isnt 0 and @scrollY deltaY
    leftoverX = if scrolledX then 0 else deltaX
    leftoverY = if scrolledY then 0 else deltaY
    if leftoverX isnt 0 or leftoverY isnt 0
      @escalateEvent 'scrollByDragDelta', leftoverX, leftoverY
    if scrolledX or scrolledY
      # layout-apply-sanctioned: scroll-input (drag-scroll escalation), determinism-exempt
      # (residuals-audit fam 1) — the same moved-gated post-scroll arrange every other scroll
      # path runs
      @_positionAndResizeChildren()
      @_reLayoutScrollbars()
  
  # Float-dragging a Viewport's contents scrolls it (particularly useful on touch devices); the same
  # gesture works with the mouse when dragging over content that isn't itself draggable (e.g. text in a
  # viewport anchored to a non-draggable background, such as a color palette).
  mouseDownLeft: (pos) ->

    # a 'never' viewport takes no scroll gestures at all — fall through to the
    # normal grab/detach recognition instead of installing a dead step
    return undefined  if @scrollPolicy is 'never'
    return undefined  unless @isScrollingByfloatDragging

    # ⚠ Do NOT seed oldPos from the `pos` parameter: a press on my scrolled CONTENT dispatches
    # to the row (base Widget.mouseDownLeft) which ESCALATES here with the pos still in the
    # ROW'S plane — offset-pixels away from mine (paint-time scroll; pre-offset-model the two
    # planes coincided, so the escalated value was right by coincidence). The step's per-frame
    # samples below are in MY plane, and one cross-plane oldPos makes the first frame's delta
    # equal the whole offset — the drag slams to the clamp on a stationary click (measured).
    # Re-derive the press point from the hand with the same mapped read the step uses.
    oldPos = @screenPointToMyPlane world.hand.position()
    deltaX = 0
    deltaY = 0
    friction = 0.8
    wasScrollDragging = false
    # Did ANY frame of this gesture see a float-drag in progress? A float-drag means
    # the gesture is MOVING a (detachable) widget, not scrolling, so it must never get
    # a parting scroll — even if its frames collapse (see the flush's collapse branch).
    everFloatDragged = false
    world.steppingWdgts.add @
    @step = =>
      scrollbarJustChanged = false
      everFloatDragged ||= world.hand.isThisPointerFloatDraggingSomething()
      if world.hand.mouseButton and
        !world.hand.isThisPointerFloatDraggingSomething() and
        # a float-draggable widget under the hand is probably about to be detached, so hold steady
        # instead of scrolling -- scrolling now would give the wrong cue right before the float-drag
        # threshold is reached. A FINGER whose stroke does not mean a mouse drag is the other way
        # round (ruling I2): over my content a plain finger drag is a scroll whatever it is over, and
        # the thing under it lifts only once a hold has armed the stroke. A mouse or pen stroke
        # always means a mouse drag, so for them this reads exactly as the detach test alone.
        (!world.hand.wdgtToGrab?.detachesWhenDragged() or !world.hand.strokeMeansMouseDrag()) and
        # per-frame samples of the hand are SCREEN-plane; map each into MY plane at the read
        # site (the raw-pointer lint enforces exactly this shape), so the containment gate
        # compares like planes and the deltas below are in-plane — a tilted viewport drag-scrolls
        # along its own axes. Off any island the mapping returns the same point (dormant
        # byte-identical). The press point (oldPos) is seeded by the SAME mapped read above.
        @boundsContainPoint(@screenPointToMyPlane world.hand.position())
          wasScrollDragging = true
          newPos = @screenPointToMyPlane world.hand.position()
          if @hBar.visibleBasedOnIsVisibleProperty() and
          !@hBar.isInCollapsedSubtree()
            deltaX = newPos.x - oldPos.x
            if deltaX isnt 0
              # AT-EDGE ESCALATION, the wheel's rule one gesture over: a step this pane cannot
              # absorb belongs to whatever scroller encloses it, so a drag inside an exhausted inner
              # pane keeps moving the outer one instead of dying at the inner clamp. scrollX answers
              # "did the view actually move", which IS the at-edge test — no second derivation of
              # the clamp. With no enclosing scroller the climb finds nobody and nothing happens.
              scrolled = @scrollX deltaX
              scrollbarJustChanged ||= scrolled
              @escalateEvent 'scrollByDragDelta', deltaX, 0  unless scrolled
          if @vBar.visibleBasedOnIsVisibleProperty() and
          !@vBar.isInCollapsedSubtree()
            deltaY = newPos.y - oldPos.y
            if deltaY isnt 0
              scrolled = @scrollY deltaY
              scrollbarJustChanged ||= scrolled
              @escalateEvent 'scrollByDragDelta', 0, deltaY  unless scrolled
          oldPos = newPos
      else
        # final FLUSH: this step samples the hand once per FRAME, so the tail
        # of the pointer's path that arrived in the same frame as the
        # mouse-up was never scrolled — without this the scroll total
        # truncates at the last pre-release frame sample, a frame-cadence
        # artifact. Scrolling the leftover here makes the total exactly
        # release-point minus press-point — event-determined, identical
        # across engines — and the leftover doubles as the glide's seed
        # velocity. Only when this drag actually scroll-dragged (a float-move
        # of the viewport must not get a parting scroll), and only if released
        # inside the viewport (matching the per-frame gate above).
        #
        # CADENCE COLLAPSE: under the harness's pacing control (or just a slow / HiDPI
        # frame) the whole press->drag->release can drain inside ONE cycle, so the FIRST
        # @step already sees the button up and NO button-down frame ever set
        # wasScrollDragging. That used to drop the scroll ENTIRELY (total -> 0), making
        # the outcome depend on frame cadence — it scrolled at dpr 1 but not at dpr 2,
        # the same gesture giving different pixels. Recover it here: when the gesture
        # never float-dragged anything and the hand isn't poised to detach a widget
        # (so it IS a scroll-drag, not a float-move) and the press is inside the viewport,
        # treat it as a scroll-drag. oldPos is still the press point, so the flush below
        # scrolls exactly release-minus-press — the SAME event-determined total the
        # multi-frame path lands on, now identical at every dpr / speed / engine.
        collapsedScrollDrag = !wasScrollDragging and
          !everFloatDragged and
          (!world.hand.wdgtToGrab?.detachesWhenDragged() or !world.hand.strokeMeansMouseDrag()) and
          @boundsContainPoint(oldPos)
        if wasScrollDragging or collapsedScrollDrag
          wasScrollDragging = false
          # plane-mapped like the per-frame samples above — the flush's release-minus-press
          # total must be computed between points of the SAME plane
          releasePos = @screenPointToMyPlane world.hand.position()
          if @boundsContainPoint releasePos
            if @hBar.visibleBasedOnIsVisibleProperty() and
            !@hBar.isInCollapsedSubtree()
              deltaX = releasePos.x - oldPos.x
              if deltaX isnt 0
                # at-edge escalation, as in the per-frame arm above
                scrolled = @scrollX deltaX
                scrollbarJustChanged ||= scrolled
                @escalateEvent 'scrollByDragDelta', deltaX, 0  unless scrolled
            if @vBar.visibleBasedOnIsVisibleProperty() and
            !@vBar.isInCollapsedSubtree()
              deltaY = releasePos.y - oldPos.y
              if deltaY isnt 0
                scrolled = @scrollY deltaY
                scrollbarJustChanged ||= scrolled
                @escalateEvent 'scrollByDragDelta', 0, deltaY  unless scrolled
            oldPos = releasePos
        # POST-RELEASE MOMENTUM (the glide): keep scrolling by the last
        # frame's hand delta, decayed by friction each frame, until it fades.
        # Both that last delta and the glide length are FRAME-CADENCE driven
        # (how many queued events played back in the final frame), so under
        # the test harness's animations pacing control the glide is
        # SUPPRESSED outright — the content stops exactly at the event-
        # determined release offset and screenshots are reproducible across
        # engines. While a glide IS running (normal interactive use) it is
        # tracked in world.wdgtsWithOngoingScrollMomentum so the macro pump
        # can hold until it settles (the font-atlas-wait idea).
        glideSuppressed = Automator? and
          Automator.animationsPacingControl and
          Automator.state != Automator.IDLE
        if !@hasVelocity or glideSuppressed or
        ((Math.abs(deltaX) < 0.5) and (Math.abs(deltaY) < 0.5))
          @step = noOperation
          world.steppingWdgts.delete @
          world.wdgtsWithOngoingScrollMomentum.delete @
        else
          world.wdgtsWithOngoingScrollMomentum.add @
          if @hBar.visibleBasedOnIsVisibleProperty() and
          !@hBar.isInCollapsedSubtree()
            deltaX = deltaX * friction
            if deltaX isnt 0
              scrollbarJustChanged ||= @scrollX Math.round deltaX
          if @vBar.visibleBasedOnIsVisibleProperty() and
          !@vBar.isInCollapsedSubtree()
            deltaY = deltaY * friction
            if deltaY isnt 0
              scrollbarJustChanged ||= @scrollY Math.round deltaY
      if scrollbarJustChanged
        # layout-apply-sanctioned: scroll-input (momentum glide), determinism-exempt (residuals-audit fam 1)
        @_positionAndResizeChildren()
        @_reLayoutScrollbars()
    super
  
  # During a float-drag, if I want the dragged widget and the pointer is in my edge band, I
  # auto-scroll. ActivePointerWdgt calls this instead of testing `newWdgt instanceof
  # ViewportWdgt` and driving the wantsDropOfChild / edge / startAutoScrolling logic itself.
  # (type-test-elimination campaign)
  maybeStartAutoScrollForDraggedWidget: (widgetBeingFloatDragged, pointerPosition) ->
    # a 'never' viewport accepts the drop but does not creep toward it
    return if @scrollPolicy is 'never'
    if @wantsDropOfChild widgetBeingFloatDragged
      # the caller hands the hand's SCREEN position; my box is plane-local (I can myself be a
      # resident of a scrolled pane / island), so map the pointer into MY plane for the band
      # test — the identity (same object) for an un-nested viewport
      if !@boundingBox().insetBy(WorldWdgt.preferencesAndSettings.scrollBarsThickness * 3).containsPoint @screenPointToMyPlane pointerPosition
        @startAutoScrolling()

  startAutoScrolling: ->
    # The edge auto-scroll is wall-clock driven (the Date.now() settle below
    # plus per-frame increments), but unlike the momentum glide in
    # mouseDownLeft it is NOT suppressed under the test harness's pacing
    # control: it is a load-bearing interaction with its own SystemTest
    # (macroListWdgtAutoScrollsNearDraggedEdge). Its determinism contract is
    # SATURATION instead — a macro holds the drag in the edge band long
    # enough that the scroll CLAMPS, so the screenshotted endpoint is
    # frame-cadence-independent even though the path there isn't (see the
    # edge-auto-scroll entry in src/macros/MACRO-PATTERNS.md).
    inset = WorldWdgt.preferencesAndSettings.scrollBarsThickness * 3
    if @isOrphan() then return undefined
    hand = world.hand
    @autoScrollTrigger = Date.now()  unless @autoScrollTrigger
    world.steppingWdgts.add @
    @step = =>
      # mapped like every per-frame hand sample (identity for an un-nested viewport) — the
      # band test and autoScroll's delta arithmetic below both run in MY plane
      pos = @screenPointToMyPlane hand.position()
      inner = @boundingBox().insetBy inset
      if @boundsContainPoint(pos) and
        !inner.containsPoint(pos) and
        hand.isThisPointerFloatDraggingSomething()
          @autoScroll pos
      else
        @step = noOperation
        world.steppingWdgts.delete @
        @autoScrollTrigger = undefined
  
  autoScroll: (pos) ->
    return undefined  if Date.now() - @autoScrollTrigger < 500
    inset = WorldWdgt.preferencesAndSettings.scrollBarsThickness * 3
    area = @topLeft().extent new Point @width(), inset
    scrollbarJustChanged = false
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollY inset - (pos.y - @top())
    area = @topLeft().extent new Point inset, @height()
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollX inset - (pos.x - @left())
    area = (new Point(@right() - inset, @top())).extent new Point inset, @height()
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollX -(inset - (@right() - pos.x))
    area = (new Point(@left(), @bottom() - inset)).extent new Point @width(), inset
    if area.containsPoint(pos)
      scrollbarJustChanged ||= @scrollY -(inset - (@bottom() - pos.y))
    if scrollbarJustChanged
      # layout-apply-sanctioned: scroll-input (edge auto-scroll), determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
      @_reLayoutScrollbars()
  
  # ViewportWdgt scrolling when editing text
  # so to bring the caret fully into view.
  # The caret is a resident of my PLANE (its parent is my contents), so its coordinates are
  # plane-local and never move on a scroll; bringing it into view means moving the OFFSET
  # until the caret's plane position falls inside the visible window's plane rect. The full
  # delta lands in ONE core call per axis (the single-pass law: CaretWdgt places itself at
  # its true, un-clamped slot position before asking), and the caret itself is never moved —
  # its screen appearance follows through the paint-time translation.
  scrollCaretIntoView: (caretWidget) ->
    # a 'never' viewport clips its caret like any other overflow — WYSIWYG of the
    # policy (a text viewport that wants the caret in view wants 'auto')
    return if @scrollPolicy is 'never'
    # layout-apply-sanctioned: scroll-input (caret-into-view), determinism-exempt (residuals-audit fam 1)
    @_positionAndResizeChildren()
    # the visible window's padded interior, expressed in the caret's plane
    # (frame origin + offset)
    ft = @contents.top() + @scrollOffsetY + @padding
    fb = @contents.top() + @scrollOffsetY + @height() - @padding
    fl = @contents.left() + @scrollOffsetX + @padding
    fr = @contents.left() + @scrollOffsetX + @width() - @padding
    marginAroundCaret = @padding
    if @extraPadding?
      marginAroundCaret += @extraPadding
    # DIRECT, deliberately UN-clamped offset writes (the follow's one licence — the movement
    # cores clamp to the content frame, but a caret at the very end of the content needs the
    # window to overshoot by its margin): the arrange below then GROWS the frame to cover the
    # overshot window (the window-in-plane merge) and its bookkeeping+clamp normalize the
    # offset against the grown frame, so the overshoot STICKS exactly as far as the margin —
    # the same fixpoint the moved-plane follow reached by moving the plane un-clamped.
    if caretWidget.top() < ft
      @_writeScrollOffset @scrollOffsetX, (Math.round @scrollOffsetY - (ft - caretWidget.top() + marginAroundCaret))
    else if caretWidget.bottom() > fb
      @_writeScrollOffset @scrollOffsetX, (Math.round @scrollOffsetY + (caretWidget.bottom() - fb + marginAroundCaret))
    if caretWidget.left() < fl
      @_writeScrollOffset (Math.round @scrollOffsetX - (fl - caretWidget.left() + marginAroundCaret)), @scrollOffsetY
    else if caretWidget.right() > fr
      @_writeScrollOffset (Math.round @scrollOffsetX + (caretWidget.right() - fr + marginAroundCaret)), @scrollOffsetY
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # ViewportWdgt events.
  wheel: (xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg) ->

    x = xArg
    y = yArg

    # if we don't destroy the resizing handles,
    # they'll follow the contents being moved!
    world.hand.destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem @

    scrollbarJustChanged = false

    # squelch the minor axis + apply the invert preferences
    [x, y] = WorldWdgt.preferencesAndSettings.normalizedWheelDeltas x, y

    if y != 0
      # Escalate the scroll in case we are in a nested
      # Viewport situation and we already
      # scrolled this inner one "up/down to the end".
      # In such case, the outer one has to scroll...
      #
      # if scrolling up and the content top is already at (or below) the top
      #  OR
      # if scrolling down and the content bottom is already at (or above) the bottom
      #  THEN
      # escalate the method up, since there might be another scrollbar catching it.
      # Exact comparisons: the offset is integer by contract (the movement cores round at
      # the write funnel), and a tolerance here would hand a 1px-shy inner viewport's last
      # wheel step to the outer viewport instead of letting the inner one reach its edge.
      # 'never' escalates HERE, not at the refused core — the else arm would
      # otherwise mark scrollbarJustChanged and swallow the wheel dead over a
      # cropping viewport instead of handing it to an enclosing scroller.
      # at-top ⇔ offset 0; at-end ⇔ offset at the clamp limit (fitting content is both).
      if @scrollPolicy is 'never' or
       (y > 0 and @scrollOffsetY <= 0) or
       (y < 0 and @scrollOffsetY >= @contents.height() - @height())
        @escalateEvent 'wheel', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @scrollY y * WorldWdgt.preferencesAndSettings.wheelScaleY
    if x != 0
      # similar to the vertical case, escalate the scroll in case
      # we are in a nested Viewport situation ('never' escalates too — see
      # the vertical case)
      if @scrollPolicy is 'never' or
       (x > 0 and @scrollOffsetX <= 0) or
       (x < 0 and @scrollOffsetX >= @contents.width() - @width())
        @escalateEvent 'wheel', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @scrollX x * WorldWdgt.preferencesAndSettings.wheelScaleX

    if scrollbarJustChanged
      # layout-apply-sanctioned: scroll-input (wheel), determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
      @_reLayoutScrollbars()
  

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    if @takesOverAndMergesChildrensMenus
      if @contents
        childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets @contents
      if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length == 1
        childrenNotHandlesNorCarets[0].addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu
    else
      super
      if @offersScrollPolicyToggle
        if @scrollPolicy is 'never'
          menu.addMenuItem "allow scrolling", @, "toggleScrollPolicyFromMenu", toolTip: "let the contents scroll\nwhen they overflow"
        else
          menu.addMenuItem "don't scroll (crop)", @, "toggleScrollPolicyFromMenu", toolTip: "crop the contents at my\nedges instead of scrolling"
  
  # Set this viewport's text-line-wrapping state; turning wrapping ON fills
  # the content to the viewport's bounds. (Called by SimpleTextWdgt's soft-wrap
  # toggle, which used to write this flag + resize the content from outside.)
  #
  # The resize here is DELIBERATELY IMMEDIATE (raw geometry), not the framework's
  # ideal DEFERRED pattern (set a flag + _invalidateLayout(), let recalculateLayouts
  # -> _reLayout derive the geometry). This is INTERMEDIATE state, not an oversight:
  # the deferred mechanism is half-built by construction (the geometry accessors read
  # applied @bounds only, so handler-level raw geometry is a symptom of that
  # incompleteness, not a one-off). Soft-wrap has an EXTRA blocker on top: the content
  # panel + text are free-floating, so _invalidateLayout() on them does NOT
  # climb up to this viewport, and the wrap geometry lives in _positionAndResizeChildren
  # -- which the _reLayout cycle never reaches for a wrap toggle. Completing the
  # deferred model (and this case) is deliberate, sequenced work; see
  # docs/archive/softwrap-deferred-layout-conversion-plan.md for the model finding, the
  # obstacle map, and what a conversion would take.
  setTextLineWrapping: (wraps) ->
    @isTextLineWrapping = wraps
    if wraps
      @contents._applyBounds @position(), @extent()

  # ⚠ NO `triggeringWidget` parameter here — see the note on FrameWdgt's pair. It is read in exactly
  # one place tree-wide, BubblesEditModeToCoordinatorMixin's `@parent != triggeringWidget`, and that
  # mixin is the core of the two Stretchables, not of a viewport. (A subclass whose core IS the
  # mixin — VerticalStackViewportWdgt — still `super`s into this one; the argument it hands
  # over is simply ignored, which is the honest outcome for a value nothing here consults.)
  enableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle()

  _enableDragsDropsAndEditingNoSettle: ->
    if @dragsDropsAndEditingEnabled
      return
    @parent?.showEditModeInBar?()

    # public-call-sanctioned: enableDrops is the trivial public drop-acceptance setter
    # (macro/cross-object surface) — settle-free, consciously reused by this core.
    @enableDrops()
    @dragsDropsAndEditingEnabled = true

    @contents._enableDragsDropsAndEditingNoSettle @

  disableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle()

  _disableDragsDropsAndEditingNoSettle: ->
    if !@dragsDropsAndEditingEnabled
      return
    @parent?.showViewModeInBar?()

    # public-call-sanctioned: disableDrops — see the enableDrops note in the enable core above.
    @disableDrops()
    @dragsDropsAndEditingEnabled = false

    @contents._disableDragsDropsAndEditingNoSettle @
    # ELIMINATE (end-of-cycle-flush-drawdown): a disable-probe proved the deferred re-fit that used to
    # live here redundant -- disabling only changes appearance/drop-handling, and the cascade's
    # @contents._disableDragsDropsAndEditingNoSettle above already did the synchronous work. See
    # docs/archive/end-of-cycle-flush-inventory.md.

