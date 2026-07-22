# TODO: when floating, windows should really be able to
# accommodate any extent always, because really windows should
# be stackable and dockable in any place...
# ...and that's now how we do it now, for example a window
# with a clock right now keeps ratio...
# Only when being part of other layouts e.g. stacks the
# windows should keep a ratio etc...
# So I'm inclined to think that a window should do what the
# StretchableWidgetContainerWdgt does...

class FrameWdgt extends Widget

  # A frame's content can transiently stick out of the frame (mid width/height
  # negotiation, mid drop), so clip at the bounds. The mixin also carries the
  # _applyMoveTo scroll-optimization override -- the repaint path a parent stack
  # takes when it moves this frame as a tracking-container child.
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  # TODO we already have the concept of "droplet" widget
  # so probably we should re-use that. The current drop
  # area management seems a little byzantine...

  # An EMPTY frame accepts drops (Widget's class default is false); the
  # ctor/reset/content paths then enable/disable per content state.
  _acceptsDrops: true

  # the title bar -- ONE child (FrameBarWdgt) owning the five title-strip
  # pieces and the title half of the skin
  bar: nil
  # ALIASES into the bar's pieces: same instances, frame-side names -- these are
  # load-bearing contracts (MacroToolkit + the macro tests reach win.label /
  # win.closeButton / win.editButton / win.collapseUncollapseSwitchButton /
  # win.titlebarBackground; FolderWindowWdgt supplies its own closeButton;
  # showEditModeInBar drives @editButton). Kept in sync at the three mutation
  # points: build, edit-button destroy on collapse, recreate on uncollapse.
  label: nil
  closeButton: nil
  editButton: nil
  collapseUncollapseSwitchButton: nil
  titlebarBackground: nil
  labelContent: nil
  resizer: nil
  padding: nil
  contents: nil
  defaultContents: nil
  # the toolbar-slot's occupant (Frame-model plan §5.C): a ToolbarWdgt the
  # CONTENT declares (@contents.buildToolbar?()), docked per its dockSide,
  # STABLE across mode flips -- shown in edit mode, COLLAPSED (not removed) in
  # view mode, so flipping the pencil never churns the tree. nil when the
  # content declares none (plain content, the empty-window placeholder).
  toolbar: nil

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
    Math.round(FrameWdgt.CLOSE_ICON_SIZE + @padding + @padding)

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
      @_titlebarHeight() + 2 * @padding + @_topDockThickness()
    else
      @_titlebarHeight() + 3 * @padding + WorldWdgt.preferencesAndSettings.handleSize + @_topDockThickness()

  # ===== the toolbar-slot's layout terms (§5.C) =====
  # The docked toolbar occupies layout space exactly when it is HERE and SHOWN
  # (view mode collapses it to a zero contribution). Pure reads -- the measures
  # consume these, so they must never read a laid-out extent (dockThickness is
  # a class constant on the toolbar).
  _dockedToolbarShowing: ->
    @toolbar? and @toolbar.parent == @ and !@toolbar.collapsed

  # Vertical chrome a TOP-docked toolbar adds (strip + the gap to the content);
  # 0 when hidden or docked elsewhere. Folded into _chromeHeight above.
  _topDockThickness: ->
    if @_dockedToolbarShowing() and @toolbar.dockSide == 'top'
      @toolbar.dockThickness + @padding
    else
      0

  # Horizontal chrome a LEFT-docked toolbar adds; 0 when hidden or docked
  # elsewhere. Folded into _chromeWidth below.
  _leftDockThickness: ->
    if @_dockedToolbarShowing() and @toolbar.dockSide == 'left'
      @toolbar.dockThickness + @padding
    else
      0

  # Frame chrome WIDTH -- everything that is not content width: the side
  # paddings plus a left-docked shown toolbar. The width sibling of
  # _chromeHeight, and the ONE home the measures and the arrange both read
  # (§6.1 rule 1): availableWidthForContents, the width negotiation and the
  # first-placement hug all route through it.
  _chromeWidth: ->
    2 * @padding + @_leftDockThickness()

  # (U2) The first-placement WIDTH negotiation, as a PURE function of the spec's
  # preferredStartingWidth sentinels -- ONE home for the measure's pre-capture branch (below)
  # and the arrange's first-placement branch: they MUST agree (assessment §6.1 rule 1), or a
  # parent measuring this window mid-construction diverges from what the window's own arrange
  # then applies -- that divergence (the old flag guard reported the CURRENT, pre-negotiation
  # extent) was the root of the nested-window settle re-visits. availW = the window width the
  # caller proposes (the arrange passes its own current width).
  _negotiatedContentWidth: (availW) ->
    spec = @contents.layoutSpecDetails
    if spec.preferredStartingWidth == FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW
      # (U3-C) "the size I have now" through the content's preferredExtent, not its raw
      # width(): identical for plain content (base preferredExtent IS the applied extent),
      # but content whose OWN first placement is pending (a nested window) answers with the
      # extent that placement will produce -- so this window places it at its FINAL size in
      # one shot and the settle loop's injection never has to re-visit us.
      @contents.preferredExtent().x
    else if spec.preferredStartingWidth == FrameContentLayoutSpec.DONT_MIND
      availW - @_chromeWidth()
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
      @contents.layoutSpecDetails.getWidthInStack availW - @_chromeWidth()

  # (U3-C) A window whose first placement is PENDING (content spec uncaptured) answers
  # preferredExtent with the extent that placement will produce -- the PURE mirror of the
  # arrange's first-placement branch (width: the negotiation + padding + the not-freefloating
  # clamp; height: the pre-capture measure at that width, which mirrors the height sentinels).
  # A collapsed-content or captured (steady-state) window IS its applied extent, like any
  # plain widget. Recursion (a window in a window in ...) terminates at plain content.
  preferredExtent: ->
    spec = @contents?.layoutSpecDetails
    if !spec? or spec.desiredWidth? or @contents.collapsed then return @extent()
    if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and spec.preferredStartingWidth != FrameContentLayoutSpec.DONT_MIND
      # the width hug (DESKTOP windows only -- §9.7-Q, same own-layoutSpec predicate as the
      # arrange's first-placement branch, incl. the not-recursively-freefloating min-clamp;
      # keep the two in lockstep)
      windowWidth = @_negotiatedContentWidth(@width()) + @_chromeWidth()
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
        if spec.preferredStartingHeight == FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW
          # (U3-C) through preferredExtent, not raw height() -- see _negotiatedContentWidth
          desiredHeight = @contents.preferredExtent().y
          if !@recursivelyAttachedAsFreeFloating()
            desiredHeight = Math.min desiredHeight, @height() - chrome
        else if spec.preferredStartingHeight == FrameContentLayoutSpec.DONT_MIND
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
        recommendedElementWidth = spec.getWidthInStack(availW - @_chromeWidth())
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
    super()
    @labelContent = opts.labelContent ? "my window"
    @closeButton = opts.closeButton

    @_deriveAndSetBodyAppearance()

    @strokeColor = Color.create 125,125,125
    @tight = true

    @defaultContents = new FrameContentsPlaceholderText
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
      @label.setText @_titleForContents @contents

    # settled-after-new: SETTLE the default extent as the constructor's LAST act (was
    # @_applyExtent, which left a pending re-fit -- and, for default contents, the
    # _setEmptyWindowLabelNoSettle label too -- so `new FrameWdgt` returned UNsettled). This flushes both.
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
    # specialFrameReferenceShortcut instead of `@contents instanceof ScriptWdgt`.
    # (type-test-elimination campaign)
    widgetToAdd = @contents?.specialFrameReferenceShortcut?(@, referenceName)
    if widgetToAdd?
      # this "add" is going to try to position the reference
      # in some smart way (i.e. according to a grid)
      placeToDropItIn.add widgetToAdd
      widgetToAdd.setExtent WidgetHolderWithCaptionWdgt.standardDesktopIconExtent()
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

  # The window title a (re)mounted content yields -- ONE home for the ctor and
  # _addNoSettle title sites. A framed CITIZEN (a FrameWdgt subclass that IS its
  # kind -- Frame-model plan §5.B) overrides this to its own colloquialName: the
  # kind names the window, not the generic payload inside it.
  _titleForContents: (aWdgt) ->
    titleToBeSet = aWdgt.colloquialName()
    if titleToBeSet == "window"
      titleToBeSet = "window with another " + titleToBeSet
    if titleToBeSet == "internal window"
      titleToBeSet = "window with an " + titleToBeSet
    titleToBeSet

  setTitle: (newTitle) ->
    @label.setText @contents.colloquialName() + ": " + newTitle

  setTitleWithoutPrependedContentName: (newTitle) ->
    @label.setText newTitle

  representativeIcon: ->
    if @contents == @defaultContents
      return super
    else
      return @contents.representativeIcon()

  # paintingOverlay() capability chain (§5.D): a paint toolbar resolving its
  # injection target at press time asks the frame, which asks its content
  # (container -> canvas -> glass). Frames over non-paintable content answer
  # nil through the ?. -- and a FLOATING paint toolbar's own frame answers nil
  # too (its content IS the toolbar), which is what routes the floating press
  # to the focus pointer instead (PaintToolbarWdgt.resolveInjectionTarget).
  paintingOverlay: ->
    @contents?.paintingOverlay?()

  # The close-from-bar POLICY (Frame-model plan §5.E E2): a tracked field replaces
  # the per-instance `closeFromFrameBar = -> …` monkey-patches the sample/info
  # factories used to inject (InfoDocs._buildInfoDocNextTo's own TODO:
  # "should be done using a flag ... the source is not tracked"). 'saveOrAsk'
  # (default) runs the per-kind hook below; 'close'/'destroy' are the one-shot
  # sample/info behaviours -- a property, not injected code.
  closeFromFrameBarPolicy: 'saveOrAsk'

  closeFromFrameBar: ->
    switch @closeFromFrameBarPolicy
      when 'close' then @close()
      when 'destroy' then @destroy()
      else @_closeFromFrameBarWhenSaveOrAsk()

  # The 'saveOrAsk' hook. Base = a plain frame lets its CONTENT decide how to
  # close (ScriptWdgt/ErrorsLogViewer/BasementWdgt/generic windows, via
  # Widget.closeFromContainerFrame); the document/panel citizens override this
  # with @_saveOrAskThenCloseCitizen, and FolderWindowWdgt with its own variant.
  _closeFromFrameBarWhenSaveOrAsk: ->
    @contents?.closeFromContainerFrame @

  # Shared save-or-ask-then-close for the document/panel citizens (§5.E E2: the
  # body was duplicated verbatim on DocumentWdgt + GenericPanelWdgt). Template
  # method: it calls the per-kind @hasStartingContentBeenChangedByUser(). No real
  # contents to save -> fullDestroy; else the save prompt; else just close.
  _saveOrAskThenCloseCitizen: ->
    # public-call-sanctioned + nosettle-sanctioned: this IS the close-from-bar
    # action (a top-level bar-button event handler); @fullDestroy / @close are the
    # public self-settling close verbs it legitimately triggers -- exactly as the
    # public closeFromFrameBar it was extracted from did (this dedup only moved the
    # shared body down a level). Reaching the NoSettle cores would leave the world
    # unsettled after a top-level bar press.
    if !@hasStartingContentBeenChangedByUser() and !world.anyReferenceToWdgt @
      @fullDestroy()
    else if !world.anyReferenceToWdgt @
      prompt = new SaveShortcutPromptWdgt @, @
      prompt.popUpAtHand()
    else
      @close()

  # The title-bar buttons announce their press to their holder (the bar, which
  # forwards here) instead of testing `@parent instanceof FrameWdgt` themselves
  # -- the frame owns what its bar buttons MEAN. closeButtonInBarPressed mirrors
  # the old button branch exactly (a contents-bearing window closes from the
  # bar, an empty one just closes); a non-bar container of a close button has no
  # such method, so that button falls back to Widget.close().
  # (type-test-elimination campaign; A2b routes the asks through FrameBarWdgt.)
  closeButtonInBarPressed: ->
    if @contents? then @closeFromFrameBar() else @close()

  editButtonInBarPressed: ->
    @contents?.editButtonPressedFromFrameBar?()

  collapseButtonInBarPressed: ->
    @contents.collapse()

  uncollapseButtonInBarPressed: ->
    @contents.unCollapse()

  # duringReInflation: true ONLY for the one synchronous re-fit inside _reactToChildUnCollapsed --
  # the content must KEEP its just-restored extent instead of being stretched to a mid-restore
  # window height; every other caller (incl. the preferredExtentForWidth measure) takes the
  # default false. History/rationale: docs/archive/upedge-endgame-plan.md §9-E4.
  contentsRecursivelyCanSetHeightFreely: (duringReInflation = false) ->
    # was `!(@contents instanceof FrameWdgt)` (type-test-elimination campaign)
    if !@contents.isFrame?()
      # FIT_BOX_TO_TEXT content drives its OWN height from its wrapped text, so the
      # window must FOLLOW that height (shrinking when a widen re-wraps to fewer
      # lines), not stretch the content to fill a freely-dragged height. A
      # SimpleTextWdgt already forces this via layoutSpecDetails.canSetHeightFreely
      # = false in its ctor; keying off the mode generalizes it to any contained
      # TextWdgt (a non-text content has no fittingSpec, so this is a no-op for it).
      if @contents.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT then return false
      return (@contents.layoutSpecDetails.canSetHeightFreely and !@contents.isInCollapsedSubtree()) and !duringReInflation
    return @contents.contentsRecursivelyCanSetHeightFreely()

  recursivelyAttachedAsFreeFloating: ->
    if @isFreeFloating()
      return true

    if @parent?
      # was `@parent instanceof FrameWdgt` (type-test-elimination campaign)
      if @parent.isFrame?()
        return @parent.recursivelyAttachedAsFreeFloating()

    return false


  # A window is the DELIBERATE-EMBED payload class (drag-embed spec §4): dropping it into a container
  # must be armed by a dwell (spec §6), so windows are never nested by accident during the constant
  # move-a-window gesture. (Overrides Widget's plain default.)
  requiresDeliberateEmbedding: ->
    return true

  # A frame does NOT impose its ratio on dropped children (was the
  # `!(whereIn instanceof FrameWdgt)` exclusion in the ratio mixin /
  # Example3DPlotWdgt) -- but it DOES release the constraint when a child is
  # grabbed back out, exactly as a stack does. The ratio mixin queries the
  # holder via ?(), so an absent release method would silently stop releasing.
  # (type-test-elimination campaign; the release was inherited from the stack
  # until the A2a de-inherit made it explicit.)
  imposesRatioConstraintOnDroppedChildren: ->
    false

  releasesRatioConstraintOnGrabbedChildren: ->
    true

  # Re-title the (content-less) window through the NON-settling label core (hence the NoSettle
  # name): reached either during construction (orphan -> deferred) or from _resetToDefaultContents
  # inside a close/destroy settle, so the enclosing settle flushes it -- a self-settling setText
  # would open a nested settle mid-pass. (The label is FIT_TEXT_TO_BOX, so the text swap changes
  # no geometry anyway; @_changed() in the core repaints it.)
  _setEmptyWindowLabelNoSettle: ->
    if @isInternal()
      @label._setTextNoSettle "empty internal window"
    else
      @label._setTextNoSettle "empty window"

  # Polymorphic replacement for `instanceof FrameWdgt`: lets Widget / the smart-placer
  # ask "are you a window?" without naming this subclass. Defined ONLY here -- there is NO
  # Widget base default (Widget is the God class under decomposition), so every call site
  # dispatches via `?()` and a non-window answers undefined (falsy). (type-test-elimination campaign)
  isFrame: -> true

  colloquialName: ->
    if @isInternal()
      return "internal window"
    else
      return "window"

  # The re-fit chokepoint (the `_reLayoutChildren?` size-tracking marker keys off this
  # definition): re-fit chrome + content via the frame's own arrange below.
  _reLayoutChildren: ->
    @_positionAndResizeChildren()

  # Stack-pattern deferred re-fit (A2a: was inherited from the stack): super applies my
  # own bounds first (bounds-first rule), then the arrange, then re-place the
  # corner-internal overlays at the FINAL frame -- the arrange may have re-committed my
  # own height after super's corner tail already placed them (idempotent when not).
  _reLayout: (newBoundsForThisLayout) ->
    super
    @_reLayoutChildren()
    @_reLayoutCornerInternalChildren()

  # Pinned false, NOT derived: defining _reLayout above would flip the derived answer
  # and mis-route the two read sites (_setWidthSizeHeightAccordingly's invalidate +
  # subWidgetsMergedFullBounds) -- the same pin the stack carries.
  implementsDeferredLayout: ->
    false

  # The width this frame offers its content -- consumed by the content's spec
  # (FrameContentLayoutSpec / VerticalStackLayoutSpec call
  # `@stack.availableWidthForContents()`, and for frame content that "@stack" IS
  # this frame). (A2a: was inherited from the stack.) Routed through
  # _chromeWidth so a left-docked shown toolbar narrows the content everywhere
  # the specs read it (§5.C).
  availableWidthForContents: ->
    @width() - @_chromeWidth()

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
  # FrameWdgt._positionAndResizeChildren. Narrowing the pre-capture term to own-FF is what
  # retires the LAST nested-window settle re-visits: a first-placement inner window now settles
  # inside its outer's arrange instead of on its own later turn + an up-edge re-visit of the
  # outer (up-edge endgame V1-b, docs/archive/upedge-endgame-plan.md §9). Absent (undefined via ?()) on
  # a stack, whose synchronous re-lay keeps its container-assigned width.
  _reLayoutMayResizeOwnWidth: ->
    @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and !@contents?.layoutSpecDetails?.desiredWidth?

  add: (aWdgt, position = nil, layoutSpec, beingDropped, notContent) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped, notContent: notContent

  # _addNoSettle -- the non-settling core of add() (mirrors Widget.add/_addNoSettle).
  # Folds in the frame's content bookkeeping (title, @contents swap, spec init +
  # first-placement re-arm) so the build/teardown chain (_buildAndConnectChildrenNoSettle)
  # adds chrome + content WITHOUT flushing layouts: super reaches Widget._addNoSettle
  # directly (A2a de-inherit), all non-settling. Adding @contents through THIS core (vs
  # the bare base _addNoSettle) is exactly what keeps the content wired by the deferred re-fit.
  _addNoSettle: (aWdgt, opts = {}) ->
    position = opts.position
    layoutSpec = opts.layoutSpec
    beingDropped = opts.beingDropped
    notContent = opts.notContent
    # the polymorphic strip-spacing hook (a base no-op; some widget types override
    # it) runs on every add, mirroring the stack's add core.
    aWdgt._resizeToWithoutSpacing()
    # caret + handle are the layout decorations (was their two instanceof) (type-test-elimination campaign)
    unless notContent or aWdgt.isLayoutInert?()
      # re-title through the NON-settling label core: _addNoSettle already runs inside the
      # add's settle, so the title change rides that flush instead of opening a nested one.
      @label._setTextNoSettle @_titleForContents aWdgt
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
      # Init the content's FrameContentLayoutSpec up-front -- the pre-fit used to do this implicitly
      # via _positionAndResizeChildren, so without it the deferred re-fit would deref an uninitialised spec.
      aWdgt.initialiseDefaultFrameContentLayoutSpec() unless aWdgt.layoutSpecDetails instanceof FrameContentLayoutSpec
      # (U2) re-arm the first-placement ONE-SHOT for this mount: content (re)mounted into a
      # window re-negotiates its placement. The old model re-ran the capture via
      # the contentNeverSetInPlaceYet flag; the CAPTURE is now itself the latch, so un-latch it
      # (a fresh spec is already unlatched; this covers content carrying a spec from a prior
      # life) -- but NOT for a same-widget chrome-rebuild re-add (§9.7-Q above): the standing
      # capture is exactly the placement this mount already has.
      aWdgt.layoutSpecDetails.desiredWidth = nil unless isSameContentRemount
      super aWdgt, position: position, layoutSpec: LayoutSpec.ATTACHEDAS_FRAME_CONTENT, beingDropped: beingDropped
    else
      super aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped
    @resizer?._moveInFrontOfSiblings()

  # (A2a, was inherited from the stack) membership-change re-fit -- same
  # absorb-or-refit contract as the inline in _reactToChildDropped below.
  _reactToChildRemoved: (child) ->
    return if @parent?._reLayOutAfterContainedPanelChange?()
    @_reFitContainer()

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

      # tear down the edit button through the bar's non-settling core: this hook fires inside
      # collapse's settle, so the public self-settling destroy() would throw under the
      # single-mutation tier. The enclosing collapse settle covers the re-layout.
      @bar._destroyEditButtonNoSettle()
      @editButton = nil
      # a collapsed window is JUST its titlebar -- the docked toolbar hides with
      # the content (restored per the content's mode on uncollapse below)
      @toolbar?._collapseNoSettle()

  _beforeChildUnCollapsed: (child) ->
    if child == @contents
      @widthWhenCollapsed = @width()
      if @contents.dragsDropsAndEditingEnabled
        @toolbar?._unCollapseNoSettle()

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
      @_applyExtent @extentWhenCollapsed
      @contents._applyExtent @contentsExtentWhenCollapsed
      if @widthWhenUnCollapsed?
        @_applyWidth @widthWhenUnCollapsed
      # layout-apply-sanctioned: uncollapse re-fit (must stay synchronous, residuals-audit fam 4).
      # duringReInflation=true -- the content keeps its just-restored extent; see
      # contentsRecursivelyCanSetHeightFreely. (Direct arrange call: _reLayoutChildren is exactly
      # this dispatch, and only THIS caller carries the mode.)
      @_positionAndResizeChildren true
      @_rememberFractionalSituationInHoldingPanel()
      @_invalidateLayout()   # (property sub-seam deletion) uniform climb replaces the property re-fit seam
      @parent.parent._invalidateLayout() if @_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()   # (proper-layouts) reach the scroll-panel grandparent; the window's bare climb is dropped at the non-tracking @contents PanelWdgt

  # the content owns the slot's occupant, so a content CHANGE retires it -- the
  # rebuild then makes the NEW content's variant (or none)
  _destroyToolbarNoSettle: ->
    @toolbar?._destroyNoSettle()
    @toolbar = nil

  # A framed CITIZEN's _resetToDefaultContents consults this flag (§5.B): a
  # payload dying because the WHOLE frame is going away must NOT be replaced --
  # a citizen constructs a FRESH payload per reset, and each fresh child
  # re-enters the destroy-until-empty iteration, an unbounded rebuild-destroy
  # loop. Set here at the subtree's destroy ENTRY so every teardown path
  # (resetWorld's fullDestroyChildren, a direct fullDestroy, the basement)
  # covers the whole recursion.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super

  _resetToDefaultContents: ->
    # public-call-sanctioned: enableDrops is the trivial public drop-acceptance setter (macros and
    # cross-object code drive it) — settle-free, consciously reused here.
    @enableDrops()
    @_destroyToolbarNoSettle()
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
    @contents?._reactToHolderFrameDropped? whereIn

  _reactToBeingGrabbed: (whereFrom) ->
    @contents?._reactToHolderFrameGrabbed? whereFrom

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
      @bar._setAppearanceAndColorOfTitleBackground()
      @_changed()

  _reactToChildDropped: (theWidget) ->
    @_destroyToolbarNoSettle()
    @contents = theWidget
    # (A2a, was the stack super) membership-change re-fit: if my container absorbs the
    # change (a scroll panel re-fits me + its scrollbars), skip my own re-fit; else it
    # DEFERS to the cycle. My own bookkeeping below runs either way, as it always did.
    unless @parent?._reLayOutAfterContainedPanelChange?()
      @_reFitContainer()
    # public-call-sanctioned: disableDrops is the trivial public drop-acceptance setter (macro-visible
    # behaviour: an occupied window stops accepting drops) — settle-free, consciously reused here.
    @disableDrops()
    # _reactToChildDropped runs inside the drop's single settle, so rebuild through the NON-settling core
    # (not the public _buildAndConnectChildren wrapper, which would re-enter the flush guard) -- same
    # as the _resetToDefaultContents lifecycle path above.
    @_buildAndConnectChildrenNoSettle()

  # The window BODY appearance half of the internal/external skin (the title-bar half is
  # FrameBarWdgt._setAppearanceAndColorOfTitleBackground): flat RectangularAppearance when nested (internal),
  # boxy BoxyAppearance when free on the desktop (external). Derived from isInternal (parentage),
  # set at construction and re-derived on every re-parenting by _reactToBeingAdded.
  _deriveAndSetBodyAppearance: ->
    if @isInternal()
      @appearance = new RectangularAppearance @
    else
      @appearance = new BoxyAppearance @

  # ONE settle around the whole rebuild via the single-mutation tier (_settleLayoutsAfter). The
  # core is non-settling: it adds the bar (whose pieces build through the bar's own non-settling
  # core) AND the content through @_addNoSettle, so nothing self-settles per add and nothing
  # re-fits the HALF-built window mid-loop -- the window's content bookkeeping rides along in
  # FrameWdgt._addNoSettle. The single settle runs AFTER the core: O(1) relayouts.
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

    if !@bar?
      @bar = new FrameBarWdgt @
      @_addNoSettle @bar, notContent: true
    # the bar builds/keeps its pieces (label rebuilt every time, the rest
    # keep-if-exist); @closeButton is the ctor-supplied one on the first build
    # (FolderWindowWdgt injects its own), then the alias of the bar's.
    @bar._buildAndConnectPiecesNoSettle @labelContent, @closeButton
    # re-point the aliases at the (possibly fresh) pieces -- see the field block.
    @titlebarBackground = @bar.titlebarBackground
    @label = @bar.label
    @closeButton = @bar.closeButton
    @collapseUncollapseSwitchButton = @bar.collapseUncollapseSwitchButton

    @_createAndAddEditButton()

    @_addNoSettle @contents

    # the toolbar-slot occupant (keep-if-exist like the bar pieces; the
    # content-CHANGE points destroy it first so a new content gets its own
    # variant). A framed CITIZEN declares its kind's variant itself (§5.B);
    # a plain frame asks the content it wraps. Born collapsed when viewing.
    if !@toolbar?
      @toolbar = @buildToolbar?() ? @contents?.buildToolbar?()
      if @toolbar?
        @_addNoSettle @toolbar, notContent: true
        if !@contents.dragsDropsAndEditingEnabled
          @toolbar._collapseNoSettle()

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
      # the toolbar-slot follows the mode: editing shows the docked toolbar.
      # NoSettle core -- this protocol is driven from inside the content's
      # enable/disable settle; the collapse cores invalidate, that flush covers it.
      @toolbar?._unCollapseNoSettle()
      # a mode-reactive toolbar (PaintToolbarWdgt re-arms/disarms its tools,
      # §5.D) rides the SAME protocol; the hooks transition-guard themselves
      # because this reflector is idempotently re-driven (e.g. the edit-button
      # recreate on window uncollapse).
      @toolbar?.reactToEditModeInFrame?()

  showViewModeInBar: ->
      @editButton?.showEyeGlyph()
      @toolbar?._collapseNoSettle()
      @toolbar?.reactToViewModeInFrame?()

  # Frame-level edit-mode switch (§5.B): route through the PAYLOAD's own core --
  # the payload owns the canonical dragsDropsAndEditingEnabled flag and its core
  # does the recursive child locking/unlocking -- then flip my own bar (I am the
  # bar owner; the payload's `@parent?.show*ModeInBar?()` notify reaches me too,
  # idempotently). The Widget base core would act SHALLOWLY on @contents (one
  # child level, no payload-specific propagation) and notify only @parent. My
  # own flag mirrors the payload's so a frame nested as another frame's content
  # keeps Widget.editButtonPressedFromFrameBar's toggle direction honest.
  enableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle triggeringWidget

  _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    @dragsDropsAndEditingEnabled = true
    @contents?._enableDragsDropsAndEditingNoSettle @
    @showEditModeInBar()

  disableDragsDropsAndEditing: (triggeringWidget) ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle triggeringWidget

  _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
    @dragsDropsAndEditingEnabled = false
    @contents?._disableDragsDropsAndEditingNoSettle @
    @showViewModeInBar()

  _createAndAddEditButton: ->
    # public-call-sanctioned: showEditModeInBar/showViewModeInBar are the window-bar mode PROTOCOL —
    # content widgets drive them cross-object (`@parent?.showEditModeInBar?()`), so they stay public.
    # A framed CITIZEN provides the amenities itself (its payload may be a plain
    # Widget container, §5.B); a plain frame asks the content it wraps.
    if (@providesAmenitiesForEditing or @contents?.providesAmenitiesForEditing) and !@editButton?
      @editButton = @bar._createAndAddEditButtonNoSettle()

      if @contents.dragsDropsAndEditingEnabled
        @showEditModeInBar()
      else
        @showViewModeInBar()

  # (A2a, was inherited from the stack) when THIS frame is another frame's CONTENT (a
  # window nested in a window), its spec pins canSetHeightFreely = false on top of the
  # base init -- byte-what the stack's override did.
  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  # The re-fit chokepoint for a window (no scrollbars): re-fit chrome + content. Reached via the
  # inherited SimpleVerticalStackPanelWdgt._reLayoutChildren, which dispatches back here.
  # duringReInflation: passed true ONLY by _reactToChildUnCollapsed's synchronous re-fit -- see
  # contentsRecursivelyCanSetHeightFreely (up-edge endgame V1-d).
  _positionAndResizeChildren: (duringReInflation = false) ->

    closeIconSize = FrameWdgt.CLOSE_ICON_SIZE

    stackHeight = 0

    if @contents? and !@contents.collapsed
      # Order-independent spec init: also (re)init when the content lacks a FrameContentLayoutSpec,
      # not only when its layoutSpec tag is unset. With the on-add pre-fit removed (deferred layout),
      # super sets the layoutSpec tag to ATTACHEDAS_FRAME_CONTENT BEFORE this deferred re-fit runs,
      # so the old tag-only gate would skip init and this would deref an uninitialised/stack-typed spec.
      if @contents.layoutSpec != LayoutSpec.ATTACHEDAS_FRAME_CONTENT or !(@contents.layoutSpecDetails instanceof FrameContentLayoutSpec)
        @contents.initialiseDefaultFrameContentLayoutSpec()
        @contents._setLayoutSpec LayoutSpec.ATTACHEDAS_FRAME_CONTENT

      # (U2) the first-placement ONE-SHOT is CONTENT-owned: an uncaptured spec (desiredWidth
      # unset -- fresh init above, or re-armed on content (re)mount in _addNoSettle) selects
      # the negotiation branch ONCE; captureInitialPlacement below is itself the latch. Computed
      # BEFORE the capture latches, and used by BOTH the width branch here and the height branch below.
      firstPlacement = !@contents.layoutSpecDetails.desiredWidth?

      if firstPlacement
        recommendedElementWidth = @_firstPlacementContentWidth @width()
        if @layoutSpec == LayoutSpec.ATTACHEDAS_FREEFLOATING and @contents.layoutSpecDetails.preferredStartingWidth != FrameContentLayoutSpec.DONT_MIND
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
            windowWidth = recommendedElementWidth + @_chromeWidth()
          else
            windowWidth = Math.min @width(), recommendedElementWidth + @_chromeWidth()
          @_applyExtentBase new Point windowWidth, @height()

        @contents.layoutSpecDetails.captureInitialPlacement @contents, @


      else
        recommendedElementWidth = @contents.layoutSpecDetails.getWidthInStack()

      partOfHeightUsedUp = @_chromeHeight @contents.layoutSpecDetails

      # this re-layouts each widget to fit the width.
      if firstPlacement
        if @contents.layoutSpecDetails.preferredStartingHeight == FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW
          # (U3-C) through preferredExtent, not raw height() -- see _negotiatedContentWidth
          desiredHeight = @contents.preferredExtent().y
          if !@recursivelyAttachedAsFreeFloating()
            desiredHeight = Math.min desiredHeight, @height() - partOfHeightUsedUp
          @contents._applyWidth recommendedElementWidth
          @contents._applyHeight desiredHeight
        else if @contents.layoutSpecDetails.preferredStartingHeight == FrameContentLayoutSpec.DONT_MIND
          @contents._applyWidth recommendedElementWidth
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents._applyHeight desiredHeight
        else
          # Path B: the sizing HANDS its resulting height back -- no read-back of @contents.height().
          desiredHeight = @contents._setWidthSizeHeightAccordingly recommendedElementWidth

        # (no flag clear -- captureInitialPlacement above latched the one-shot)
      else
        # Path B: take the resulting height from the sizing call, not a read-back of @contents.height().
        desiredHeight = @contents._setWidthSizeHeightAccordingly recommendedElementWidth

        # (proper-layouts residual, 2026-07-01) Single-pass fit-to-content: settle a NON-deferred size-tracking
        # container content (a stack) NOW, synchronously, so I fit its FINAL height in THIS pass. Otherwise the
        # content settles independently LATER (as its own settle-loop chain-top) and its settle-time re-fit
        # re-VISITS me to re-fit -- the residual FrameWdgt content-negotiation re-visits. This is the SAME
        # _reLayout() the settle loop would call on the content's own turn, pulled one iteration earlier, so it
        # is byte-exact. _setWidthSizeHeightAccordingly already settles DEFERRED-layout content (a scroll panel);
        # a stack pins implementsDeferredLayout false, so we settle it here. EXCLUDES content that re-fits its OWN
        # width when re-laid (a nested window, _reLayoutMayResizeOwnWidth): settling THAT early re-negotiates its
        # width and diverges from its normal independent settle -- its re-visit is a GENUINE width<->height
        # convergence, correctly left to the settle loop.
        if @contents._reLayoutChildren? and not @contents.implementsDeferredLayout() and not @contents.layoutIsValid and not @contents._reLayoutMayResizeOwnWidth?()
          @contents._reLayout()
          desiredHeight = @contents.height()

        if @contentsRecursivelyCanSetHeightFreely duringReInflation
          desiredHeight = Math.round @height() - partOfHeightUsedUp
          @contents._applyHeight desiredHeight

      # contained text that has OPTED INTO FIT_BOX_TO_TEXT (a SimpleTextWdgt,
      # or any bare TextWdgt put into that mode) fits its BOX to the TEXT: it wraps
      # to the width we set generically above and its height follows the wrapped
      # content. We RESPECT the mode rather than imposing it, so the empty-window
      # placeholder — a TextWdgt that stays FIT_TEXT_TO_BOX — is left alone. Here we
      # only (re)assert soft-wrap (the actual reflow is driven by the generic
      # width-set above → the widget's own FIT_BOX_TO_TEXT _reLayoutSelf).
      if @contents.fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
        @contents.softWrap = true

      # centre the content in its REGION -- the frame width minus a left-docked
      # shown toolbar (identical to the whole width when none is docked left)
      contentRegionLeft = @left() + @_leftDockThickness()
      leftPosition = contentRegionLeft + Math.floor (@width() - @_leftDockThickness() - recommendedElementWidth) / 2

      @contents._applyMoveTo new Point leftPosition, @top() + @_titlebarHeight() + @_topDockThickness() + @padding
      stackHeight += desiredHeight

    if @contents? and @contents.collapsed
      partOfHeightUsedUp = @_titlebarHeight()


    newHeight = stackHeight + partOfHeightUsedUp

    @_applyExtentBase new Point @width(), newHeight

    # the title strip: hand the bar its bounds (my top strip at the FINAL width --
    # the first-placement hug above may have just re-committed it); the bar's own
    # arrange places the five pieces at the same absolute pixels the flat chrome had.
    if @bar? and @bar.parent == @
      barBounds = new Rectangle @position()
      barBounds = barBounds.setBoundsWidthAndHeight @width(), @_titlebarHeight()
      @bar._reLayout barBounds

    # the toolbar-slot: place the docked toolbar in the padded body, under the
    # bar -- TOP: a full-available-width strip the content then starts below;
    # LEFT: a column sharing the content's vertical span (stackHeight is the
    # content height this pass just derived). Driven SYNCHRONOUSLY via
    # _reLayout bounds, the same drive as @bar above -- a scroll panel's
    # _reLayout applies its own bounds THEN re-fits its contents+scrollbars, so
    # a width change that re-wraps the tool grid converges IN THIS PASS. (A
    # bare _applyMoveTo/_applyExtent drive commits the viewport but re-fits
    # nothing, leaving the inner panel at a stale wrap height -- fg census
    # caught exactly that: ToolPanel 75 tall inside the 40 strip after a
    # narrow->wide window resize.)
    if @_dockedToolbarShowing()
      toolbarBounds = new Rectangle new Point @left() + @padding, @top() + @_titlebarHeight() + @padding
      if @toolbar.dockSide == 'top'
        toolbarBounds = toolbarBounds.setBoundsWidthAndHeight @width() - 2 * @padding, @toolbar.dockThickness
      else
        toolbarBounds = toolbarBounds.setBoundsWidthAndHeight @toolbar.dockThickness, stackHeight
      @toolbar._reLayout toolbarBounds

    # TODO there is *already* a way to make handles do the right thing, and that is
    # to have this sort of code in a _reLayout function, and calling super in there,
    # where the base Windget._reLayout takes care of everything that has a
    # corner or edge internal layout, like handles. This should work the same way i.e.
    # this code should not be here.
    if @resizer?.parent == @
      @resizer.__commitMoveTo new Point @right() - WorldWdgt.preferencesAndSettings.handleSize - @padding, @bottom() - WorldWdgt.preferencesAndSettings.handleSize - @padding
