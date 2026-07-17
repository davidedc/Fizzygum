# TODO: when floating, windows should really be able to
# accommodate any extent always, because really windows should
# be stackable and dockable in any place...
# ...and that's now how we do it now, for example a window
# with a clock right now keeps ratio...
# Only when being part of other layouts e.g. stacks the
# windows should keep a ratio etc...
# So I'm inclined to think that a window should do what the
# StretchableWidgetContainerWdgt does...

# TODO: this is such a special version of SimpleVerticalStackPanelWdgt
# that really it seems like this extension is misleading...

class WindowWdgt extends SimpleVerticalStackPanelWdgt

  # TODO we already have the concept of "droplet" widget
  # so probably we should re-use that. The current drop
  # area management seems a little byzantine...

  label: nil
  closeButton: nil
  editButton: nil
  collapseUncollapseSwitchButton: nil
  labelContent: nil
  resizer: nil
  padding: nil
  contents: nil
  titlebarBackground: nil
  defaultContents: nil
  reInflating: false

  # §4.1 pure measure (Stage D): a window's preferred height-at-width, side-effect-free (no
  # @bounds write, no seam) -- it MIRRORS the steady-state _positionAndResizeChildren WITHOUT
  # mutating anything, so a parent (a stack/scroll holding this window) can MEASURE this window
  # instead of mutating-it-and-reading-the-applied-height-back. Replaces the Stage-B stub.
  #
  #   window height = content height-at-its-allotted-width + title/resizer chrome
  #
  # - chrome (== the arrange's partOfHeightUsedUp): the titlebar (closeIcon + 2*padding) plus the
  #   bottom margin, which differs by whether the resizer may overlap the contents -- chrome
  #   comes from the shared _chromeHeight (one home for the measure and the arrange).
  # - content height: when the content sets its height FREELY (a scroller / slider / document fills
  #   whatever height the window is dragged to), the height is the window's OWN height minus chrome
  #   (mirrors the contentsRecursivelyCanSetHeightFreely branch); otherwise the content DICTATES the
  #   height (wrapping text, a stack, an aspect widget), so we RECURSE into its measure at the width
  #   it gets in the window -- getWidthInStack(availW - 2*padding), which reproduces the arrange's
  #   no-arg getWidthInStack() since availableWidthForContents() == width() - 2*padding.
  # contentsRecursivelyCanSetHeightFreely is width-independent, so testing it here (before the
  # recursion) matches the arrange's post-width-set test. A collapsed window is just its titlebar.

  # The titlebar icon square (close / collapse / edit buttons) -- ONE home for the
  # literal 16 the measure and the arrange both used to declare locally.
  @CLOSE_ICON_SIZE: 16

  # Height of the titlebar strip: icon square + a padding above and below. (Rounding the
  # whole sum -- identical to every historical inline form for any integer @padding.)
  _titlebarHeight: ->
    Math.round(WindowWdgt.CLOSE_ICON_SIZE + @padding + @padding)

  # Window chrome height -- everything that is NOT content: the titlebar strip plus the
  # bottom margin, which depends on whether the resizer may overlap the contents. ONE home
  # for the calc the measure (preferredExtentForWidth) and the arrange
  # (_positionAndResizeChildren) both used to write out inline: they MUST agree, or the
  # window's measure diverges from what its arrange then applies (assessment §6.1 rule 1).
  # The two inline copies had in fact drifted at the PARSE level -- one rounded only the
  # titlebar, the other (via CoffeeScript's implicit call in `Math.round (a) + b`) the
  # whole sum -- identical only while @padding is an integer.
  _chromeHeight: (spec) ->
    if spec.resizerCanOverlapContents
      @_titlebarHeight() + 2 * @padding
    else
      @_titlebarHeight() + 3 * @padding + WorldWdgt.preferencesAndSettings.handleSize

  # (U2) The first-placement WIDTH negotiation, as a PURE function of the spec's
  # preferredStartingWidth sentinels -- ONE home for the measure's pre-capture branch (below)
  # and the arrange's first-placement branch: they MUST agree (assessment §6.1 rule 1), or a
  # parent measuring this window mid-construction diverges from what the window's own arrange
  # then applies -- that divergence (the old flag guard reported the CURRENT, pre-negotiation
  # extent) was the root of the nested-window settle re-visits. availW = the window width the
  # caller proposes (the arrange passes its own current width).
  _negotiatedContentWidth: (availW) ->
    spec = @contents.layoutSpecDetails
    if spec.preferredStartingWidth == WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW
      # (U3-C) "the size I have now" through the content's preferredExtent, not its raw
      # width(): identical for plain content (base preferredExtent IS the applied extent),
      # but content whose OWN first placement is pending (a nested window) answers with the
      # extent that placement will produce -- so this window places it at its FINAL size in
      # one shot and the settle loop's injection never has to re-visit us.
      @contents.preferredExtent().x
    else if spec.preferredStartingWidth == WindowContentLayoutSpec.DONT_MIND
      availW - 2 * @padding
    else
      spec.preferredStartingWidth

  # (§9.7-Q, owner-decided 2026-07-17) THE width a first placement hands the content, as a
  # pure function of MY OWN attachment -- ONE home for the arrange's first-placement branch
  # and the measure's pre-capture branch (§6.1 rule 1, same contract as _negotiatedContentWidth):
  # - my own attachment is FREE-FLOATING (a desktop window): the content gets the width it
  #   asked for (the sentinel negotiation above) and the window HUGS it -- unchanged.
  # - I am CONTAINER-OWNED (window content / stack element): THE CONTAINER OWNS MY WIDTH.
  #   I never self-resize to the content, and the content gets the same container-derived
  #   width a captured window would hand it (getWidthInStack is total pre-capture, U2) --
  #   a container-owned window sizes like a captured one FROM BIRTH. This deletes the
  #   first-placement shrink->re-widen width ping-pong structurally (suite-verified
  #   byte-identical: every suite-covered hug of a container-owned window was anyway
  #   reasserted to exactly this width by its container's re-fit).
  _firstPlacementContentWidth: (availW) ->
    if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING
      @_negotiatedContentWidth availW
    else
      @contents.layoutSpecDetails.getWidthInStack availW - 2 * @padding

  # (U3-C) A window whose first placement is PENDING (content spec uncaptured) answers
  # preferredExtent with the extent that placement will produce -- the PURE mirror of the
  # arrange's first-placement branch (width: the negotiation + padding + the not-freefloating
  # clamp; height: the pre-capture measure at that width, which mirrors the height sentinels).
  # A collapsed-content or captured (steady-state) window IS its applied extent, like any
  # plain widget. Recursion (a window in a window in ...) terminates at plain content.
  preferredExtent: ->
    spec = @contents?.layoutSpecDetails
    if !spec? or spec.desiredWidth? or @contents.collapsed then return @extent()
    if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and spec.preferredStartingWidth != WindowContentLayoutSpec.DONT_MIND
      # the width hug (DESKTOP windows only -- §9.7-Q, same own-layoutSpec predicate as the
      # arrange's first-placement branch, incl. the not-recursively-freefloating min-clamp;
      # keep the two in lockstep)
      windowWidth = @_negotiatedContentWidth(@width()) + 2 * @padding
      if !@recursivelyAttachedAsFreeFloating()
        windowWidth = Math.min @width(), windowWidth
    else
      # container-owned (or DONT_MIND): the width stays what the container hands me
      windowWidth = @width()
    new Point windowWidth, @preferredExtentForWidth(windowWidth).y

  preferredExtentForWidth: (availW) ->
    if @contents? and !@contents.collapsed
      spec = @contents.layoutSpecDetails
      # A content transiently WITHOUT its layoutSpec (mid drop/delete) has no derivable measure --
      # keep the measure total and report the current extent.
      if !spec? then return new Point (availW ? @width()), @height()
      chrome = @_chromeHeight spec
      if !spec.desiredWidth?
        # FIRST placement hasn't run yet -- the spec capture is the one-shot latch (U2; this
        # branch replaced the deleted contentNeverSetInPlaceYet guard). Mirror the arrange's
        # first-placement negotiation PURELY, so an outer container measuring this window
        # DURING construction already sees the extent the window's own arrange will take --
        # not the garbage pre-negotiation extent the old guard reported. The recursion into
        # the content's measure is safe pre-capture: getWidthInStack is total (U2).
        if spec.preferredStartingHeight == WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW
          # (U3-C) through preferredExtent, not raw height() -- see _negotiatedContentWidth
          desiredHeight = @contents.preferredExtent().y
          if !@recursivelyAttachedAsFreeFloating()
            desiredHeight = Math.min desiredHeight, @height() - chrome
        else if spec.preferredStartingHeight == WindowContentLayoutSpec.DONT_MIND
          desiredHeight = Math.round @height() - chrome
        else
          # (§9.7-Q) through the shared first-placement width -- container-owned windows
          # measure at the container-derived width, desktop windows at the negotiated one,
          # exactly as the arrange will apply (lockstep via _firstPlacementContentWidth).
          desiredHeight = @contents.preferredExtentForWidth(@_firstPlacementContentWidth(availW ? @width())).y
        return new Point (availW ? @width()), desiredHeight + chrome
      if @contentsRecursivelyCanSetHeightFreely()
        desiredHeight = Math.round @height() - chrome
      else
        recommendedElementWidth = spec.getWidthInStack(availW - 2 * @padding)
        desiredHeight = @contents.preferredExtentForWidth(recommendedElementWidth).y
      return new Point availW, desiredHeight + chrome
    else if @contents?.collapsed
      return new Point availW, @_titlebarHeight()
    return new Point availW, @height()

  # TODO passing the @labelContent doesn't quite work, when
  # you add a widget to the window it overwrites the
  # title which means that this one parameter passed in
  # the constructor has no effect
  # `contents` (the widget this window wraps) is the one meaningful argument; every call site
  # passes only it. labelContent / closeButton are optional, supplied via the opts object
  # (labelContent defaults to "my window"). The former `internal` / `alwaysShowInternalExternalButton`
  # positional args are GONE (P5 arg-object conversion): internal-ness is DERIVED from parentage
  # (see isInternal) and the internal/external switch button is gone, so both were inert — neither
  # was ever bound to `@`, stored, or serialized.
  constructor: (@contents, opts = {}) ->
    super nil, nil, 40, true
    @labelContent = opts.labelContent ? "my window"
    @closeButton = opts.closeButton

    @_deriveAndSetBodyAppearance()

    @strokeColor = Color.create 125,125,125
    @tight = true

    @defaultContents = new WindowContentsPlaceholderText
    if !@contents?
      @contents = @defaultContents

    @padding = 5
    # TODO this looks better:
    #@padding = 10
    @color = Color.create 248, 248, 248
    @_buildAndConnectChildren()

    if @contents == @defaultContents
      @_setEmptyWindowLabelNoSettle()
    else
      @disableDrops()
      # TODO there is a duplicate of this down below
      titleToBeSet = @contents.colloquialName()
      if titleToBeSet == "window"
        titleToBeSet = "window with another " + titleToBeSet
      if titleToBeSet == "internal window"
        titleToBeSet = "window with an " + titleToBeSet
      @label.setText titleToBeSet

    # settled-after-new: SETTLE the default extent as the constructor's LAST act (was
    # @_applyExtent, which left a pending re-fit -- and, for default contents, the
    # _setEmptyWindowLabelNoSettle label too -- so `new WindowWdgt` returned UNsettled). This flushes both.
    # Kept on the public setExtent rather than folded into _buildAndConnectChildrenNoSettle: that core is
    # SHARED with the rebuild-on-drop paths, which must NOT reset a user-resized window back to 300x300.
    @setExtent new Point 300, 300


  # in general, windows just create a reference of themselves and
  # that is it. However, windows containing a ScriptWdgt create
  # a special type of reference that has a slightly different icon
  # and when double-clicked actually runs the script rather than
  # bringing up the script
  createReference: (referenceName, placeToDropItIn) ->
    # this function can also be called as a callback
    # of a trigger, in which case the first parameter
    # here is a menuItem. We take that parameter away
    # in that case.
    if referenceName? and typeof(referenceName) != "string"
      referenceName = nil
      placeToDropItIn = world

    # ScriptWdgt content yields a special script shortcut (runs the script on double-click);
    # any other content falls to the default reference via super. The content type decides via
    # specialWindowReferenceShortcut instead of `@contents instanceof ScriptWdgt`.
    # (type-test-elimination campaign)
    widgetToAdd = @contents?.specialWindowReferenceShortcut?(@, referenceName)
    if widgetToAdd?
      # this "add" is going to try to position the reference
      # in some smart way (i.e. according to a grid)
      placeToDropItIn.add widgetToAdd
      widgetToAdd.setExtent new Point 75, 75
      widgetToAdd.fullChanged()
      @bringToForeground()
    else
      super


  # A window is "internal" -- drawn with the flat, embedded title-bar skin and called an
  # "internal window" -- exactly when it is NESTED inside a real container: its parent is
  # neither the desktop (world) nor the hand (world.hand, its transient parent while being
  # float-dragged). DERIVED from parentage rather than a stored flag, so the skin simply
  # FOLLOWS where the window lives -- drag it into a container and it reads internal, out to
  # the desktop and it reads external -- re-applied on every (re)parenting by _reactToBeingAdded.
  # This is what let us delete makeInternal / makeExternal and the manual internal/external
  # switch button: nesting a window (drag-with-dwell) or ejecting it (drag-out, Phase 3 rule
  # flip) now updates the skin automatically, no toggle needed.
  isInternal: ->
    # A sugar island -- the transient TransformFrameWdgt that setRotationDegrees/setScaleFactor wraps a
    # widget in to tilt/scale it -- is an IMPLEMENTATION DETAIL of "this window is tilted", NOT a real
    # container the window was nested into. Classify against my REAL container (through any sugar wrap):
    # tilting an EXTERNAL window keeps it external (true parent still world), a tilted INTERNAL window keeps
    # it internal (true parent still the real container). The look-through idiom is shared with
    # BasementWdgt.holds (§7.5 Bug A/B) -- one _parentThroughIslands, not a bespoke check per site.
    # Option B (latent 2): the look-through also climbs EXPLICIT sole-content islands, so an
    # explicitly-islanded window on the desktop reads EXTERNAL (its real home is the world).
    p = @_parentThroughIslands()
    p? and p isnt world and p isnt world?.hand

  setTitle: (newTitle) ->
    @label.setText @contents.colloquialName() + ": " + newTitle

  setTitleWithoutPrependedContentName: (newTitle) ->
    @label.setText newTitle

  representativeIcon: ->
    if @contents == @defaultContents
      return super
    else
      return @contents.representativeIcon()

  closeFromWindowBar: ->
    @contents?.closeFromContainerWindow @

  # The title-bar Close/Edit buttons announce their press here instead of testing
  # `@parent instanceof WindowWdgt` themselves -- the window owns what its bar
  # buttons mean. closeButtonInBarPressed mirrors the old button branch exactly (a
  # contents-bearing window closes from the bar, an empty one just closes); a
  # non-window container of a close button has no such method, so that button falls
  # back to Widget.close(). (type-test-elimination campaign)
  closeButtonInBarPressed: ->
    if @contents? then @closeFromWindowBar() else @close()

  editButtonInBarPressed: ->
    @contents?.editButtonPressedFromWindowBar?()

  contentsRecursivelyCanSetHeightFreely: ->
    # was `!(@contents instanceof WindowWdgt)` (type-test-elimination campaign)
    if !@contents.isWindow?()
      # FIT_BOX_TO_TEXT content drives its OWN height from its wrapped text, so the
      # window must FOLLOW that height (shrinking when a widen re-wraps to fewer
      # lines), not stretch the content to fill a freely-dragged height. A
      # SimplePlainTextWdgt already forces this via layoutSpecDetails.canSetHeightFreely
      # = false in its ctor; keying off the mode generalizes it to any contained
      # TextWdgt (a non-text content has no fittingSpec, so this is a no-op for it).
      if @contents.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT then return false
      return (@contents.layoutSpecDetails.canSetHeightFreely and !@contents.isInCollapsedSubtree()) and !@reInflating
    return @contents.contentsRecursivelyCanSetHeightFreely()

  recursivelyAttachedAsFreeFloating: ->
    if @isFreeFloating()
      return true

    if @parent?
      # was `@parent instanceof WindowWdgt` (type-test-elimination campaign)
      if @parent.isWindow?()
        return @parent.recursivelyAttachedAsFreeFloating()

    return false


  # A window is the DELIBERATE-EMBED payload class (drag-embed spec §4): dropping it into a container
  # must be armed by a dwell (spec §6), so windows are never nested by accident during the constant
  # move-a-window gesture. (Overrides Widget's plain default.)
  requiresDeliberateEmbedding: ->
    return true

  # A window is a SimpleVerticalStackPanelWdgt but does NOT impose its ratio on dropped
  # children (was the `!(whereIn instanceof WindowWdgt)` exclusion in the ratio mixin /
  # Example3DPlotWdgt). It still RELEASES the constraint on grab, via the inherited default.
  # (type-test-elimination campaign)
  imposesRatioConstraintOnDroppedChildren: ->
    false

  # Re-title the (content-less) window through the NON-settling label core (hence the NoSettle
  # name): reached either during construction (orphan -> deferred) or from _resetToDefaultContents
  # inside a close/destroy settle, so the enclosing settle flushes it -- a self-settling setText
  # would open a nested settle mid-pass. (The label is FIT_TEXT_TO_BOX, so the text swap changes
  # no geometry anyway; @changed() in the core repaints it.)
  _setEmptyWindowLabelNoSettle: ->
    if @isInternal()
      @label._setTextNoSettle "empty internal window"
    else
      @label._setTextNoSettle "empty window"

  # Polymorphic replacement for `instanceof WindowWdgt`: lets Widget / the smart-placer
  # ask "are you a window?" without naming this subclass. Defined ONLY here -- there is NO
  # Widget base default (Widget is the God class under decomposition), so every call site
  # dispatches via `?()` and a non-window answers undefined (falsy). (type-test-elimination campaign)
  isWindow: -> true

  colloquialName: ->
    if @isInternal()
      return "internal window"
    else
      return "window"

  # (no _reLayoutChildren override: SimpleVerticalStackPanelWdgt's is already `@_positionAndResizeChildren()`,
  # and that dispatches to the window's own override below -- which is what re-fits chrome + content.)

  # A window fits its OWN width to its content -- but ONLY in the FIRST-PLACEMENT branch of its
  # arrange (the steady-state branch re-fits height alone, exactly like a stack), and -- post
  # §9.7-Q (rule B2+D, owner-decided 2026-07-17) -- ONLY when the window is itself attached
  # FREE-FLOATING: a CONTAINER-OWNED window never self-resizes its width (its container owns it,
  # see the first-placement branch's own-layoutSpec gate in _positionAndResizeChildren). So this
  # capability -- "re-laying me synchronously while my container is mid-arrange may re-negotiate
  # my width, diverging from my normal independent settle" (the historical failure: an outer
  # window's early settle collapsed an inner window to its content's aspect width) -- DERIVES
  # from BOTH one-shot states: TRUE only while the content spec is uncaptured (first placement
  # pending, U2-B) AND my own attachment is free-floating (the only case whose first placement
  # touches my width). A captured window is height-only under re-lay; so is a container-owned
  # window even pre-capture -- both safe to early-settle single-pass in
  # WindowWdgt._positionAndResizeChildren. Narrowing the pre-capture term to own-FF is what
  # retires the LAST nested-window settle re-visits: a first-placement inner window now settles
  # inside its outer's arrange instead of on its own later turn + an up-edge re-visit of the
  # outer (up-edge endgame V1-b, docs/upedge-endgame-plan.md §9). Absent (undefined via ?()) on
  # a stack, whose synchronous re-lay keeps its container-assigned width.
  _reLayoutMayResizeOwnWidth: ->
    @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and !@contents?.layoutSpecDetails?.desiredWidth?

  add: (aWdgt, position = nil, layoutSpec, beingDropped, notContent) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped, notContent: notContent

  # _addNoSettle -- the non-settling core of add() (mirrors Widget.add/_addNoSettle and
  # SimpleVerticalStackPanelWdgt.add/_addNoSettle). Folds in the window's content bookkeeping (title,
  # @contents swap, spec init + first-placement re-arm) so the build/teardown chain
  # (_buildAndConnectChildrenNoSettle) adds chrome + content WITHOUT flushing layouts: super threads
  # down through SimpleVerticalStackPanelWdgt._addNoSettle to Widget._addNoSettle, all non-settling.
  # @_addNoSettle @contents (vs the bare base _addNoSettle) is exactly what keeps @stack wired by the
  # deferred re-fit.
  _addNoSettle: (aWdgt, opts = {}) ->
    position = opts.position
    layoutSpec = opts.layoutSpec
    beingDropped = opts.beingDropped
    notContent = opts.notContent
    # caret + handle are the layout decorations (was their two instanceof) (type-test-elimination campaign)
    unless notContent or aWdgt.isLayoutInert?()
      titleToBeSet = aWdgt.colloquialName()
      if titleToBeSet == "window"
        titleToBeSet = "window with another " + titleToBeSet
      if titleToBeSet == "internal window"
        titleToBeSet = "window with an " + titleToBeSet
      # re-title through the NON-settling label core: _addNoSettle already runs inside the
      # add's settle, so the title change rides that flush instead of opening a nested one.
      @label._setTextNoSettle titleToBeSet
      # (§9.7-Q, owner-decided 2026-07-17) a chrome rebuild (_buildAndConnectChildrenNoSettle,
      # reached from _reactToChildDropped / _resetToDefaultContents) re-adds the widget that
      # is ALREADY my content. That is bookkeeping, not a re-mount: the placement it would
      # re-negotiate was just negotiated in the same flush, so re-arming for it only produced
      # a duplicate first-placement pass (one settle re-visit per drop, probe-verified).
      isSameContentRemount = aWdgt == @contents
      @removeChild @contents
      @contents = aWdgt
      # Deferred-layout (capstone probe): the window-content re-fit now DEFERS to the settle cycle
      # (super -> _addNoSettle invalidates the window; the inherited _reLayout runs @_reLayoutChildren on
      # the recalculateLayouts pass). The old synchronous pre-fit (@_reLayoutChildren here) is removed.
      # Init the content's WindowContentLayoutSpec up-front -- the pre-fit used to do this implicitly
      # via _positionAndResizeChildren, so without it the deferred re-fit would deref an uninitialised spec.
      aWdgt.initialiseDefaultWindowContentLayoutSpec() unless aWdgt.layoutSpecDetails instanceof WindowContentLayoutSpec
      # (U2) re-arm the first-placement ONE-SHOT for this mount: content (re)mounted into a
      # window re-negotiates its placement. The old model re-ran the capture via
      # the contentNeverSetInPlaceYet flag; the CAPTURE is now itself the latch, so un-latch it
      # (a fresh spec is already unlatched; this covers content carrying a spec from a prior
      # life) -- but NOT for a same-widget chrome-rebuild re-add (§9.7-Q above): the standing
      # capture is exactly the placement this mount already has.
      aWdgt.layoutSpecDetails.desiredWidth = nil unless isSameContentRemount
      super aWdgt, position: position, layoutSpec: LayoutSpec.ATTACHEDAS_WINDOW_CONTENT, beingDropped: beingDropped
    else
      super aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped
    @resizer?._moveInFrontOfSiblings()

  _beforeChildDestroyed: (child) ->
    if child == @contents
      @_resetToDefaultContents()

  _beforeChildPickedUp: (child) ->
    if child == @contents
      @_resetToDefaultContents()

  _beforeChildClosed: (child) ->
    if child == @contents
      @_resetToDefaultContents()

  _beforeChildCollapsed: (child) ->
    if child == @contents
      @widthWhenUnCollapsed = @width()
      @contentsExtentWhenCollapsed = @contents.extent()
      @extentWhenCollapsed = @extent()

      # tear down the bar buttons through the non-settling core: this hook fires inside collapse's
      # settle, so the public self-settling destroy() would throw under the single-mutation tier. The
      # enclosing collapse settle covers the re-layout.
      @editButton?._destroyNoSettle()
      @editButton = nil

  _beforeChildUnCollapsed: (child) ->
    if child == @contents
      @widthWhenCollapsed = @width()

    @_createAndAddEditButton()

  _reactToChildCollapsed: (child) ->
    if child == @contents
      if @widthWhenCollapsed?
        @_applyWidth @widthWhenCollapsed
      # layout-apply-sanctioned: collapse re-fit (must stay synchronous, residuals-audit fam 4)
      @_reLayoutChildren()
      @_invalidateLayout()   # (property sub-seam deletion) uniform climb replaces the property re-fit seam
      @parent.parent._invalidateLayout() if @_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()   # (proper-layouts) reach the scroll-panel grandparent; the window's bare climb is dropped at the non-tracking @contents PanelWdgt

  _reactToChildUnCollapsed: (child) ->
    if child == @contents
      @reInflating = true
      @_applyExtent @extentWhenCollapsed
      @contents._applyExtent @contentsExtentWhenCollapsed
      if @widthWhenUnCollapsed?
        @_applyWidth @widthWhenUnCollapsed
      # layout-apply-sanctioned: uncollapse re-fit, reInflating-coupled (must stay synchronous, residuals-audit fam 4)
      @_reLayoutChildren()
      @reInflating = false
      @_rememberFractionalSituationInHoldingPanel()
      @_invalidateLayout()   # (property sub-seam deletion) uniform climb replaces the property re-fit seam
      @parent.parent._invalidateLayout() if @_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()   # (proper-layouts) reach the scroll-panel grandparent; the window's bare climb is dropped at the non-tracking @contents PanelWdgt

  _resetToDefaultContents: ->
    # public-call-sanctioned: enableDrops is the trivial public drop-acceptance setter (macros and
    # cross-object code drive it) — settle-free, consciously reused here.
    @enableDrops()
    @contents = @defaultContents
    # Reached only from a child-lifecycle hook (_beforeChildDestroyed/PickedUp/Closed). Rebuild through
    # the non-settling core so a hook firing INSIDE an enclosing settle (destroy/close) is absorbed by
    # that operation's settle instead of re-entering the public self-settler. (window-rebuild follow-up)
    @_buildAndConnectChildrenNoSettle()
    @_setEmptyWindowLabelNoSettle()
    if @recursivelyAttachedAsFreeFloating()
      @_applyExtent new Point 300, 300

  _beforeChildDropped: (child) ->
    @removeChild @contents

  _reactToBeingDropped: (whereIn) ->
    super
    @contents?._reactToHolderWindowDropped? whereIn

  _reactToBeingGrabbed: (whereFrom) ->
    @contents?._reactToHolderWindowGrabbed? whereFrom

  # The whole-window skin follows the window's nesting (isInternal, derived from parentage), so
  # re-apply it whenever the window lands in a new home: a container makes it internal (flat,
  # embedded skin), the desktop makes it external (boxy). This is the ONE place the skin used to
  # be flipped manually by makeInternal/makeExternal via the internal/external switch button --
  # now it is automatic on every (re)parenting (drag-drop AND programmatic add both route through
  # here after the reparent, so a dashboard/document that builds a nested window via `container.add`
  # gets the internal skin too). We re-derive BOTH the window body appearance and the title-bar
  # appearance/colors so the whole window flips consistently (a window built internal=true and then
  # nested via container.add ends up byte-identical to the old stored-flag path). We SKIP the
  # transient pick-up by the hand (whereTo is world.hand) so the skin stays put during a drag and
  # settles on release, exactly as the old stored flag did.
  _reactToBeingAdded: (whereTo, beingDropped) ->
    super
    if whereTo isnt world?.hand
      @_deriveAndSetBodyAppearance()
      @_setAppearanceAndColorOfTitleBackground()
      @changed()

  _reactToChildDropped: (theWidget) ->
    @contents = theWidget
    super
    # public-call-sanctioned: disableDrops is the trivial public drop-acceptance setter (macro-visible
    # behaviour: an occupied window stops accepting drops) — settle-free, consciously reused here.
    @disableDrops()
    # _reactToChildDropped runs inside the drop's single settle, so rebuild through the NON-settling core
    # (not the public _buildAndConnectChildren wrapper, which would re-enter the flush guard) -- same
    # as the _resetToDefaultContents lifecycle path above.
    @_buildAndConnectChildrenNoSettle()

  # The window BODY appearance half of the internal/external skin (the title-bar half is
  # _setAppearanceAndColorOfTitleBackground): flat RectangularAppearance when nested (internal),
  # boxy BoxyAppearance when free on the desktop (external). Derived from isInternal (parentage),
  # set at construction and re-derived on every re-parenting by _reactToBeingAdded.
  _deriveAndSetBodyAppearance: ->
    if @isInternal()
      @appearance = new RectangularAppearance @
    else
      @appearance = new BoxyAppearance @

  _setAppearanceAndColorOfTitleBackground: ->
    if @isInternal()
      @titlebarBackground.appearance = new RectangularAppearance @titlebarBackground
    else
      @titlebarBackground.appearance = new BoxyAppearance @titlebarBackground

    if @isInternal()
      @titlebarBackground.setColor WorldWdgt.preferencesAndSettings.internalWindowBarBackgroundColor
      @titlebarBackground.strokeColor = WorldWdgt.preferencesAndSettings.internalWindowBarStrokeColor
    else
      @titlebarBackground.setColor WorldWdgt.preferencesAndSettings.externalWindowBarBackgroundColor
      @titlebarBackground.strokeColor = WorldWdgt.preferencesAndSettings.externalWindowBarStrokeColor


  _buildTitlebarBackground: ->
    if @titlebarBackground?
      # tear down through the non-settling core: this runs inside _buildAndConnectChildren's settle, so
      # the public self-settling fullDestroy() would throw under the single-mutation tier. The enclosing
      # rebuild settle covers the re-layout.
      @titlebarBackground._fullDestroyNoSettle()

    # TODO we should really just instantiate a Widget,
    # and give it the shape, there is no reason to create
    # the dedicated shape widget and then change the appearance
    # as the window changes from internal to external and vice versa
    # HOWEVER a bunch of tests would fail if I do the proper
    # thing so we are doing this for the time being.
    if @isInternal()
      @titlebarBackground = new RectangleWdgt
    else
      @titlebarBackground = new BoxWdgt

    @_setAppearanceAndColorOfTitleBackground()
    @_addNoSettle @titlebarBackground, notContent: true
  
  # ONE settle around the whole rebuild via the single-mutation tier (_settleLayoutsAfter). The
  # core is non-settling: it adds every chrome widget AND the content through @_addNoSettle (the cores
  # mirrored down WindowWdgt -> SimpleVerticalStackPanelWdgt -> Widget), so nothing self-settles per add
  # and nothing re-fits the HALF-built window mid-loop -- the window's content bookkeeping rides along in
  # WindowWdgt._addNoSettle. The single settle runs AFTER the core, when @stack is wired: O(1) relayouts.
  #
  # This PUBLIC self-settler is only ever called STANDALONE (the constructor). Every rebuild path that
  # fires from inside an enclosing settle -- a child-lifecycle hook (_beforeChildDestroyed/Closed/PickedUp)
  # -> _resetToDefaultContents -> rebuild, or _reactToChildDropped inside the drop's settle -- goes through the
  # non-settling @_buildAndConnectChildrenNoSettle directly, never this wrapper, so the wrapper never
  # re-enters a flush. The chrome the core constructs adds to ORPHANS, exempt from the flush-throw
  # (Widget._settleLayoutsAfter's orphan guard precedes the throw). (Phase 3b; window-rebuild follow-up.)
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->

    if !@titlebarBackground?
      @_buildTitlebarBackground()

    # label -- tear down through the non-settling core (inside the rebuild's settle; see _buildTitlebarBackground)
    @label?._fullDestroyNoSettle()
    @label = new StringWdgt @labelContent, WorldWdgt.preferencesAndSettings.titleBarTextFontSize

    # as of March 2018, Safari 10.1.1 on OSX 10.12.5 :
    # safari's rendering of bright text on dark background is atrocious
    # so we have to force bold style in the window bars
    if /^((?!chrome|android).)*safari/i.test navigator.userAgent
      @label.isBold = true
    else
      @label.isBold = WorldWdgt.preferencesAndSettings.titleBarBoldText

    @label.color = Color.WHITE
    @_addNoSettle @label, notContent: true

    # upper-left button, often a close button
    # but it can be anything
    if !@closeButton?
      @closeButton = new CloseIconButtonWdgt
    @_addNoSettle @closeButton, notContent: true


    if !@collapseUncollapseSwitchButton?
      collapseButton = new CollapseIconButtonWdgt
      uncollapseButton = new UncollapseIconButtonWdgt
      @collapseUncollapseSwitchButton = new SwitchButtonWdgt [collapseButton, uncollapseButton]
    @_addNoSettle @collapseUncollapseSwitchButton, notContent: true


    @_createAndAddEditButton()

    @_addNoSettle @contents

    if !@resizer?
      # Attach the resizer, then record it. @resizer stays nil DURING its own add so the
      # `@resizer?._moveInFrontOfSiblings()` in _addNoSettle (above) is a no-op for the resizer
      # itself -- it only re-fronts the resizer when LATER content is added. (Byte-identical to the
      # old `@resizer = new HandleWdgt @`, whose in-constructor add also ran while @resizer was nil.)
      resizer = new HandleWdgt
      @_addNoSettle resizer, layoutSpec: resizer.defaultLayoutSpecWhenAddedTo(@)
      @resizer = resizer

  # Reflect the content's edit/view mode in the title-bar edit button. The glyph
  # NAMES the current mode (pencil = editing now, eye = viewing now); the button
  # owns its own rest/hover appearance + colour (monochrome at rest, colour on
  # hover as feedforward — see EditIconButtonWdgt), so this just sets the mode.
  # Driven from the enable/disable state-reflection callers, not from clicks.
  showEditModeInBar: ->
      @editButton?.showPencilGlyph()

  showViewModeInBar: ->
      @editButton?.showEyeGlyph()

  _createAndAddEditButton: ->
    # public-call-sanctioned: showEditModeInBar/showViewModeInBar are the window-bar mode PROTOCOL —
    # content widgets drive them cross-object (`@parent?.showEditModeInBar?()`), so they stay public.
    if @contents?.providesAmenitiesForEditing and !@editButton?
      @editButton = new EditIconButtonWdgt @
      @_addNoSettle @editButton, notContent: true

      if @contents.dragsDropsAndEditingEnabled
        @showEditModeInBar()
      else
        @showViewModeInBar()

  # (no initialiseDefaultWindowContentLayoutSpec override: SimpleVerticalStackPanelWdgt's already ends
  # with the same `@layoutSpecDetails.canSetHeightFreely = false`, so re-asserting it here was a no-op.)

  # The re-fit chokepoint for a window (no scrollbars): re-fit chrome + content. Reached via the
  # inherited SimpleVerticalStackPanelWdgt._reLayoutChildren, which dispatches back here.
  # should this just be the _reLayout function? Why do we need this extra one?
  _positionAndResizeChildren: ->

    closeIconSize = WindowWdgt.CLOSE_ICON_SIZE

    # close button
    if @closeButton? and @closeButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @padding, @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @closeButton._reLayout buttonBounds

    # collapse/uncollapse button
    if @collapseUncollapseSwitchButton? and @collapseUncollapseSwitchButton.parent == @
      buttonBounds = new Rectangle new Point @left() + closeIconSize + 2 * @padding, @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @collapseUncollapseSwitchButton._reLayout buttonBounds

    stackHeight = 0

    if @contents? and !@contents.collapsed
      # Order-independent spec init: also (re)init when the content lacks a WindowContentLayoutSpec,
      # not only when its layoutSpec tag is unset. With the on-add pre-fit removed (deferred layout),
      # super sets the layoutSpec tag to ATTACHEDAS_WINDOW_CONTENT BEFORE this deferred re-fit runs,
      # so the old tag-only gate would skip init and this would deref an uninitialised/stack-typed spec.
      if @contents.layoutSpec != LayoutSpec.ATTACHEDAS_WINDOW_CONTENT or !(@contents.layoutSpecDetails instanceof WindowContentLayoutSpec)
        @contents.initialiseDefaultWindowContentLayoutSpec()
        @contents._setLayoutSpec LayoutSpec.ATTACHEDAS_WINDOW_CONTENT

      # (U2) the first-placement ONE-SHOT is CONTENT-owned: an uncaptured spec (desiredWidth
      # unset -- fresh init above, or re-armed on content (re)mount in _addNoSettle) selects
      # the negotiation branch ONCE; captureInitialPlacement below is itself the latch.
      # This replaced the window-level contentNeverSetInPlaceYet boolean (decl + set + two
      # branch selectors + clear, all deleted). Computed BEFORE the capture latches, and used
      # by BOTH the width branch here and the height branch below.
      firstPlacement = !@contents.layoutSpecDetails.desiredWidth?

      if firstPlacement
        # in this case the contents has just been added
        recommendedElementWidth = @_firstPlacementContentWidth @width()
        if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and @contents.layoutSpecDetails.preferredStartingWidth != WindowContentLayoutSpec.DONT_MIND
          # THIS_ONE_I_HAVE_NOW / an explicit px on a DESKTOP window: the WINDOW resizes
          # (hugs) to the content's width. A CONTAINER-OWNED window never self-resizes its
          # width -- the container owns it (§9.7-Q, owner-decided 2026-07-17; the predicate
          # is MY OWN layoutSpec, NOT recursivelyAttachedAsFreeFloating(), which answers for
          # the ISLAND -- a window nested in a desktop window IS recursively-freefloating).
          # ⚠ suppressing the hug ALONE (still handing the content the negotiated width) is
          # the U3-C falsified shape (plan §6): the content freezes at a width its window
          # never converges to (stale applied-vs-spec, clipped text). The sound form is the
          # PAIRED rule in _firstPlacementContentWidth: no hug AND the container-derived
          # content width, so window and content agree from birth.
          if @recursivelyAttachedAsFreeFloating()
            windowWidth = recommendedElementWidth + @padding * 2
          else
            windowWidth = Math.min @width(), recommendedElementWidth + @padding * 2
          @_applyExtentBase new Point windowWidth, @height()

        @contents.layoutSpecDetails.captureInitialPlacement @contents, @


      else
        # the content was already there
        recommendedElementWidth = @contents.layoutSpecDetails.getWidthInStack()

      partOfHeightUsedUp = @_chromeHeight @contents.layoutSpecDetails

      # this re-layouts each widget to fit the width.
      if firstPlacement
        # in this case the contents has just been added
        if @contents.layoutSpecDetails.preferredStartingHeight == WindowContentLayoutSpec.THIS_ONE_I_HAVE_NOW
          # (U3-C) through preferredExtent, not raw height() -- see _negotiatedContentWidth
          desiredHeight = @contents.preferredExtent().y
          if !@recursivelyAttachedAsFreeFloating()
            desiredHeight = Math.min desiredHeight, @height() - partOfHeightUsedUp
          @contents._applyWidth recommendedElementWidth
          @contents._applyHeight desiredHeight
        else if @contents.layoutSpecDetails.preferredStartingHeight == WindowContentLayoutSpec.DONT_MIND
          @contents._applyWidth recommendedElementWidth
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents._applyHeight desiredHeight
        else
          # Path B: the sizing HANDS its resulting height back -- no read-back of @contents.height().
          desiredHeight = @contents._setWidthSizeHeightAccordingly recommendedElementWidth

        # (no flag clear -- captureInitialPlacement above latched the one-shot)
      else
        # the content was already there
        # Path B: take the resulting height from the sizing call, not a read-back of @contents.height().
        desiredHeight = @contents._setWidthSizeHeightAccordingly recommendedElementWidth

        # (proper-layouts residual, 2026-07-01) Single-pass fit-to-content: settle a NON-deferred size-tracking
        # container content (a stack) NOW, synchronously, so I fit its FINAL height in THIS pass. Otherwise the
        # content settles independently LATER (as its own settle-loop chain-top) and its settle-time re-fit
        # re-VISITS me to re-fit -- the residual WindowWdgt content-negotiation re-visits. This is the SAME
        # _reLayout() the settle loop would call on the content's own turn, pulled one iteration earlier, so it
        # is byte-exact. _setWidthSizeHeightAccordingly already settles DEFERRED-layout content (a scroll panel);
        # a stack pins implementsDeferredLayout false, so we settle it here. EXCLUDES content that re-fits its OWN
        # width when re-laid (a nested window, _reLayoutMayResizeOwnWidth): settling THAT early re-negotiates its
        # width and diverges from its normal independent settle -- its re-visit is a GENUINE width<->height
        # convergence, correctly left to the settle loop.
        if @contents._reLayoutChildren? and not @contents.implementsDeferredLayout() and not @contents.layoutIsValid and not @contents._reLayoutMayResizeOwnWidth?()
          @contents._reLayout()
          desiredHeight = @contents.height()

        if @contentsRecursivelyCanSetHeightFreely()
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents._applyHeight desiredHeight

      # contained text that has OPTED INTO FIT_BOX_TO_TEXT (a SimplePlainTextWdgt,
      # or any bare TextWdgt put into that mode) fits its BOX to the TEXT: it wraps
      # to the width we set generically above and its height follows the wrapped
      # content. We RESPECT the mode rather than imposing it, so the empty-window
      # placeholder — a TextWdgt that stays FIT_TEXT_TO_BOX — is left alone. Here we
      # only (re)assert soft-wrap (the actual reflow is driven by the generic
      # width-set above → the widget's own FIT_BOX_TO_TEXT _reLayoutSelf).
      if @contents.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
        @contents.softWrap = true

      leftPosition = @left() + Math.floor (@width() - recommendedElementWidth) / 2

      @contents._applyMoveTo new Point leftPosition, @top() + (closeIconSize + @padding + @padding) + @padding
      stackHeight += desiredHeight

    if @contents? and @contents.collapsed
      partOfHeightUsedUp = @_titlebarHeight()


    newHeight = stackHeight + partOfHeightUsedUp

    @_applyExtentBase new Point @width(), newHeight

    @titlebarBackground._applyExtent (new Point @width(), closeIconSize + 2 * @padding).subtract new Point 2,2
    @titlebarBackground._applyMoveTo @position().add new Point 1,1
    # TODO this looks better:
    #@titlebarBackground._applyExtent (new Point @width(), closeIconSize + 2 * @padding).subtract new Point 4,4
    #@titlebarBackground._applyMoveTo @position().add new Point 2,2

    # NON-settling cores (not the public collapse/unCollapse): this is a layout pass, so reaching the
    # self-settling wrapper would re-enter the flush. The cores are idempotent, so an already-correct
    # button is a no-op exactly as the public guards made it. (check-layering [G])
    # The edit button is now the rightmost title-bar button (the internal/external switch that used to
    # sit to its right is gone), so it collapses at the tighter width the switch used to.
    if @width() < 3 * (closeIconSize + @padding) + @padding
      @editButton?._collapseNoSettle()
    else
      @editButton?._unCollapseNoSettle()

    # label
    if @label? and @label.parent == @
      labelLeft = @left() + @padding + 2 * (closeIconSize + @padding)
      labelTop = @top() + @padding
      labelRight = @right() - @padding
      if @editButton? and !@editButton.isInCollapsedSubtree()
        labelRight -= 1 * (closeIconSize + @padding)
      labelWidth = labelRight - labelLeft

      labelBounds = new Rectangle new Point labelLeft, labelTop
      labelBounds = labelBounds.setBoundsWidthAndHeight labelWidth, WorldWdgt.preferencesAndSettings.titleBarTextHeight
      @label._applyBounds labelBounds

    # edit button -- now the sole right-hand title-bar button (the internal/external switch that
    # used to occupy the rightmost slot is gone), so it takes that rightmost slot.
    if @editButton? and !@editButton.isInCollapsedSubtree() and @editButton.parent == @
      buttonBounds = new Rectangle new Point @right() - 1 * (closeIconSize + @padding), @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @editButton._reLayout buttonBounds

    # TODO there is *already* a way to make handles do the right thing, and that is
    # to have this sort of code in a _reLayout function, and calling super in there,
    # where the base Windget._reLayout takes care of everything that has a
    # corner or edge internal layout, like handles. This should work the same way i.e.
    # this code should not be here.
    if @resizer?.parent == @
      @resizer.__commitMoveTo new Point @right() - WorldWdgt.preferencesAndSettings.handleSize - @padding, @bottom() - WorldWdgt.preferencesAndSettings.handleSize - @padding
