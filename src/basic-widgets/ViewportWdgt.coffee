# The scrolling VIEWPORT — an invisible composite (alpha 0, never paints itself) owning three
# pieces of chrome: the contents panel (the PLANE its content lives on, physically moved by the
# scroll) and two SliderWdgt bars. NOT a PanelWdgt: a panel is a SURFACE whose children are
# content, while my children are chrome — my content lives one level down, on the plane — so
# the panel-family answers (its menu rows, its lock-granting, its drop slots) are wrong here,
# and the few panel facts I do mean are stated explicitly below (scroll-frame role plan P4).
class ViewportWdgt extends Widget

  # I clip my chrome (and through it the scrolled content) at my bounds — the same mixin
  # PanelWdgt wears, taken directly now (as FrameWdgt does). It also decides hit-testing
  # together with the RectangularAppearance the constructor sets: opaque inside my bounds,
  # even though alpha 0 means I never paint a pixel.
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  # the panel facts I genuinely mean, restated off PanelWdgt:
  # around-the-content padding a caller can add via setContents (reads: the arrange,
  # scrollCaretIntoView)
  extraPadding: 0
  # an EMPTY generic scroll frame accepts drops (wantsDropOfChild consults the contents' veto)
  _acceptsDrops: true
  # a scroll frame is an editing surface: FrameWdgt shows the pencil off its contents'
  # answer, and the edit-mode focus walk climbs to the first opinion
  providesAmenitiesForEditing: true

  autoScrollTrigger: undefined
  hasVelocity: true
  padding: 0 # around the scrollable area
  isTextLineWrapping: false
  isScrollingByfloatDragging: true

  # ── SCROLL POLICY ──────────────────────────────────────────────────────────
  # 'auto'  — scroll iff content overflows. Bars are not a mode, they are the
  #           visible CONSEQUENCE of overflow: a fitting frame already hides
  #           both bars and escalates every wheel, so it is behaviorally a
  #           plain panel with nothing to flip.
  # 'never' — behave as a plain cropping panel: every scroll path refuses at
  #           the movement cores (scrollX/scrollY), the bars never show, the
  #           wheel always escalates, and no scroll gesture engages. Contents
  #           sizing is DELIBERATELY unchanged — the contents panel still
  #           grows to its merged bounds and the overflow is clipped at my
  #           viewport, which IS plain-frame semantics.
  # Flipped live via setScrollPolicy (menu: toggleScrollPolicyFromMenu) with
  # no widget-tree change — policy over structure, the same verdict the
  # pop-ups reached for their unconditional rows frame
  # (PopUpWdgt._buildRowsViewportNoSettle).
  scrollPolicy: 'auto'

  # Only the GENERIC scrollable panel offers the crop⇄scroll flip in its menu:
  # the dedicated subclasses (list, toolbar, text, stack, pop-up rows) design
  # their scroll behavior in, so there the row would be menu rent plus a
  # footgun (cropping an inspector's list pane hides properties with no cue).
  # Each opts out with a one-line reason at its own declaration.
  offersScrollPolicyToggle: true
  scrollBarsThickness: undefined
  contents: undefined
  vBar: undefined
  hBar: undefined

  # Capability query: is aWdgt one of MY scrollbars? A SliderWdgt asks this of its parent to know whether
  # it is CHROME (a scrollbar → excluded from the editor-focus selection overlay) or content (a dropped
  # value control → framable). Only my actual bars match, so a content slider dropped into my content stays
  # framable. See SliderWdgt.excludedFromEditorFocusTracking.
  isMyScrollBar: (aWdgt) ->
    aWdgt is @vBar or aWdgt is @hBar

  # Role query, the plane-side twin of isMyScrollBar: is aWdgt the contents panel I clip and
  # scroll? THE one place the scroll-frame topology is stated — the chokepoints
  # (_amITheContentsPanelOfAViewport, _amIDirectlyInsideViewport, the hierarchy
  # menu) ask this rather than pattern-matching the composite's shape, so ANY class serving as
  # my plane (the default ScrolledPaneWdgt, a FolderPanelWdgt, a ToolPanelWdgt, a stack)
  # answers uniformly. (scroll-frame role plan P3; type-test-elimination ε.)
  isMyContentsPanel: (aWdgt) ->
    aWdgt is @contents

  # Do my plane's DIRECT children live there as LOOSE scrollable content — things a drag may
  # scroll-or-detach, a caret follows into view, a lone text child offers soft-wrap for, a
  # container re-fit climbs through? True for a generic scroll frame; a ListWdgt answers false —
  # its pane holds the list's own rows machinery, not loose content — which is the exclusion
  # `_amIDirectlyInsideViewport`'s consumers relied on as `!(instanceof ListWdgt)`.
  contentsPanelHoldsLooseContent: ->
    true

  # My contents panel is internal structure — hide it from the ancestor hierarchy
  # (disambiguation) menu. Asked by Widget.hierarchyMenuWidgets via ?(); replaces two of its
  # structural exclusions (plain-panel-in-scroll-frame, stack-in-stack-scroll-frame — the
  # stack IS its frame's contents). FolderWindowWdgt declares the third the same way.
  hidesContainedWidgetFromHierarchyMenu: (aWdgt) ->
    @isMyContentsPanel aWdgt

  # ── the plane's up-relays (scroll-frame role plan P3) ─────────────────────────────────────
  # My paint values MIMIC my contents' (I never paint — alpha 0 — but menus and readers see my
  # fields), and the plane keeps them true by notifying me when it is recolored directly. Bare
  # field writes: there is nothing of me to invalidate — I am never painted, and the plane's
  # own super covers every visible recoloured pixel. Guarded on a real value: Widget.setColor
  # returns undefined on a no-change call, and writing that through would clobber the mimic.
  _reactToChildColorChanged: (child, aColor) ->
    return unless child is @contents and aColor?
    return if @color?.equals aColor
    @color = aColor

  _reactToChildAlphaChanged: (child, alpha) ->
    return unless child is @contents and alpha?
    unless @alpha == alpha
      @alpha = alpha

  # there are several ways in which we allow
  # scrolling when a Viewport is scrollable
  # (i.e. the scrollbars are showing).
  # You can choose to scroll it by dragging the
  # contents or by dragging the background,
  # independently. Which could be useful for
  # example when showing a geographic map.
  canScrollByDraggingBackground: false
  canScrollByDraggingForeground: false

  constructor: (
    @contents,
    @scrollBarsThickness = (WorldWdgt.preferencesAndSettings.scrollBarsThickness),
    @sliderColor
    ) ->
    # alpha 0: I never paint myself — the plane and bars are the visible thing, and my own
    # values just MIMIC the plane's (see _buildViewportChromeNoSettle)
    @alpha = 0
    super()
    # the appearance is for HIT-TESTING parity, not painting (alpha 0): an appearance-bearing
    # widget answers opaque inside its tight bounds; the colors seed the mimic until
    # _buildViewportChromeNoSettle adopts the contents' own
    @appearance = new RectangularAppearance @
    @color = WorldWdgt.preferencesAndSettings.defaultPanelsBackgroundColor
    @strokeColor = WorldWdgt.preferencesAndSettings.defaultPanelsStrokeColor
    @_buildViewportChrome()

  # Build the scroll frame (contents + h/v scrollbars) via the NoSettle core, settling ONCE at the end
  # (orphan-settledness: `new ViewportWdgt` returns settled). The name is deliberately DISTINCT from the
  # leaf builder `_buildAndConnectChildren`: ViewportWdgt is a base whose subclass ListWdgt OVERRIDES
  # `_buildAndConnectChildren` to build its list CONTENTS, and CoffeeScript binds a subclass's constructor
  # params (@elements, …) only AFTER super(). If THIS base constructor called the (virtual)
  # `_buildAndConnectChildren`, `new ListWdgt` would dispatch into ListWdgt's contents-core during super()
  # with @elements still undefined → crash. So the base builds only the frame here (a name ListWdgt does not
  # override); ListWdgt's constructor builds its contents via `_buildAndConnectChildren` AFTER super().
  _buildViewportChrome: ->
    @_settleLayoutsAfter => @_buildViewportChromeNoSettle()

  _buildViewportChromeNoSettle: ->
    @contents = new ScrolledPaneWdgt() unless @contents?
    # _addNoSettle (NOT the self-settling public add): we are building our own innards
    # during construction; the panel is not parented yet, so a flush here would be a
    # redundant whole-world relayout (and would throw if we are built during a layout pass).
    @_addNoSettle @contents

    # the Viewport is never going to paint itself,
    # but its values are going to mimic the values of the
    # contained Panel
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
    # the CONTENTS vetoes raw drops into its frame (a folder's contents are managed by the
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

  getScrollX: -> @left() - @contents.left()

  getScrollY: -> @top() - @contents.top()

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
    if @scrollX (@left() - num) - @contents.left()
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()
    return num

  setScrollY: (num) ->
    num = parseFloat num  unless typeof num is "number"
    return  if isNaN num
    if @scrollY (@top() - num) - @contents.top()
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
  # so a flip on a live overflowing frame shows/hides its bars and re-clamps
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
    # Note that the container Viewport.
    # is actually not painted.
    @contents.setColor aColor
    return aColor

  setAlphaScaled: (alpha) ->
    alpha = super
    # update the alpha of the Viewport - note
    # that we are never going to paint the Viewport
    # we are updating the alpha so that its value is the same as the
    # contained Panel
    @contents.setAlphaScaled alpha
    return alpha

  anyScrollBarShowing: ->
    if (@hBar.visibleBasedOnIsVisibleProperty() and !@hBar.isInCollapsedSubtree()) or
    (@vBar.visibleBasedOnIsVisibleProperty() and !@vBar.isInCollapsedSubtree())
      return true
    return false

  # The width my @contents must lay itself out within: my viewport width. Asked via ?() by
  # content that wraps to its container (ToolPanelWdgt's row-wrap). Capability, was
  # `parent instanceof ViewportWdgt` at the caller (type-test-elimination ε).
  widthContentsMustFitWithin: ->
    @width()

  # Pressing a slider's TRACK jump-drags the button to the press point when the slider is
  # chrome its parent owns (my scrollbars) — SliderWdgt.mouseDownLeft asks its parent via ?().
  # PromptWdgt gives its input slider the same policy. Capability, was
  # `(parent instanceof ViewportWdgt) or (parent instanceof PromptWdgt)` (type-test-elimination ε).
  sliderTrackPressJumpsButton: ->
    true

  # (no childrenCanLockToMe here: my direct children are chrome, not user-lockable content, and
  # the lock-menu row keys on the capability EXISTING — see PanelWdgt.childrenCanLockToMe —
  # so a viewport simply not defining it is the opt-out)

  # Am I a content-sizing scroll frame — one whose content frame derives from a PURE measure
  # of @contents's children (§4.1 Stage C, see _positionAndResizeChildren)? The two dedicated
  # subclasses (SimpleTextViewportWdgt / SimpleVerticalStackViewportWdgt) always
  # are; a plain frame is when text-wrapping. Class-level query, was two self-instanceof
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
      # a 'never' panel shows no bars whatever the overflow — same hide arm the
      # fitting case takes
      if @scrollPolicy isnt 'never' and @contents.width() >= @width() + 1
        @hBar.show()
        # chrome I own and place -- apply via the non-notifying twin as above (see the method-top
        # comment). _applyExtentBase == _applyWidth/Height minus the seam; preserves height/width by
        # passing the current other axis.
        @hBar._applyExtentBase new Point(hWidth, @hBar.height())  if @hBar.width() isnt hWidth
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
        @vBar._applyExtentBase new Point(@vBar.width(), vHeight)  if @vBar.height() isnt vHeight
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

    # ── THE REVERSE EDGE (connector plan §P8) ────────────────────────────────────────────────
    # My scroll geometry just settled, so ANNOUNCE it and let whoever tracks me re-read it — instead
    # of pushing four numbers into the two bars I happen to hold fields for. Everything above this
    # line is still field business, and rightly: SHOWING, SIZING and PLACING the bars is chrome I own
    # and only my own two are mine to place. The four NUMBERS are not chrome, they are the state, and
    # any number of bars may want them — a duplicate, a bar someone unplugged onto the desktop, one
    # belonging to nobody. That is complaint ① closed.
    #   markNonValueChange, not markStale: my scroll offset is not my VALUE (I declare no principal
    # pin — a scroll frame has no one number), and this wakes only the edges that asked to re-read me,
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
  # end up in the Panel inside it.
  # This would also apply to resizing handles - so we need to
  # correct for that case
  add: (aWdgt, opts = {}) ->
    # annotation + handle both attach to the scroll frame directly (was their two instanceof)
    # (type-test-elimination campaign). Keyed off the WIDGET, not the layoutSpec argument:
    # handles are added with no explicit spec (defaultLayoutSpecWhenAddedTo resolves it inside
    # the add), so the argument is undefined exactly for the widgets this must catch.
    if aWdgt.attachesToViewportDirectly?()
      super
    else
      @contents.add aWdgt, opts
      # Intentional synchronous APPLY (not an off-settle trigger to defer): add / addMany /
      # showResizeAndMoveHandlesAndLayoutAdjusters are public content-change ENDPOINTS, idempotent
      # with this panel's own _reLayout ('super; @_reLayoutChildren'), distinct from the seam sites
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
  # this frame -- like add() -> @contents.add above), then SCHEDULE this frame's re-fit. The enclosing wrapper's
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

    aWdgt._applyMoveTo @position().add @padding + @extraPadding

    @add aWdgt


  # SCROLL-POSITION POLICY, not a child re-lay (schedule-valve V1): a REAL immediate resize of a
  # text-wrapping panel re-pins its contents to my origin (the shipped reset-scroll-on-resize
  # behaviour), while a re-lay at an unchanged frame must never touch the scroll position. The pin
  # lives AT the resize event because only the event knows the delta — a scheduled/settle re-lay
  # enters _reLayout with the extent already committed, so an extent-delta gate inside _reLayout
  # structurally cannot see an immediate resize. Pinning BEFORE super is safe (an extent commit
  # never changes my origin); the arrange that follows (via the resize re-lay) then anchors and
  # clamps off the pinned position. A plane that manages its own scroll pinning (a wrapping
  # STACK, whose position the arrange's clamp owns) declares itself out —
  # managesOwnScrollPinning, the P5 contract.
  _applyExtent: (aPoint) ->
    if !aPoint.equals(@extent()) and @isTextLineWrapping and !@contents.managesOwnScrollPinning?()
      @contents._applyMoveTo @position()
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
  # contained panel's notification). Inherited by ListWdgt and the other scroll
  # panels -- they all re-fit the same way (the ListWdgt opt-out below is ONLY
  # for the contained-panel notification, not for this pair).
  _reLayoutChildren: ->
    @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # ===== Phase 3b (Slice 1): re-fit on the _reLayout cycle =====
  # A scroll panel re-fits its contents+scrollbars during recalculateLayouts (deferred),
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
  # shrink a NESTED scroll panel's reported content size and regress nested-scroll (the proven 16->18
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
  # SimpleVerticalStackPanelWdgt testing `@amIPanelOfScrollPanelWdgt()`: the
  # stack just notifies its parent, and only a scroll panel reacts. NB kept
  # SEPARATE from _reLayoutChildrenAndScrollbars / _reactToChildDropped / _reactToChildGrabbed on
  # purpose -- a ListWdgt opts OUT of THIS notification (see ListWdgt) yet still
  # re-fits on its own drops/grabs/attaches.
  _reLayOutAfterContainedPanelChange: ->
    @_reLayoutChildrenAndScrollbars()
    return true

  _positionAndResizeChildren: ->

    # if PanelWdgt is of type isTextLineWrapping
    # it means that you don't want the text widget to
    # extend indefinitely as you are typing. Rather,
    # the width will be constrained and the text will
    # wrap.
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
      # equal at the fixpoint (the merge-commit below pins contents width to mine for wrap panels),
      # but mid-transient — my frame just resized, contents not yet re-committed — only @width() is
      # current. The re-wrap itself is the plane's (?.-dispatched; only a default plane defines it).
      @contents._reWrapTextChildrenTo? @width() - totalPadding

    # §4.1 Stage C (proper-layouts): a content-sizing scroll panel (text-wrapping / vertical-stack / plain-text)
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

        # Anchor to the viewport's own left/top even when subBounds starts elsewhere (e.g. a single
        # centered icon) -- otherwise merging bounds that start off-origin would shift the panel so
        # the icon's left aligns with the viewport's left, un-centering it. The merge rect spans my
        # full width but only 1px of height, so it also guarantees newBounds.width() >= @width() --
        # only the height may still fall short of the viewport:
        newBounds = newBounds.merge new Rectangle @contents.left(), @contents.top(), @contents.left() + @width(), @contents.top() + 1

        if newBounds.height() < @height()
          newBounds = newBounds.growBy new Point 0, @height() - newBounds.height()
      else
        newBounds = subBounds.expandBy(padding).merge @boundingBox()?.ceil()
    else
      newBounds = @boundingBox()?.ceil()

    unless @contents.boundingBox().equals newBounds
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
      # of every ordinary scroll panel) gets nothing from a full re-lay beyond the _reLayoutSelf
      # above, and this arrange is ALSO reached off-settle by the sanctioned synchronous
      # content-change endpoints (public add/addMany -> _reLayoutChildren) and the drag-to-scroll
      # step -- a children.length gate made every such call push the contents onto the end-of-cycle
      # flush (34 careless pushes across 10 scroll tests, plan §11).
      if @contents.implementsDeferredLayout()
        @contents._scheduleRelayoutRespectingPhase()

    # Always run this check even when @contents.boundingBox() already equals newBounds: a stack can
    # resize itself in the foreach loop above without changing the outer frame, so the view can still
    # need fixing. Cheap to check when there's nothing to do.
    @keepContentsInViewport()

  # §4.2 Stage 3 (structural arrange): the position clamp keeping my content snug against my viewport edges. I
  # OWN this position, so apply each nudge via the NON-notifying move twin -- the old _applyMoveBy fired the
  # re-fit seam back at ME (part of the scroll panel's Intent-2 self-re-enqueue), redundant since I am the clamper.
  keepContentsInViewport: ->
    if @contents.left() > @left()
      @contents._applyMoveByBase new Point @left() - @contents.left(), 0
    if @contents.right() < @right()
      @contents._applyMoveByBase new Point @right() - @contents.right(), 0
    if @contents.top() > @top()
      @contents._applyMoveByBase new Point 0, @top() - @contents.top()
    if @contents.bottom() < @bottom()
      @contents._applyMoveByBase new Point 0, @bottom() - @contents.bottom()
  
  # ViewportWdgt scrolling by floatDragging:
  scrollX: (steps) ->
    # under 'never' every scroll path refuses HERE, at the movement core: the
    # pin setters, scrollTo/scrollToBottom, the edge auto-scroll and the
    # momentum glide all route through this pair, and callers read the boolean
    # as "did the content actually move".
    return false if @scrollPolicy is 'never'
    cl = @contents.left()
    l = @left()
    cw = @contents.width()
    r = @right()
    newX = cl + steps
    newX = r - cw  if newX + cw < r
    newX = l  if newX > l
    # Return true iff the content actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
    if newX isnt cl
      @contents._moveLeftSideTo newX
      return true
    else
      return false

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
    scrolledX = @scrollX @left() - whereTo.x - @contents.left()
    scrolledY = @scrollY @top() - whereTo.y - @contents.top()
    if scrolledX or scrolledY
      # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()


  scrollToBottom: ->
    @scrollY -100000
    # layout-apply-sanctioned: scroll-input handler, determinism-exempt (residuals-audit fam 1)
    @_reLayoutScrollbars()
  
  scrollY: (steps) ->
    # 'never' refuses at the core — see scrollX.
    return false if @scrollPolicy is 'never'
    ct = @contents.top()
    t = @top()
    ch = @contents.height()
    b = @bottom()
    newY = ct + steps
    if newY + ch < b
      newY = b - ch
    # prevents content to be scrolled to the Panel's
    # bottom if the content is otherwise empty
    newY = t  if newY > t
    # Return true iff the content actually moved -- callers use this to decide whether to trigger the
    # content/scrollbar update.
    if newY isnt ct
      @contents._moveTopSideTo newY
      return true
    else
      return false
  
  # Float-dragging a Viewport's contents scrolls it (particularly useful on touch devices); the same
  # gesture works with the mouse when dragging over content that isn't itself draggable (e.g. text in a
  # scroll panel anchored to a non-draggable background, such as a color palette).
  mouseDownLeft: (pos) ->

    # a 'never' panel takes no scroll gestures at all — fall through to the
    # normal grab/detach recognition instead of installing a dead step
    return undefined  if @scrollPolicy is 'never'
    return undefined  unless @isScrollingByfloatDragging

    oldPos = pos
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
        # threshold is reached
        !world.hand.wdgtToGrab?.detachesWhenDragged() and
        # per-frame samples of the hand are SCREEN-plane; map each into MY plane at the read
        # site (the raw-pointer lint enforces exactly this shape), so the containment gate
        # compares like planes and the deltas below are in-plane — a tilted panel drag-scrolls
        # along its own axes. Off any island the mapping returns the same point (dormant
        # byte-identical). The press point (oldPos = the handler's `pos`) arrives pre-mapped.
        @boundsContainPoint(@screenPointToMyPlane world.hand.position())
          wasScrollDragging = true
          newPos = @screenPointToMyPlane world.hand.position()
          if @hBar.visibleBasedOnIsVisibleProperty() and
          !@hBar.isInCollapsedSubtree()
            deltaX = newPos.x - oldPos.x
            if deltaX isnt 0
              scrollbarJustChanged ||= @scrollX deltaX
          if @vBar.visibleBasedOnIsVisibleProperty() and
          !@vBar.isInCollapsedSubtree()
            deltaY = newPos.y - oldPos.y
            if deltaY isnt 0
              scrollbarJustChanged ||= @scrollY deltaY
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
        # of the panel must not get a parting scroll), and only if released
        # inside the panel (matching the per-frame gate above).
        #
        # CADENCE COLLAPSE: under the harness's pacing control (or just a slow / HiDPI
        # frame) the whole press->drag->release can drain inside ONE cycle, so the FIRST
        # @step already sees the button up and NO button-down frame ever set
        # wasScrollDragging. That used to drop the scroll ENTIRELY (total -> 0), making
        # the outcome depend on frame cadence — it scrolled at dpr 1 but not at dpr 2,
        # the same gesture giving different pixels. Recover it here: when the gesture
        # never float-dragged anything and the hand isn't poised to detach a widget
        # (so it IS a scroll-drag, not a float-move) and the press is inside the panel,
        # treat it as a scroll-drag. oldPos is still the press point, so the flush below
        # scrolls exactly release-minus-press — the SAME event-determined total the
        # multi-frame path lands on, now identical at every dpr / speed / engine.
        collapsedScrollDrag = !wasScrollDragging and
          !everFloatDragged and
          !world.hand.wdgtToGrab?.detachesWhenDragged() and
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
                scrollbarJustChanged ||= @scrollX deltaX
            if @vBar.visibleBasedOnIsVisibleProperty() and
            !@vBar.isInCollapsedSubtree()
              deltaY = releasePos.y - oldPos.y
              if deltaY isnt 0
                scrollbarJustChanged ||= @scrollY deltaY
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
    # a 'never' panel accepts the drop but does not creep toward it
    return if @scrollPolicy is 'never'
    if @wantsDropOfChild widgetBeingFloatDragged
      if !@boundingBox().insetBy(WorldWdgt.preferencesAndSettings.scrollBarsThickness * 3).containsPoint pointerPosition
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
      pos = hand.position()
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
  scrollCaretIntoView: (caretWidget) ->
    # a 'never' panel clips its caret like any other overflow — WYSIWYG of the
    # policy (a text panel that wants the caret in view wants 'auto')
    return if @scrollPolicy is 'never'
    txt = caretWidget.target
    ft = @top() + @padding
    fb = @bottom() - @padding
    fl = @left() + @padding
    fr = @right() - @padding
    # layout-apply-sanctioned: scroll-input (caret-into-view), determinism-exempt (residuals-audit fam 1)
    @_positionAndResizeChildren()
    marginAroundCaret = @padding
    if @extraPadding?
      marginAroundCaret += @extraPadding
    if caretWidget.top() < ft
      newT = @contents.top() + ft - caretWidget.top()
      @contents._moveTopSideTo newT + marginAroundCaret
      caretWidget._moveTopSideTo ft
    else if caretWidget.bottom() > fb
      newB = @contents.bottom() + fb - caretWidget.bottom()
      @contents._moveBottomSideTo newB - marginAroundCaret
      caretWidget._moveBottomSideTo fb
    if caretWidget.left() < fl
      newL = @contents.left() + fl - caretWidget.left()
      @contents._moveLeftSideTo newL + marginAroundCaret
      caretWidget._moveLeftSideTo fl
    else if caretWidget.right() > fr
      newR = @contents.right() + fr - caretWidget.right()
      @contents._moveRightSideTo newR - marginAroundCaret
      caretWidget._moveRightSideTo fr
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
      # TODO this escalation should also
      # be implemented in the touch case... user could scroll
      # WITHOUT wheel, by just touch-dragging the contents...
      #
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
      # Exact comparisons: geometry is integer by invariant (Widget._assertBoundsWellFormed),
      # and a tolerance here would hand a 1px-shy inner panel's last wheel step to the outer
      # panel instead of letting the inner one reach its edge.
      # 'never' escalates HERE, not at the refused core — the else arm would
      # otherwise mark scrollbarJustChanged and swallow the wheel dead over a
      # cropping panel instead of handing it to an enclosing scroller.
      if @scrollPolicy is 'never' or
       (y > 0 and @contents.top() >= @top()) or
       (y < 0 and @contents.bottom() <= @bottom())
        @escalateEvent 'wheel', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
      else
        scrollbarJustChanged = true
        @scrollY y * WorldWdgt.preferencesAndSettings.wheelScaleY
    if x != 0
      # similar to the vertical case, escalate the scroll in case
      # we are in a nested Viewport situation ('never' escalates too — see
      # the vertical case)
      if @scrollPolicy is 'never' or
       (x > 0 and @contents.left() >= @left()) or
       (x < 0 and @contents.right() <= @right())
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
  
  # Set this scroll panel's text-line-wrapping state; turning wrapping ON fills
  # the content to the panel's bounds. (Called by SimpleTextWdgt's soft-wrap
  # toggle, which used to write this flag + resize the content from outside.)
  #
  # The resize here is DELIBERATELY IMMEDIATE (raw geometry), not the framework's
  # ideal DEFERRED pattern (set a flag + _invalidateLayout(), let recalculateLayouts
  # -> _reLayout derive the geometry). This is INTERMEDIATE state, not an oversight:
  # the deferred mechanism is half-built by construction (the geometry accessors read
  # applied @bounds only, so handler-level raw geometry is a symptom of that
  # incompleteness, not a one-off). Soft-wrap has an EXTRA blocker on top: the content
  # panel + text are free-floating, so _invalidateLayout() on them does NOT
  # climb up to this scroll panel, and the wrap geometry lives in _positionAndResizeChildren
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
  # mixin is the core of the two Stretchables, not of a scroll panel. (A subclass whose core IS the
  # mixin — SimpleVerticalStackViewportWdgt — still `super`s into this one; the argument it hands
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

