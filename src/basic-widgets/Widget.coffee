# "Widget" is a more understandable name for the concept of "Morph"
# (from the Greek "shape" or "form"). A Widget is an interactive
# graphical object.
# (General information on the Morphic system
# can be found at http://wiki.squeak.org/squeak/30 )

# Widgets exist in a tree, rooted at a World or at the Hand.
# The widgets owns subwidgets. Widgets are drawn recursively;
# if a Widget has no owner it never gets drawn
# (but note that there are other ways to hide a Widget).

class Widget extends TreeNode

  # we want to keep track of how many instances we have
  # of each Widget for a few reasons:
  # 1) it gives us an identifier for each Widget
  # 2) profiling
  # 3) generate a uniqueIDString that we can use
  #    for example for hashtables
  # each subclass of Widget has its own static
  # instancesCounter which starts from zero. First object
  # has instanceNumericID of 1.
  # instanceNumericID is initialised in the constructor.
  @instancesCounter: 0
  # lastBuiltInstanceNumericID is the source of instanceNumericID (see assignUniqueID). Unlike
  # instancesCounter (the never-reset lifetime/profiling count) it is RESET to 0 per widget class
  # at ResetWorld (WorldWdgt), so SystemTest widget IDs restart deterministically each test.
  @lastBuiltInstanceNumericID: 0
  instanceNumericID: 0

  # Serialization: own properties the serializer must SKIP (frame timing + the
  # WorldWdgt.geometryVersion-keyed derived geometry caches — all re-derived on demand
  # after a restore). Merged up the class chain by Serializer.transientsForClass; a
  # subclass ADDS to this list. See docs/architecture/serialization-duplication-reference.md §5.
  @serializationTransients: [
    # frame timing for throttled stepping (fps > 0, non-synchronised: BlinkerWdgt, the video
    # widgets) — wall-clock, so it cannot ride a file. The DUPLICATOR must COPY it, and does:
    # clones skip the constructor (the Date.now() seed never runs), so a dropped lastTime would
    # leave _runChildrensStepFunction computing NaN milliseconds-remaining and the clone would
    # never step; the copied value keeps a throttled clone's cadence in phase with its original.
    "lastTime"
    # the back-buffer render cache (BackBufferMixin) — rebuilt on demand by
    # _createRefreshOrGetBackBuffer, so it is never serialized; the restored widget
    # re-renders it on its first paint. The shadow-silhouette twin follows the same rule.
    "backBuffer", "backBufferContext"
    "_backBufferShadowSilhouette", "_backBufferShadowSilhouetteSource"
    "cachedFullBounds", "checkFullBoundsCache", "childrenBoundsUpdatedAt"
    # the root() cache (TreeNode) — the ONE cache pair that was missing here: a STALE
    # cachedRoot can point into a subtree destroyed since the last structure change
    # (root() itself never reads it stale — it checks structureVersion — but the
    # serializer walks the raw field), so capture-mode world snapshots pulled dead
    # subtrees in and crashed on their unserializable handler functions (found by the
    # bin/shelf probe's mid-sort snapshot check, 2026-07-23). Recomputed on demand.
    "cachedRoot", "checkRootCache"
    # the firstParentClippingAtBounds() cache (TreeNode) — the SAME identity-cache hazard as
    # cachedRoot above (it points at a WIDGET, and the serializer walks the raw field), found
    # missing here by the 2026-08-20 twins-rider review while fixing the Duplicator's copy of
    # the whole cache family. Recomputed on demand.
    "cachedFirstParentClippingAtBounds", "checkFirstParentClippingAtBoundsCache"
    "cachedFullClippedBounds", "checkFullClippedBoundsCache"
    "cachedVisibleBasedOnIsVisibleProperty", "checkVisibleBasedOnIsVisiblePropertyCache"
    "cachedClippedThroughBounds", "checkClippedThroughBoundsCache"
    "cachedClipThrough", "checkClipThroughCache"
    "cachedIsInCollapsedSubtree", "checkIsInCollapsedSubtreeCache"
    # §4.4 island buffer cache source-lane fields: ephemeral per-frame paint state (a widget ref +
    # a virtual rect), consumed at flesh-out — never persist them (a snapshot must not pin an island).
    # The Duplicator drops them too (a clone never painted into any buffer; a copied stash would
    # deposit a false "vacated" rect onto the ORIGINAL's island and pin it — see _cloneContentInto).
    "_islandBufferSourceIsland", "_islandBufferSourceVirtualRect"
    # flush-scoped settle-engine bookkeeping (ordered down-walk Stage B1): the flag mirrors the
    # work-list's lifecycle and is cleared when the drain completes, so persisting it would only
    # bake a stale own-property into saved files (a restored flag has no matching work-list entry).
    # Duplication needs no handling: outside a layout flush every flag is false
    # (__flagHasDirtyDescendantUpwards is flush-local scratch) and a copy cannot run mid-flush
    # (recalculateLayouts' re-entrancy guard), so a field-copy only ever copies false.
    "hasDirtyDescendant"
    # per-frame damage-rect bookkeeping — every field pairs with world-level per-flush
    # state that is never serialized: the _changed()/_fullChanged() dedupe flags mirror membership
    # in world.widgetsWithMaybeChanged(Full)PaintBounds, the *WhenLastPainted footprints and the
    # src/dst indices are consumed by the flesh-out. A restored `true` dedupe flag has no matching
    # work-list entry, so it would permanently SUPPRESS damage reporting on the restored widget
    # (the menu a world snapshot was saved from came back leaving repaint artifacts when moved —
    # the triggering click's bringToForeground marks the menu damaged right before the save runs).
    # Duplication keeps the whole family consistent without dropping anything: world.noteWidgetCopied
    # (the alignCopiedWidgetToDamageInfoDataStructures aligner) inherits work-list membership, so a
    # copied true dedupe flag always has its matching entry; the copied *WhenLastPainted footprints
    # are truthful for a copy born at the original's position (worst case an over-erase of the
    # original's box — extra repaint, never lost damage); and the src/dst indices are flush-local
    # (_cleanupSrcAndDestRectsOfWidgets), undefined whenever a copy can run.
    "paintBoundsMaybeChanged", "fullPaintBoundsMaybeChanged"
    "clippedBoundsWhenLastPainted", "fullClippedBoundsWhenLastPainted"
    "srcDamageRectIndex", "dstDamageRectIndex"
  ]

  appearance: undefined

  # HOW ROUND MY CORNERS ARE, when I wear an appearance that has any. It lives HERE rather than on
  # BoxWdgt because it is part of the widget↔appearance contract and always was: every rounded
  # appearance reads `@widget.cornerRadius` unconditionally and supplies its own default when the
  # widget declares none (BoxyAppearance.getCornerRadius). Undeclared, that read was the only
  # statement of the contract — and its setter twin lived on ONE subclass, so the "corner radius..."
  # prompt and the `corner radius` pin that every rounded widget offers reached nothing on the
  # sixteen classes that are not BoxWdgts.
  #   `undefined` means "I have no opinion, use the shape's default" — which is why the field is not
  # given a number here.
  cornerRadius: undefined

  dragsDropsAndEditingEnabled: true

  # we conveniently keep all geometry information
  # into a single property (a Rectangle). Only
  # a few geometry-related methods should directly
  # access this property.
  bounds: undefined
  minimumExtent: undefined
  color: Color.create 80, 80, 80
  strokeColor: undefined
  texture: undefined # optional url of a fill-image

  lastTime: undefined
  # when you use the high-level geometry-change APIs
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it.
  # Here we store the desired extent and position.
  desiredExtent: undefined
  desiredPosition: undefined

  # 1: fully opaque, 0: fully transparent
  alpha: 1

  # the padding area of a widget is INSIDE a widget and
  # responds to mouse events.
  # The padding area should be empty, not drawn, except
  # for debugging or "interim painting" purposes such
  # as highlights.
  # The padding's purpose is to give the option to widgets
  # to accommodate for spacing between their contents and
  # their bounds, so to enable consecutive widgets to
  # have some spacing in between them.
  # Note that paddings of consecutive widgets do add up.
  # The padding area reacts to mouse events ONLY IF
  # it's filled with color. Otherwise, it doesn't.
  # This is consistent with the concept that Widgets only
  # react within their "filled" region.
  paddingTop: 0
  paddingBottom: 0
  paddingLeft: 0
  paddingRight: 0

  # backgroundColor and backgroundTransparency fill the
  # entire rectangular bounds of the widget.
  # I.e. they area they fill is not affected by the
  # padding or the actual design of the widget.
  backgroundColor: undefined
  backgroundTransparency: 1

  # for a Widget, being visible and collapsed
  # are two separate things.
  # isVisible means that the widget is meant to show
  #  as empty or without any surface. BUT the widget
  #  will still take the usual space.
  # Collapsed means that the widget, whatever its
  #  content or appearance or design, is not drawn
  #  on the desktop AND it doesn't occupy any space.
  isVisible: true
  collapsed: false

  # if a widget is a "template" it means that
  # when you floatDrag it, it creates a copy of itself.
  # it's a nice shortcut instead of doing
  # right click and then "duplicate..."
  isTemplate: false
  _acceptsDrops: false
  noticesTransparentClick: false
  fps: 0

  # usually Widgets can be detached from Panels
  # by grabbing them (there are exceptions, for example
  # buttons don't stick to the world but stick to Panels,
  # widget that "select" based on dragging such as the colour palette).
  # However you can get them to stick to Panels (and the desktop)
  # by toggling this flag
  isLockingToPanels: false
  # even if a Widget is locked to its parent (which is
  # the default) or locks to Panels (because isLockingToPanels is
  # set to true), it could be STILL BE dragged
  # (if any of its parents is loose).
  #
  # Setting this flag prevents that: a Widget rejecting
  # a drag can never be part of a chain that is dragged.
  # An example is buttons that are part of a compound Widget
  # (such as the Inspector):
  # in those cases you can never drag the compound Widget by
  # dragging a button (because it is a common behaviour to
  # "drag away" from a button to avoid actioning it when one
  # mousedowns on it). (Note however that buttons on the desktop
  # are draggable).
  # Another example are widgets like the colour palette where
  # users can drag the mouse on them to pick a color: it would be
  # weird if that caused a drag of anything.
  defaultRejectDrags: false

  # if you place a menu construction function here,
  # it gets the priority over the normal context
  # menu. This is done for example in the Inspector
  # panes, where the context menu is about running the
  # code contained in the text panel, rather than
  # to fiddle with the properties of the text panel
  # itself.
  overridingContextMenu: undefined

  # menu merging is useful when you want a "parent"
  # menu to take over the menus of their children.
  # This assumes that for certain widgets is OK to just exist
  # "in their whole" without letting the user obviously take it
  # apart or mess with its parts.
  #
  # The best example is scrollable text: when one right-clicks
  # on scrollable text, the menu OF THE VIEWPORT that
  # contains it takes over.
  #
  # Otherwise, without merging, there would FIRST be a
  # multiple-selection menu to spacially demultiplex which
  # widget is the one of interest
  # (the text widget, or the Panel, or the ViewportWdgt?). And
  # if the user wanted to resize the scroll text, which Widget
  # would the user have to pick? It would be very confusing.
  #
  # Instead, in this example above, one can naturally
  # resize the Viewport, or change its color, or delete it,
  # instead of operating on the text content.
  #
  # Note that, on the other side, for this to work the menu of
  # the ViewportWdgt has to give menu entries "peeking" them
  # from the text widget it contains, e.g. to change the font size
  #
  # Note that this mechanism could be overridden for "advanced"
  # users who want to mangle with the sub-components of a scrollable
  # text
  takesOverAndMergesChildrensMenus: false

  onNextStep: undefined # optional function to be run once. Not currently used in Fizzygum

  clickOutsideMeOrAnyOfMeChildrenCallback: [undefined]

  # ── the two per-class halves of the PIN protocol (see `pins`, below) ──────────────────────────
  # What kind of value I produce when I act as a dataflow SOURCE, which is what decides which of a
  # target's pins my "choose target property" menu may offer ("numerical" | "string" | "color", or
  # "any" for a widget that forwards whatever it received). Only controllers declare it.
  #   ONE declaration feeds both halves of the set-target UI: `openTargetPropertySelector` filters the
  # target's pins by it, and `ControllerMixin._addTargetConnectionMenuEntries` words its tooltip from
  # it. Stating the kind separately in each place lets the two drift silently — nothing compares a
  # tooltip's adjective against the menu it describes.
  producesPinKind: undefined

  # The LABEL of my principal pin — the one `exportedValue` reads when something asks for my value
  # without naming a pin (a spreadsheet reference, the dataflow drain). undefined => I export no
  # value. By label rather than by setter because a principal pin may legitimately be READ-ONLY
  # (StringFieldWdgt's value), and then there is no setter to name it by.
  principalPinLabel: undefined

  # hover help text. Declared on the base because this is where its consumer hook
  # lives (startCountdownForBubbleHelp, below) and because HighlightableMixin reads
  # it on whatever it is mixed into — branches that share no ancestor below Widget.
  # A subclass may state its own by declaring a value; ButtonWdgt's constructor reads
  # opts.toolTip GUARDED so that a declared value survives construction.
  toolTipMessage: undefined

  textDescription: undefined

  # note that not all the changed widgets have this flag set
  # because if a parent does a _fullChanged, we don't set this
  # flag in the children. This is intentionally so,
  # as we don't want to navigate the children too many times.
  # If you want to know whether a widget has changed its
  # position, use the hasMaybeChangedPaintBounds:
  # method instead, which looks at this flag (and another one).
  # See comment below on fullPaintBoundsMaybeChanged
  # for more information.
  paintBoundsMaybeChanged: false
  clippedBoundsWhenLastPainted: undefined

  # you'd be tempted to check this flag to figure out
  # whether any widget has possibly changed position but
  # you can't. If a PARENT has done a _fullChanged, the
  # children are NOT set this flag. This flag is set
  # only for the parent widget, and it's important that
  # it stays that way for how the mechanism for fleshing out
  # the damage rectangles works. We flesh out the rectangles
  # of the "fully damaged" widgets separately looking at this
  # flag, and we remove the rectangles of the sub-widgets that
  # have a parent with this flag since we know that they are
  # already covered.
  # If you want to figure out whether a widget has changed,
  # use the hasMaybeChangedPaintBounds: method,
  # which checks recursively with the parents both the
  # fullPaintBoundsMaybeChanged flag and the
  # paintBoundsMaybeChanged flag.
  # Another way of doing this is to mark with a special flag
  # all the widget that touch their bounds or positions, but
  # then it's sort of costly to un-set such flag in all such
  # widgets, as we'd have to keep the "changed" widgets in a special
  # array to do that. Seems quite a bit more work and complication,
  # so just use the method.
  fullPaintBoundsMaybeChanged: false
  fullClippedBoundsWhenLastPainted: undefined

  # §4.4 island buffer cache — the "source" (old-position) lane. When this widget last painted INTO
  # an island's buffer, these hold the PRE-mapping virtual full-bounds and that island, so a later
  # move-within-island can erase the vacated buffer region (_recordDrawnAreaForNextDamageRects sets
  # them; the flesh-out source lane consumes+clears them). undefined on every ordinary (non-island) paint.
  _islandBufferSourceIsland: undefined
  _islandBufferSourceVirtualRect: undefined

  cachedFullBounds: undefined
  checkFullBoundsCache: undefined
  childrenBoundsUpdatedAt: -1

  cachedFullClippedBounds: undefined
  checkFullClippedBoundsCache: undefined

  cachedVisibleBasedOnIsVisibleProperty: undefined
  checkVisibleBasedOnIsVisiblePropertyCache: undefined

  cachedClippedThroughBounds: undefined
  checkClippedThroughBoundsCache: undefined

  cachedClipThrough: undefined
  checkClipThroughCache: undefined

  cachedIsInCollapsedSubtree: undefined
  checkIsInCollapsedSubtreeCache: undefined

  srcDamageRectIndex: undefined
  dstDamageRectIndex: undefined

  layoutIsValid: true
  # (ordered down-walk Stage B2 — docs/archive/ordered-downwalk-stage-b-plan.md) FLUSH-LOCAL dirty-path
  # flag: true while I am a still-invalid work-list entry or an ancestor of one, steering the
  # settle engine's root-down walk (WorldWdgt.__downWalkLayout descends only through flagged
  # nodes). Derived FRESH each settle round from the work-list itself
  # (__flagHasDirtyDescendantUpwards, called only by _recalculateLayoutsBody's derivation — never
  # at enqueue/attach time), and cleared wholesale when the flush completes (recalculateLayouts'
  # finally, via world._widgetsFlaggedHasDirtyDescendant). Outside a flush every flag is false — which is why
  # it must stay in @serializationTransients even though its resting own-value is false.
  hasDirtyDescendant: false
  # The ACTIVE layout spec (a LayoutSpec-family object) — HOW I participate in my
  # container's layout right now. FREE-FLOATING = no spec OWNS my placement: undefined, or a
  # follower spec (StretchLayoutSpec — proportional placement MEMORY, ownsPlacement()
  # false) — see isFreeFloating and the LayoutSpec family contract.
  layoutSpec: undefined
  # The kept content-stack spec (VerticalStackLayoutSpec / FrameContentLayoutSpec) — spec
  # DATA persists across detachment (an element grabbed OUT of a stack keeps its explicit
  # grow/alignment for a later re-adoption); the adopting arranges read/refresh it and make
  # it the active @layoutSpec.
  _contentStackSpec: undefined
  # the widget's division constraint box (a DivisionStackLayoutSpec) once it has a private
  # one — see _ensureDivisionBox() / _divisionBoxOrDefaults() in the Layouts section
  _divisionBox: undefined

  _showsAdders: false

  highlighted: false
  # if this widget has the purpose of highlighting
  # another widget, then this field points to the
  # widget that this widget is supposed to highlight
  wdgtThisWdgtIsHighlighting: undefined

  # I am a transient EPHEMERAL overlay (highlight / pinout / — future — drag affordance),
  # created and destroyed by the per-cycle reconciler in WorldWdgt.doOneCycle, not by normal
  # widget code. Dedicated overlay classes (HighlighterWdgt) set this on their prototype; ad-hoc
  # overlays (the pinout StringWdgt) set it per-instance at creation. Read via the isEphemeral()
  # capability, which drives hit-test exclusion, shadow-skip and world-snapshot exclusion (below).
  _ephemeralOverlay: false

  destroyed: false

  shadowInfo: undefined

  initialiseDefaultFrameContentLayoutSpec: ->
    @_contentStackSpec = new FrameContentLayoutSpec FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW , FrameContentLayoutSpec.THIS_ONE_I_HAVE_NOW, 1
    # bind the element NOW (the capture re-binds it later): a PRE-capture measure's
    # total-fallback (getWidthInStack, U2) derives its answer from the element's
    # natural width, so it needs the back-ref before the first arrange runs.
    @_contentStackSpec.element = @

  initialiseDefaultVerticalStackLayoutSpec: ->
    # use the existing kept spec (if it's there — including a FrameContentLayoutSpec whose
    # widget moved from a window into a stack: the capability keeps explicit edits alive)
    unless @_contentStackSpec?.isContentStackCapable?()
      # no grow arg: UNDECIDED — the capture derives it from the add-time relationship
      # (a full-width add tracks the stack, a narrower add keeps its size — D2-def,
      # docs/archive/sizing-model-unification-plan.md §9.1/§9.5)
      @_contentStackSpec = new VerticalStackLayoutSpec
      # element bound now for the pre-capture measure fallback (see the window-content twin above)
      @_contentStackSpec.element = @

  mouseClickRight: ->
    # you could bring up what you right-click,
    # however for example that's not how OSX works.
    # Perhaps this could be a system setting?
    #@bringToForeground()

    world.hand.openContextMenuAtPointer @

  getTextDescription: ->
    if @textDescription?
      return @textDescription + "" + (@constructor.name.replace "Wdgt", "") + " (adhoc description of widget)"
    else
      return (@constructor.name.replace "Wdgt", "") + " (class name)"

  uniqueIDString: ->
    @widgetClassString() + "#" + @instanceNumericID

  widgetClassString: ->
    @constructor.name or @constructor.toString().split(" ")[1].split("(")[0]

  assignUniqueID: ->
    @constructor.instancesCounter++
    @constructor.lastBuiltInstanceNumericID++
    @instanceNumericID = @constructor.lastBuiltInstanceNumericID

  startCountdownForBubbleHelp: (contents) ->
    ToolTipWdgt.createInAWhileIfHandStillContainedInWidget @, contents

  constructor: ->
    super()
    @assignUniqueID()

    # PLACE TO ADD AUTOMATOR EVENT RECORDING IF NEEDED

    @bounds = Rectangle.EMPTY
    @minimumExtent = new Point 5,5

    @_commitBounds new Rectangle 0,0,50,40

    @lastTime = Date.now()
    # Note that we don't call
    # that's because the actual extending widget will probably
    # set more details of how it should look (e.g. size),
    # so we wait and we let the actual extending
    # widget to draw itself.

  # this happens when the Widget's constructor runs
  # and also when the Widget is duplicated
  registerThisInstance: ->
    goingUpClassHierarchy = @constructor
    loop
      # __super__ will always get to Object,
      # which doesn't have the "instances" property
      if !goingUpClassHierarchy.instances?
        break
      goingUpClassHierarchy.instances.add @
      goingUpClassHierarchy = goingUpClassHierarchy.__super__.constructor

  # this happens when the Widget is destroyed
  unregisterThisInstance: ->
    # remove instance from the instances tracker
    # in the class. To see this: just create an
    # AnalogClockWdgt, see that
    # AnalogClockWdgt.instances has one
    # element. Then delete the clock, and see that the
    # tracker is now an empty array.
    goingUpClassHierarchy = @constructor
    loop
      # __super__ will always get to Object,
      # which doesn't have the "instances" property
      if !goingUpClassHierarchy.instances?
        break
      goingUpClassHierarchy.instances.delete @
      goingUpClassHierarchy = goingUpClassHierarchy.__super__.constructor


  # INK COVERAGE: is there nothing of me drawn at this point? The appearance answers
  # for widgets that draw; an appearance-LESS widget is OPAQUE — explicitly (`? false`):
  # most appearance-less widgets are hit-targets that must catch clicks, PROVEN when
  # the opposite default ("appearance-less means transparent") was tried and regressed
  # ~70 tests (container arc §5.6). The appearance-less widgets that genuinely ARE
  # transparent overlays declare it per-class (MenuWdgt / PromptWdgt → true;
  # TransformFrameWdgt delegates into its subtree). Before the `? false` this same
  # behaviour rode an accident — `not undefined === true` at the consumer.
  isTransparentAt: (aPoint) ->
    (@appearance?.isTransparentAt aPoint) ? false

  # THE QUESTION THE POINTER ACTUALLY ASKS: does a pointer at this point stop on me?
  # It resolves the PAIR (@noticesTransparentClick, @isTransparentAt) into the one thing
  # the hit test wants, and it exists because that pair is a trap in both directions.
  #   Reading it: hit-testing is not "am I see-through here". A widget can paint nothing
  # at all and still catch every click (@noticesTransparentClick, which is how a string
  # stays clickable between its glyphs — measured 97% ink-free), and a widget can be fully
  # opaque in @alpha terms and catch nothing (a menu, whose body is drawn by a child).
  #   Writing it: one behaviour is composed from BOTH members, so stating either alone says
  # half of what you mean — TransformFrameWdgt's constructor spells that pairing out longhand.
  # Ask THIS, and set the two only as the way to answer it.
  catchesPointerAt: (aPoint) ->
    return true  if @noticesTransparentClick
    not @isTransparentAt aPoint

  # Selection overlay (selection-overlay-unification arc, supersedes the §5.D D-3/D21 world-attached
  # HighlighterWdgt). The editor-focus selection is a per-widget decoration drawn ON TOP of the selected
  # widget -- NOT a separate world/island widget -- so it rides that widget's own z-order (a click that
  # brings the window to the front can't bury it, the old bug) and is never baked into any cached buffer.
  # It is drawn AFTER my whole subtree (_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow),
  # so a CONTAINER's frame sits on top of its children too (own-content-level would let the children hide
  # it). Both halves are overridable so every widget decides WHETHER it is selected and HOW that looks;
  # the default frames the editor-selected widget (WorldWdgt._widgetBeingEdited, cached once per cycle)
  # with a calm teal outline. (The spreadsheet cell's blue ring is a separate MODEL selection drawn inline
  # -- CellWdgt.paintIntoAreaOrBlitFromBackBuffer -- since a cell is never the editor-focus widget.)
  _showsSelectionOverlay: ->
    world?.isEditorSelected @
  _drawSelectionOverlay: (aContext, al, at, w, h) ->
    # the teal outline the old editor-focus HighlighterWdgt drew (D19, Color 38,166,154): a 1-LOGICAL-px
    # stroke (ceilPixelRatio device px — the same thickness as every rectangular-family border) on my own
    # screen footprint, inset half a logical pixel for a crisp line (see RectangularAppearance.paintStroke),
    # clipped to my visible rect so a partially-scrolled widget is not outlined past its clip. Deliberately
    # DEVICE-space: this is world-level screen chrome, not an appearance body (only the thickness is logical).
    aContext.save()
    aContext.beginPath()
    aContext.rect Math.round(al), Math.round(at), Math.round(w), Math.round(h)
    aContext.clip()
    aContext.globalAlpha = 1
    aContext.lineWidth = ceilPixelRatio
    aContext.strokeStyle = Color.create(38, 166, 154, 1).toString()
    aContext.strokeRect (Math.round(@left() * ceilPixelRatio) + 0.5 * ceilPixelRatio),
      (Math.round(@top() * ceilPixelRatio) + 0.5 * ceilPixelRatio),
      (Math.round(@width() * ceilPixelRatio) - ceilPixelRatio),
      (Math.round(@height() * ceilPixelRatio) - ceilPixelRatio)
    aContext.restore()

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @appearance?.paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow

  # painting strokes is a little delicate because they need to
  # be painted INSIDE the widget (otherwise a) adjacent widgets, of widgets
  # within a layout would make a mess and b) clipping widget would
  # present a problem).
  # Also, Panels are tricky
  # because they need to paint the strokes after they paint their
  # content (because the content could paint everywhere inside the
  # Panel).
  # If you are thinking that you could paint the stroke before
  # the contents, by just
  # painting the contents of the Panel slightly clipped "inside" the
  # border of the Panel, that could potentially work with enough
  # changes, but it would only be easy to do with rectangular Panels,
  # since clipping "on the inside" of a border of arbitrary shape is
  # not trivial, maybe you'd have to examine how the lines cross at
  # different angles to paint "inside" of the lines, looks very messy.
  # Much easier to just paint the stroke after the content.
  paintStroke: (aContext, clippingRectangle) ->
    if @appearance?
      if @appearance.paintStroke?
        @appearance.paintStroke aContext, clippingRectangle

  addShapeSpecificMenuItems: (menu) ->
    if @appearance?.addShapeSpecificMenuItems?
      return @appearance.addShapeSpecificMenuItems menu
    return menu



  # Widget string representation: e.g. 'a Widget' or 'a Widget#2'
  toString: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.hidingOfWidgetsNumberIDInLabels
      name = @widgetClassString()
    else
      name = @uniqueIDString()
    # "an" before a vowel-initial name, else "a" (e.g. "an Image", "a Rectangle")
    firstPart = if name[0]?.toLowerCase() in ["a", "e", "i", "o", "u"] then "an " else "a "
    firstPart + name

  close: ->
    # SELF-SETTLE (single-mutation tier). _closeNoSettle re-homes me to the bin through the NON-settling
    # core _addLostWidgetNoSettle (-> _addInPseudoRandomPositionNoSettle -> _addNoSettle) and recurses
    # @parent._closeNoSettle(), so it reaches no public setter. Anchored on @ (the canonical wrap): I'm
    # attached at entry so the orphan guard passes, then the global flush re-lays-out my parent.
    @_settleLayoutsAfter => @_closeNoSettle()

  # restingContainer: which storage container the closed figure comes to rest
  # in -- undefined = the bin (the generic close verdict; the end-of-cycle storage
  # sort re-files anything reachable to the shelf that same cycle). The
  # save-close path passes the shelf directly: the reference demonstrably
  # exists, so filing there just skips the bin hop the sort would fix up.
  _closeNoSettle: (restingContainer) ->

    # closing window content: also close the window
    # UNLESS we are an internal window, in such case
    # leave the parent one as is
    if !@isFrame?() and @parent?.isFrame?()
      # private chain: the core, not public close() -- we are already inside close()'s settle batch.
      @parent._closeNoSettle restingContainer
      return

    world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.delete @
    @parent?._beforeChildClosed? @
    restingContainer ?= world.binWdgt
    if restingContainer?
      # §7.5 Bug B (model a) + latent 2 (Option B): re-home the whole FIGURE, not just me -- if I am the
      # sole content of an island (sugar OR explicit), the island IS my transform, so sending only me to
      # the bin would strand the empty island and drop my transform. Only the re-homing TARGET
      # changes; my own close bookkeeping above still runs on me. Off any island this is me (byte-identical).
      restingContainer._addRestingWidgetNoSettle @_enclosingIslandFigure()
      world.noteStorageMembershipMayHaveChanged()
    else
      world.inform "There is no\nbin to go in!"

  # ⚠ A DIRECT-CALL protocol, never a button action: the container window passes ITSELF
  # (FrameWdgt.close -> @contents?.closeFromContainerFrame @), and the parameter is read. Wiring
  # this name into a ButtonWdgt would hand it the BUTTON in slot 1 (trigger passes itself) and
  # silently close the button. A chrome button that means "dismiss" dispatches a zero-parameter
  # verb of its own (ErrorsLogViewerWdgt.hideLog is the worked example).
  closeFromContainerFrame: (containerWindow) ->
    containerWindow.close()

  # "move to trash" (reference-widgets plan §4.3, ratified sever-and-close): close, but FIRST cut
  # every liveness edge aimed at my figure — shortcuts pointing at me die, wires into me are
  # revoked — so the close's bin filing STICKS: nothing reachable is left to make the end-of-cycle
  # drain re-file me to the shelf. Where no such edge exists this is exactly close-to-bin, which is
  # why the menu only offers it when _wouldTrashSeverAnything says it differs.
  moveToTrash: ->
    # SELF-SETTLE (single-mutation tier): sever + close share the one settle batch.
    @_settleLayoutsAfter => @_moveToTrashNoSettle()

  _moveToTrashNoSettle: ->
    # trashing window content: the WINDOW is what gets trashed — the same one-step redirect
    # _closeNoSettle makes (which then sees a frame and does not redirect again).
    if !@isFrame?() and @parent?.isFrame?()
      # private chain: the core, not public moveToTrash() -- we are already inside its settle batch.
      @parent._moveToTrashNoSettle()
      return
    world._severLivenessEdgesIntoWdgtNoSettle @_enclosingIslandFigure()
    @_closeNoSettle()

  # Does "move to trash" differ from plain close/delete for me right now? — i.e. is there an
  # inbound liveness edge the sever would cut. Asked by the context-menu builder so the trash row
  # only appears when it MEANS something (a row on every menu is rent nothing measures); the walk
  # is O(everything widget-bearing) but menu-opening is a user gesture, like the close sites' ask.
  # Redirects like _closeNoSettle/_moveToTrashNoSettle so the question is asked about the same
  # figure the trash would file.
  _wouldTrashSeverAnything: ->
    if !@isFrame?() and @parent?.isFrame?()
      # private chain: the same one-step contents-to-window redirect as _moveToTrashNoSettle.
      return @parent._wouldTrashSeverAnything()
    # public-call-sanctioned: anyReferenceOrWireIntoWdgt is a pure read (a tree walk that
    # mutates nothing and settles nothing), the same ask the close sites make.
    world.anyReferenceOrWireIntoWdgt @_enclosingIslandFigure()

  # The window title-bar "edit" (pencil) button announces its press to the window's
  # contents (FrameWdgt.editButtonInBarPressed -> @contents.editButtonPressedFromFrameBar?()).
  # The button is only shown when providesAmenitiesForEditing is set -- by PanelWdgt
  # on contents, and by the framed citizens (DocumentWdgt, GenericPanelWdgt, §5.B)
  # on the frame itself -- so this shared press body lives here on the base.
  editButtonPressedFromFrameBar: ->
    if @dragsDropsAndEditingEnabled
      @disableDragsDropsAndEditing @
    else
      @enableDragsDropsAndEditing @

  # The shared "enable/disable editing" lock menu entry appended by the content-locking
  # containers (StretchableWidgetContainerWdgt, StretchablePanelWdgt,
  # VerticalStackViewportWdgt). The children list varies by
  # container (the viewport sources it from @contents), so it is passed in.
  _addEditingLockMenuEntries: (menu, childrenNotHandlesNorCarets) ->
    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if !@dragsDropsAndEditingEnabled
        menu.addMenuItem "enable editing", @, "enableDragsDropsAndEditingFromMenu", toolTip: "lets you drag content in and out"
      else
        menu.addMenuItem "disable editing", @, "disableDragsDropsAndEditingFromMenu", toolTip: "prevents dragging content in and out"
    menu.removeConsecutiveLines()

  # Widgets destroying ======
  # this is different from a widget being closed/deleted
  # when a widget is destroyed, it's removed from the stepping
  # list and marked as destroyed.
  # NOTE that the tree under this widget is kept intact,
  # so this widget could be duplicated and revived
  destroy: ->
    # SELF-SETTLE (single-mutation tier, the canonical wrap). _settleLayoutsAfter checks orphan at
    # the START (I'm still attached) then flushes globally, so my parent settles even though _destroyNoSettle
    # orphans me.
    # The one hook that rebuilds during destroy -- a window losing its @contents
    # (_beforeChildDestroyed -> _resetToDefaultContents) -- is safe inside this _inLayoutMutation:
    # _resetToDefaultContents rebuilds through the non-settling @_buildAndConnectChildrenNoSettle (not the
    # public self-settler), and the chrome it constructs adds to ORPHANS, which are exempt from the
    # flush-throw (see _settleLayoutsAfter's orphan guard). So nothing re-enters a settle mid-destroy.
    @_settleLayoutsAfter => @_destroyNoSettle()

  _destroyNoSettle: ->

    @parent?._beforeChildDestroyed? @
    @unregisterThisInstance()
    world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.delete @
    world.keyboardEventsReceivers.delete @
    # node-death, both halves (spec §2 + graph-edges plan §4.3). First SEVER the wires still
    # aiming at me: they live on each living producer's own @wires list, which the engine's
    # reverse index — still populated at this point — can find; left in place, the producer's
    # next fire would re-declare an edge onto my corpse and the drain would deliver into it
    # (the dead-target-wire spike). Then drop my own edges from the shared index — a dead node
    # left in @edgesFrom/@edgesTo is a leak AND a ghost recompute. Both are cheap no-ops for a
    # widget that was never a node.
    world.dataflow?.severWiresIntoDyingNode @
    world.dataflow?.removeAllEdgesOf @
    # my own wires die with me: anything only I was driving may just have become lost
    # (storage liveness follows wires — graph-edges plan §4.3), so mark the membership
    # chokepoint. O(1) and drain-suppressed, so it is safe inside bulk destroy storms.
    world.noteStorageMembershipMayHaveChanged() if @wires?

    # THE REFERENCE HALF of node-death (reference-widgets plan §4.3): no reference edge
    # outlives its referent, the twin of the wire invariant above — a shortcut left pointing
    # at my corpse is a dead door whose click can only apologise. The tracker enumerates
    # every holder wherever it lives (orphans and storage residents included), so this is
    # total where the classifier's walk is deliberately not. Terminates: a referent is
    # ctor-fixed, so every reference edge points at an OLDER widget — the reference graph is
    # a DAG — and the destroyed guard covers diamonds. O(tracker) per death, tracker is
    # small, so bulk destroy storms stay cheap.
    if world.widgetsReferencingOtherWidgets.size > 0
      for eachHolder in Array.from world.widgetsReferencingOtherWidgets
        continue if eachHolder.destroyed or eachHolder.referencedWidget != @
        eachHolder._severReferenceEdgeToNoSettle @

    @destroyed = true
    # FREEFLOATING-skip is centralized in _invalidateLayout(triggeringChild): passing @ lets the
    # parent skip when I'm freefloating (removing a freefloating child can't change the parent's
    # layout). Containers that MANAGE a freefloating child (e.g. LabelButton/MenuItem centring their
    # label) self-settle on the change itself (sizeToTextAndDisableFitting / setLabel), not here.
    @parent?._invalidateLayout(@)
    @__breakMoveResizeCaches()
    WorldWdgt.noteStructureChange()

    world.steppingWdgts.delete @

    # if there is anything being edited inside
    # what we are destroying, then also
    # stop editing -- through the NON-settling core, since _destroyNoSettle is a pure core that may run
    # under a layout flush (e.g. resetWorld / fullDestroyChildren): the public stopEditing tears the
    # caret down via fullDestroy (a self-settler) which would re-enter the flush and throw.
    if world.caret?
      if @isAncestorOf world.caret.target
        world._stopEditingNoSettle()

    # Editor-focus hygiene (Frame-model plan §5.D D2b): if the widget the editor
    # chrome acts on (the focus register) is in the dying subtree, clear it -- a
    # dangling register let a text button silently format a detached widget
    # (a data structure referencing a dead widget). Ancestor-or-self, mirroring
    # the caret check above, so a single-widget destroy (which orphans its
    # children rather than destroying them) still covers a focused descendant.
    focusWdgt = world.editorFocusWdgt
    if focusWdgt? and (focusWdgt == @ or @isAncestorOf focusWdgt)
      world.editorFocusWdgt = undefined

    # remove callback when user clicks outside
    # me or any of my children
    # public-call-sanctioned: onClickOutsideMeOrAnyOfMyChildren is pure REGISTRY bookkeeping (one
    # add/delete on world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren) — it settles nothing and
    # touches no geometry, so calling it from a NoSettle core is settle-neutral. Deregistering here
    # is the point: a destroyed widget must not stay in that set.
    @onClickOutsideMeOrAnyOfMyChildren undefined

    if @parent?
      previousParent = @parent
      @_fullChangedIncludingShadowOwner()

      previousParent.removeChild @
      if previousParent._reactToChildRemoved?
        previousParent._reactToChildRemoved @

    # in case I'm a destroy at the end of a fullDestroy,
    # the children array is already empty
    if @children.length != 0
      @children = []

    return undefined
  
  # destroys the whole tree
  # from the bottom (leaf widgets, drawn on top
  # of everything) to the top
  fullDestroy: ->
    # SELF-SETTLE (single-mutation tier, the canonical wrap). _fullDestroyNoSettle is a PURE core (recurses
    # cores). Anchored on @: attached at entry so the orphan guard passes, then the global flush re-fits.
    @_settleLayoutsAfter => @_fullDestroyNoSettle()

  _fullDestroyNoSettle: ->
    WorldWdgt.noteStructureChange()
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    # core-to-core recursion (no public fullDestroy/destroy): a PURE core. The public fullDestroy
    # wrapper supplies the single settle, so _fullDestroyNoSettle is safe to call directly from another
    # private chain even under _inLayoutMutation (where the public destroy() would throw).
    until @children.length == 0
      @children[0]._fullDestroyNoSettle()
    @_destroyNoSettle()
    return undefined

  closeChildren: ->
    WorldWdgt.noteStructureChange()
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    # bulk teardown through the non-settling core (see fullDestroyChildren): looping the public
    # self-settling close() would re-home + flush once PER child, and under the single-mutation tier
    # each immediate settle re-fits a half-emptied container. The caller settles once afterwards.
    until @children.length == 0
      @children[0]._closeNoSettle()
    return undefined

  fullDestroyChildren: ->
    if @children.length == 0
      return

    WorldWdgt.noteStructureChange()
    # we can't use a normal iterator because
    # we are iterating over an array that changes
    # its length as we are deleting its contents
    # while we are iterating on it.
    # Bulk teardown through the non-settling core, NOT the public self-settling fullDestroy(): looping
    # the public method would self-settle once PER child (O(children) flushes), and -- with fullDestroy
    # on the single-mutation tier -- each immediate settle re-fits a half-emptied container. Callers
    # (resetWorld / Inspector rebuild / video panes / bin) are reset/rebuild contexts that settle
    # once afterwards (or redraw an empty container), so no per-child flush is wanted.
    until @children.length == 0
      @children[0]._fullDestroyNoSettle()
    return undefined

  # Free-floating = NO SPEC OWNS MY PLACEMENT: no layoutSpec at all, or a follower spec
  # (StretchLayoutSpec — proportional placement MEMORY whose ownsPlacement() is false).
  # Both mean the layouting system leaves me alone between my holder's own re-lays: I am
  # user-movable/resizable, my mutations don't climb into my parent's layout, handles
  # show. See the LayoutSpec family contract.
  isFreeFloating: ->
    !@layoutSpec? or !@layoutSpec.ownsPlacement()

  _setLayoutSpec: (newLayoutSpec) ->
    if @layoutSpec == newLayoutSpec
      return

    @layoutSpec = newLayoutSpec

    # The resizing handle becomes visible/invisible
    # when the layout spec of the parent changes
    # (typically it's visible only when freefloating)
    # TODO unclear if we should rather have handles subscribe to the parent
    # layout change ??? What if there are multiple handles or they are
    # nested deeper?
    # only HandleWdgt defines updateVisibility, so the ?-existence filter is exactly the old
    # `m instanceof HandleWdgt` (type-test-elimination ε — the keep-links-back precedent)
    isThereAnHandle = @firstChildSuchThat (m) ->
      m.updateVisibility?
    isThereAnHandle?.updateVisibility()


  # leaving this function as step means that the widget wants to do nothing
  # but the children *are* traversed and their step function is invoked.
  # If a Widget wants to do nothing and wants to prevent the children to be
  # traversed, then this function should be set to undefined.
  step: noOperation
  
  
  # Widget accessing - geometry getting:
  left: ->
    @bounds.left()
  
  right: ->
    @bounds.right()
  
  top: ->
    @bounds.top()
  
  bottom: ->
    @bounds.bottom()
  
  center: ->
    @bounds.center()
  
  bottomCenter: ->
    @bounds.bottomCenter()
  
  bottomLeft: ->
    @bounds.bottomLeft()
  
  bottomRight: ->
    @bounds.bottomRight()
  
  boundingBox: ->
    @bounds
  
  # Widget accessing - geometry getting:
  leftTight: ->
    @bounds.left() + @paddingLeft
  
  rightTight: ->
    @bounds.right() - @paddingRight
  
  topTight: ->
    @bounds.top() + @paddingTop
  
  bottomTight: ->
    @bounds.bottom() - @paddingBottom
  
  boundingBoxTight: ->
    new Rectangle @leftTight(), @topTight(), @rightTight(), @bottomTight()

  _resizeToWithoutSpacing: ->

  # Set my width and re-fit my height / children to it. The width->height POLICY is
  # POLYMORPHIC: shape-keepers override this WHOLE method (AnalogClockWdgt -> square,
  # KeepsRatioWhenInVerticalStackMixin -> ratio, the icons / Stretchable* -> their own
  # extent rule). The base just sets the width and lets a deferred-layout widget re-fit its
  # children. HOW that re-fit is triggered depends on WHETHER A LAYOUT PASS IS ALREADY RUNNING:
  #  - normally (from an event handler / the public-setter flush): @_invalidateLayout() --
  #    schedule the re-fit for the current frame's recalculateLayouts (the deferred path).
  #  - WHILE recalculateLayouts is running (a CONTAINER sizing this child from inside its own
  #    _reLayout / _positionAndResizeChildren -- Phase 3b's window/stack re-fit on the cycle):
  #    _invalidateLayout would, for a non-freefloating deferred-layout child, CLIMB back and
  #    re-dirty the container in the SAME pass -> the until-loop never converges. So settle
  #    this child IN PLACE with a synchronous @_reLayout() (no invalidate, no climb), making
  #    the container's _reLayout a FIXED POINT -- the same outcome ViewportWdgt reaches via
  #    the non-notifying _apply*Base twins. (See docs/archive/deferred-layout-refit-and-add-design.md, "Phase 3b -- Slice 2".)
  # RETURNS the RESULTING height (Path B de-read-back). A container re-fit that sizes a child this way
  # (FrameWdgt / VerticalStackPanelWdgt _positionAndResizeChildren) must NOT then read the child's
  # geometry back to learn its new height -- that synchronous mutate-then-read-back is exactly what forces
  # the container re-fit to stay on the synchronous seam (it broke C1; see
  # docs/archive/softwrap-deferred-layout-conversion-plan.md §6b + docs/archive/deferred-layout-OVERVIEW.md §5). Instead it
  # HANDS the height forward: read once HERE, at the source, immediately after the synchronous mutation (so
  # byte-equal to the caller's old `child.height()`), and returned. EVERY override must likewise return its
  # resulting height (the 8 overrides are the historical break point -- keep them in sync).
  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_applyWidth newWidth
    if @implementsDeferredLayout()
      # immediate mutator: APPLY the re-fit now (synchronous _reLayout), never SCHEDULE it
      # (no _invalidateLayout). See task #17 -- low-level mutators must not schedule layout.
      @_reLayout()
    @height()

  # §4.1 pure measure -- the side-effect-free counterpart of _setWidthSizeHeightAccordingly above:
  # "what extent would I take at this available width?", computed WITHOUT mutating @bounds or firing the
  # re-fit seam, so a parent can MEASURE a child instead of sizing-it-then-reading-the-height-back. The
  # BASE default is for a widget whose height is INVARIANT under width (a plain box, an icon, a menu): its
  # height at any width is just its current height. Width->height-coupled widgets OVERRIDE it with their
  # real measure -- TextWdgt (wrapped-text height), VerticalStackPanelWdgt (Sigma of children's),
  # FrameWdgt (content + chrome), AnalogClockWdgt / KeepsRatioWhenInVerticalStackMixin (aspect). Reading
  # @height()/@width() here is allowed: those are STABLE applied geometry, NOT a mutate-then-read-back.
  preferredExtentForWidth: (availW) ->
    new Point (availW ? @width()), @height()

  # (U3-C, sizing-model unification) The no-input sibling of preferredExtentForWidth: "the
  # extent I would take given my druthers" -- PURE. For a plain widget that IS its applied
  # extent (identical to the THIS_ONE_I_HAVE_NOW sentinel's old raw width()/height() reads,
  # byte-for-byte). A widget whose own pending first placement will CHANGE its extent
  # (FrameWdgt pre-capture) overrides this with the extent that placement will produce, so a
  # container placing it mid-construction sizes to its FINAL extent in one shot instead of a
  # stale transient (the last first-placement settle re-visits died here).
  preferredExtent: ->
    @extent()

  # The apply-tier twin of setBounds — same two call shapes (aRectangle | aPosition, anExtent):
  # place AND size in ONE immediate call. The move is subtree-FOLLOWING (_applyMoveTo — children
  # ride along, like every unmarked move verb): the one-shot for the ubiquitous construction
  # idiom `w._applyMoveTo p; w._applyExtent e`. CONTRAST _applyGrantedBounds below, the arrange
  # engine's frame-commit, whose translate deliberately does NOT carry children.
  _applyBounds: (aRectangleOrPosition, extent) ->
    aRectangle = if extent? then aRectangleOrPosition.extent extent else aRectangleOrPosition
    # deliberately NOT re-fusable into a self-call: this IS the one-shot the pairs fuse into
    @_applyMoveTo aRectangle.origin
    @_applyExtent aRectangle.extent()

  # The ARRANGE engine's frame-commit (the bounds-first rule: a _reLayout override applies the
  # bounds the layout pass GRANTED it before its first own-geometry read — enforced by
  # buildSystem/check-relayout-bounds-first.js). The translate deliberately does NOT carry
  # children: the widget's own arrange places them from the new frame right after, and
  # float-followers ride the float-follow machinery — auto-following here would double-move them.
  _applyGrantedBounds: (newBounds) ->
    if @bounds.equals newBounds
      return

    unless @bounds.origin.equals newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @_assertBoundsWellFormed "_applyGrantedBounds"
      @__breakMoveResizeCaches()
      @_changed()

    @_applyExtent newBounds.extent()

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  # ===== self-settling public geometry API (prototype, 2026-06-19) =====
  # A public geometry setter records the DESIRED change (@desired* + _invalidateLayout)
  # and then FLUSHES the layout (world.recalculateLayouts) before returning, so the
  # world's geometry is consistent between public calls -- the caller never needs a
  # "settle"/yield. (See docs/archive/deferred-layout-16-macro-breakages.md.) Re-entrancy is
  # forbidden and THROWS: a public setter must not be called from within another
  # public setter (or a layout pass), which would flush more than once per logical
  # mutation. Calling several public setters in SEQUENCE is fine -- each completes,
  # flushing once, before the next begins.
  # The same wrapper also backs the public STRUCTURAL mutator add() (a tree
  # change re-fits layouts too), so it RETURNS the thunk's value -- those need to hand
  # back the added widget (see docs/archive/deferred-layout-refit-and-add-design.md, D3).
  _settleLayoutsAfter: (coreThunk) ->
    # early world bootstrap: the `world` singleton isn't wired up yet, so there's
    # nothing to flush to -- just record the desired change; the first frame settles it.
    unless world?
      return coreThunk()
    # ALREADY inside a flush/pass?  Two cases, split by whether the receiver is part of the live world:
    #  - ORPHAN receiver -> DEFER (record the change, do NOT flush). This is the ONE remaining settle
    #    deferral, and it is framework-internal: a constructor that builds its innards (e.g. the icon
    #    buttons FrameWdgt._buildAndConnectChildren makes) runs INSIDE the enclosing mutation's settle and
    #    adds to an orphan; it must not re-enter recalculateLayouts (which would throw). It settles for real
    #    when that enclosing operation's flush completes -- or, for a widget that stays detached, on its next
    #    public call / on attach. (isOrphan() is false for the world itself and for anything on the hand, so
    #    world.add / dragged-widget mutations are NOT orphans and fall through to the throw.) See
    #    docs/archive/orphan-settledness-plan.md and docs/archive/deferred-layout-refit-and-add-design.md (D3).
    #  - ATTACHED receiver -> THROW. A public geometry setter reached on an attached widget mid flush/pass is
    #    a flow-soundness violation: internal layout (_reLayout / _reLayoutSelf / ...) must use the immediate
    #    (geometry) mutators, never the public deferred API -- otherwise recalculateLayouts would re-enter.
    #    The static gate buildSystem/check-layering.js catches the name-recognized internal methods at BUILD
    #    time ([A] the public geometry/text setters, [G] the structural self-settling wrappers
    #    destroy/close/fullDestroy/...); this runtime backstop covers what the name-scanner CANNOT: a
    #    structural add() (its name collides with Point#add, so [G] excludes it) and any wrapper reached
    #    TRANSITIVELY or via a dynamically-typed receiver.
    if world._inLayoutMutation or world._recalculatingLayouts
      return coreThunk() if @isOrphan()
      throw new Error "Fizzygum: a public geometry setter was reached during a layout flush/pass -- internal layout code (_reLayout / _reLayoutSelf / ...) must use the immediate (geometry) mutators, not the public deferred API (see buildSystem/check-layering.js)."
    # NOT in a flush: settle NOW -- for ATTACHED widgets (always have) AND for ORPHANS (orphan-settledness,
    # docs/archive/orphan-settledness-plan.md): a public mutation leaves the receiver's OWN subtree settled on return,
    # so there is no "is it settled here?" question for a detached/under-construction widget either.
    # recalculateLayouts lays out the orphan's queued invalidations, which are its own subtree (an orphan's
    # _invalidateLayout can't climb into the world -- it stops at parent==undefined), so when the world is already
    # settled this flushes ONLY the orphan. The orphan's intrinsic (parentless) geometry re-settles to its
    # in-context form when it is later added to the world.
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()
      return result
    finally
      world._inLayoutMutation = false

  # The REACTIVE-CONNECTOR settle lane: like _settleLayoutsAfter, but when an enclosing settle's MUTATION WINDOW
  # is already open (world._inLayoutMutation) it JOINS it (runs the core in it) instead of throwing. A connection
  # cascade (a wired reactive circuit) legitimately reaches a self-settling connector entrypoint mid-window --
  # e.g. the C<->F converter: cText's connector opens the settle, and the calc renders + fText's connector hops
  # run inside it -- so the whole cascade settles ONCE, when the OUTERMOST connector returns.
  # Reached from INSIDE the flush walk itself (world._recalculatingLayouts -- only layout code can get here, e.g.
  # a wired AxisWdgt tick label re-titled by its _reLayout firing its connection) it KEEPS the strict lane's
  # orphan-defer + flow-violation throw: layout code must not fire settling entrypoints, cascade or not.
  # RESTRICTED to _<name>Connector callers by check-layering rule [P] -- general/internal code must keep using
  # _settleLayoutsAfter (which also throws mid-WINDOW, surfacing the violation) or a _<name>NoSettle core.
  _settleLayoutsAfterOrJoinEnclosingPass: (coreThunk) ->
    unless world?
      return coreThunk()
    if world._recalculatingLayouts
      return coreThunk() if @isOrphan()
      throw new Error "Fizzygum: a connector entrypoint was reached from inside the layout flush walk -- layout code (_reLayout / _reLayoutSelf / ...) must not fire a connection's settling entrypoint (see buildSystem/check-layering.js, rule [P])."
    if world._inLayoutMutation
      return coreThunk()          # JOIN the enclosing settle's mutation window (no nested settle, no throw)
    world._inLayoutMutation = true
    try
      result = coreThunk()
      world.recalculateLayouts()
      return result
    finally
      world._inLayoutMutation = false

  # The ONE-SHOT frame setter: position AND extent in a single public mutation (ONE flush --
  # prefer this over a setExtent-then-moveTo pair, which flushes twice). Two call shapes:
  #   setBounds aRectangle            -- the Morphic/Cocoa-setFrame form
  #   setBounds aPosition, anExtent   -- origin + size as Points (the friendly form)
  setBounds: (aRectangleOrPosition, extent) ->
    @_settleLayoutsAfter => @_setBoundsNoSettle aRectangleOrPosition, extent

  # Non-settling bounds core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent /
  # @desiredPosition + invalidate, no flush -- rides an OUTER settle. Was setBounds' inline thunk.
  _setBoundsNoSettle: (aRectangleOrPosition, extent) ->
    aRectangle = if extent? then aRectangleOrPosition.extent extent else aRectangleOrPosition
    if not @isFreeFloating()
      return
    else
      aRectangle = aRectangle.round()

      newExtent = new Point aRectangle.width(), aRectangle.height()
      unless @extent().equals newExtent
        @desiredExtent = newExtent
        @_invalidateLayout()

      newPos = aRectangle.origin
      unless @position().equals newPos
        @desiredPosition = newPos
        @_invalidateLayout()

  # Silently commit my bounds (origin + extent): translate my origin, then commit my extent via the __commitExtent
  # leaf -- NO repaint, NO self-relayout. Used for construction-time sizing and by the top-down arrange (a container
  # sizing my frame already knows my new bounds, so no repaint/relayout is owed here).
  # (Collapsed 2026-07-01) The old "non-notifying twin" _applyGrantedBounds and this method became byte-identical once the
  # re-fit seam was deleted -- both are just a silent origin+extent commit -- so they are ONE method now (_commitBounds).
  _commitBounds: (newBounds) ->
    if @bounds.equals newBounds
      return

    unless @bounds.origin.equals newBounds.origin
      @bounds = @bounds.translateTo newBounds.origin
      @_assertBoundsWellFormed "_commitBounds"
      @__breakMoveResizeCaches()

    @__commitExtent newBounds.extent()
  
  
  leftCenter: ->
    @bounds.leftCenter()
  
  rightCenter: ->
    @bounds.rightCenter()
  
  topCenter: ->
    @bounds.topCenter()
  
  # same as position()
  topLeft: ->
    @bounds.origin
  
  topRight: ->
    @bounds.topRight()
  
  position: ->
    @bounds.origin

  extent: ->
    @bounds.extent()
  
  width: ->
    @bounds.width()

  # e.g. images can have a lot of spacing
  # around them, so here is a method to get
  # the width of the actual thing, ignoring all
  # the spacing that might be around
  widthWithoutSpacing: ->
    @width()
  
  height: ->
    @bounds.height()

  # used for example:
  # - to determine which widgets you can attach a widget to
  # - for a SliderWdgt's "set target" so you can change properties of another Widget
  # - by the HandleWdgt when you attach it to some other widget
  # Note that this method has a slightly different
  # version in PanelWdgt (because it clips, so we need
  # to check that we don't consider overlaps with
  # widgets contained in a Panel that are clipped and
  # hence *actually* not overlapping).
  # The 5-clause "is THIS widget itself a plausible attach/set-target for theWidget" predicate — shared
  # verbatim by plausibleTargetAndDestinationWidgets below and by its clipping variant in
  # ClippingAtRectangularBoundsMixin (the two differ only in whether they recurse into the children).
  # Pure query, no side effects.
  # The overlap test runs in the SCREEN plane: either side can live on a mapped plane (a scrolled
  # pane's residents, an island's), where its @bounds are plane-local and a raw cross-plane
  # isIntersecting compares apples to oranges. MY side is the mapped VISIBLE box —
  # clippedThroughBounds (plane box ∩ every ancestor clip, EMPTY when I'm scrolled/clipped
  # out of view) mapped to screen — so a widget the user cannot SEE is never offered as an
  # attach/set-target candidate; theWidget's side stays its full mapped box (the subject being
  # attached may itself poke out of a pane and still probes with all of itself). Both are the
  # identity (same object) off any mapped plane, so the unmapped world pays nothing.
  _isSelfPlausibleAttachTargetFor: (theWidget) ->
    @visibleBasedOnIsVisibleProperty() and
      !@isInCollapsedSubtree() and
      !theWidget.isAncestorOf(@) and
      ((@mapRectToScreen @clippedThroughBounds()).isIntersecting theWidget.screenBounds()) and
      !@anyParentPopUpMarkedForClosure()

  plausibleTargetAndDestinationWidgets: (theWidget) ->
    # find if I intersect theWidget,
    # then check my children recursively
    # exclude me if I'm a child of theWidget
    # (cause it's usually odd to attach a Widget
    # to one of its subwidgets or for it to
    # control the properties of one of its subwidgets)
    result = []
    if @_isSelfPlausibleAttachTargetFor theWidget
      result = [@]

    @children.forEach (child) ->
      result = result.concat(child.plausibleTargetAndDestinationWidgets(theWidget))

    return result


  # both methods invoked in here
  # are cached
  # used in the method _fleshOutDamage
  # to skip the "destination" damage rects
  # for widgets that marked themselves
  # as damaged but at moment of destination
  # might be invisible
  surelyNotShowingUpOnScreenBasedOnVisibilityCollapseAndOrphanage: ->
    if !@isVisible
      return true

    if @isOrphan()
      return true

    if !@visibleBasedOnIsVisibleProperty()
      return true

    if @isInCollapsedSubtree()
      return true

    return false


  SLOWvisibleBasedOnIsVisibleProperty: ->
    if !@isVisible
      return false
    if @parent?
      return @parent.SLOWvisibleBasedOnIsVisibleProperty()
    else
      return true

  # doesn't check orphanage
  visibleBasedOnIsVisibleProperty: ->
    if !@isVisible
      # I'm not sure updating the cache here does
      # anything but it's two lines so let's do it
      @checkVisibleBasedOnIsVisiblePropertyCache = WorldWdgt.visibilityVersion
      @cachedVisibleBasedOnIsVisibleProperty = false
      result = @cachedVisibleBasedOnIsVisibleProperty
    else # @isVisible is true
      if !@parent?
        result = true
      else
        if @checkVisibleBasedOnIsVisiblePropertyCache == WorldWdgt.visibilityVersion
          result = @cachedVisibleBasedOnIsVisibleProperty
        else
          @checkVisibleBasedOnIsVisiblePropertyCache = WorldWdgt.visibilityVersion
          @cachedVisibleBasedOnIsVisibleProperty = @parent.visibleBasedOnIsVisibleProperty()
          result = @cachedVisibleBasedOnIsVisibleProperty

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWvisibleBasedOnIsVisibleProperty()
        debugger
        console.error "CACHED_DERIVATION_DIVERGED -- visibleBasedOnIsVisibleProperty is broken"

    return result


  # doesn't take into account orphanage
  # or visibility
  SLOWfullBounds: ->
    result = @bounds
    @children.forEach (child) ->
      if child.SLOWvisibleBasedOnIsVisibleProperty() and
      !child.SLOWisInCollapsedSubtree()
        result = result.merge child.SLOWfullBounds()
    result

  SLOWfullClippedBounds: ->
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    result = @SLOWclippedThroughBounds()
    @children.forEach (child) ->
      if child.SLOWvisibleBasedOnIsVisibleProperty() and !child.SLOWisInCollapsedSubtree()
        result = result.merge child.SLOWfullClippedBounds()
    result

  # Independent (de-circularized) re-derivations of the version-keyed clipThrough /
  # clippedThroughBounds, mirroring their CACHED bodies exactly. Like the cached clipThrough,
  # the recursion terminates at the two overriders -- world and the hand -- which return their
  # raw @boundingBox() via matching SLOW* overrides (WorldWdgt / ActivePointerWdgt), exactly as
  # their cached clippedThroughBounds/clipThrough overrides do. The hand's override is NOT the
  # same as the generic clip-through-world computation (the hand is painted on top of
  # everything, unclipped -- and its @boundingBox() can be inside-out/empty, which the generic
  # intersect would normalize to EMPTY), so it MUST be mirrored explicitly per overrider; a
  # base-only guard cannot reproduce it.
  SLOWclipThrough: ->
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    firstClipping = @SLOWfirstParentClippingAtBounds()
    if !firstClipping?
      firstClipping = world
    upstream = firstClipping.SLOWclipThrough()
    # translation edge — kept in lockstep with clipThrough above
    if firstClipping.scrollTranslationOfChild?
      edgeChild = @
      edgeChild = edgeChild.parent while edgeChild.parent? and edgeChild.parent != firstClipping
      if (translation = firstClipping.scrollTranslationOfChild edgeChild)?
        upstream = upstream.translateBy translation.neg()
    if @clipsAtRectangularBounds
      @boundingBox().intersect upstream
    else
      upstream

  SLOWclippedThroughBounds: ->
    if @isOrphan() or !@SLOWvisibleBasedOnIsVisibleProperty() or @SLOWisInCollapsedSubtree()
      return Rectangle.EMPTY
    @boundingBox().intersect @SLOWclipThrough()

  # for PanelWdgt scrolling support
  # (D4, sizing-model unification U3-A) THE ONE NAMED STATE-READ of the layout system --
  # reclassified, kept. Single consumer: ViewportWdgt's NON-content-sizing (folder /
  # toolbar) frame-fit branch. Its children there are USER-PLACED free-floating widgets:
  # their positions are genuine STATE (not derivable from any spec or measure -- §4.1 proved
  # a measure pass alone could not replace this read), and that arrange never mutates them
  # first, so this is a read of STABLE applied geometry -- NOT the mutate-then-read-back
  # impurity the pure-measure campaign retires (cf. preferredExtentForWidth's rule: reading
  # applied geometry is allowed when nothing just mutated it). Lint note: any NEW caller of
  # this method should justify itself against subWidgetsMergedPreferredBounds (below) first.
  # D2 scroll reachability (docs/archive/claimsspace-footprint-default-and-scroll-reachability-plan.md):
  # a child that answers scrollOverflowBoundsInParentPlane?() (a transformed island) contributes
  # its claimed ∪ ink box INSTEAD of its stock bounds — its rotated overhang is §4.11 ink
  # overflow, invisible to fullBounds (= the slot box), yet must stay reachable by scrolling.
  # The SEED takes the same capability answer: a coupled island's union does not contain its
  # (pixel-less, virtual) slot box, which must not inflate the frame. Still a read of stable
  # applied geometry + a pure derived box — the D4/U3-A classification is unchanged.
  subWidgetsMergedFullBounds: ->
    result = undefined
    @children.forEach (child) ->
      # we exclude the HandleWdgts because they
      # mangle how the Panel inside ViewportWdgts
      # calculate their size when they are resized
      # (remember that the resizing handle of ViewportWdgts
      # actually end up in the Panel inside them.)
      # HIDDEN children are deliberately NOT excluded (owner ruling, 2026-07-23,
      # reverting a short-lived bin-era filter): visibility is a PAINT/INPUT
      # toggle, never a layout input -- an invisible widget keeps its seat, its
      # extent and its scroll contribution, ghost-like. To take a widget out of
      # a layout, take it out of the tree. (Making the fit visibility-dependent
      # would also hand the auto-hiding scrollbars a feedback loop: hiding a
      # bar changing the fit that decides whether the bar shows.)
      if !child.isLayoutInert?()
        contribution = child.scrollOverflowBoundsInParentPlane?()
        if !contribution?
          # if a widget implements deferred layout, then
          # really we can't consider the sizes and positions
          # of its children, so stick to the parent bounds
          # only
          contribution = if child.implementsDeferredLayout() then child.bounds else child.fullBounds()
        result = if result? then result.merge contribution else contribution
    result

  # §4.1 Stage C (proper-layouts): the side-effect-free counterpart of subWidgetsMergedFullBounds above --
  # the merged bounds of my children with each child's SIZE taken from its pure preferredExtentForWidth
  # measure (min-extent-clamped, as __commitExtent applies on commit) instead of its just-mutated applied
  # extent, at the child's current position. A viewport consumes this to size its content frame WITHOUT
  # first resizing my children and reading the result back -- the mutate-then-read-back the re-fit seam exists
  # for (assessment §2.4). KEEPS the historical child[0] seed (contributes even if inert) that
  # subWidgetsMergedFullBounds dropped in its 2026-07-22 rewrite -- re-aligning this one would shift real
  # content-sizing measurements, so the divergence is deliberate; visibility-blind like it (and fullBounds).
  # Byte-identical to the applied fit at the fixed point, where measured extent
  # == applied extent (Stage-C probe: 0/1429 converged mismatches). childMeasureWidth = the width to measure
  # each child at (the caller subtracts its own padding). VerticalStackPanelWdgt overrides this to also
  # derive child POSITIONS from measures (its children's positions are layout-derived, not stable state).
  subWidgetsMergedPreferredBounds: (childMeasureWidth) ->
    result = undefined
    if @children.length
      result = @children[0].bounds
      @children.forEach (child) ->
        if !child.isLayoutInert?()
          measured = child.preferredExtentForWidth?(childMeasureWidth)
          ext = if measured? then measured else child.extent()
          minE = child.getMinimumExtent?()
          w = if minE? then Math.max(ext.x, minE.x) else ext.x
          h = if minE? then Math.max(ext.y, minE.y) else ext.y
          result = result.merge new Rectangle child.left(), child.top(), child.left() + w, child.top() + h
    result

  # does not take into account orphanage or visibility
  fullBounds: ->
    if @checkFullBoundsCache == WorldWdgt.geometryVersion
      if world.doubleCheckCachedMethodsResults
        if !@cachedFullBounds.equals @SLOWfullBounds()
          debugger
          console.error "CACHED_DERIVATION_DIVERGED -- fullBounds is broken (cached)"
      return @cachedFullBounds

    result = @bounds
    @children.forEach (child) ->
      if child.visibleBasedOnIsVisibleProperty() and !child.isInCollapsedSubtree()
        result = result.merge child.fullBounds()

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWfullBounds()
        debugger
        console.error "CACHED_DERIVATION_DIVERGED -- fullBounds is broken (uncached)"

    @checkFullBoundsCache = WorldWdgt.geometryVersion
    @cachedFullBounds = result

  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the smallest damage rectangle created by
  # a _fullChanged(), which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  fullClippedBounds: ->
    if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      result = Rectangle.EMPTY
    else
      if @checkFullClippedBoundsCache == WorldWdgt.geometryVersion
        if world.doubleCheckCachedMethodsResults
          if !@cachedFullClippedBounds.equals @SLOWfullClippedBounds()
            debugger
            console.error "CACHED_DERIVATION_DIVERGED -- fullClippedBounds is broken"
        return @cachedFullClippedBounds

      # you'd be thinking this is the same as
      #   result = @fullBounds().intersect @clipThrough()
      # but it's not, because fullBounds doesn't
      # take into account orphanage and visibility

      result = @clippedThroughBounds()
      @children.forEach (child) ->
        if child.visibleBasedOnIsVisibleProperty() and !child.isInCollapsedSubtree()
          result = result.merge child.fullClippedBounds()

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWfullClippedBounds()
        debugger
        console.error "CACHED_DERIVATION_DIVERGED -- fullClippedBounds is broken"

    @checkFullClippedBoundsCache = WorldWdgt.geometryVersion
    @cachedFullClippedBounds = result
  
  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the smallest damage rectangle created by
  # a _changed(), which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  clippedThroughBounds: ->

    if @checkClippedThroughBoundsCache == WorldWdgt.geometryVersion
      result = @cachedClippedThroughBounds
    else if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClippedThroughBoundsCache = WorldWdgt.geometryVersion
      @cachedClippedThroughBounds = Rectangle.EMPTY
      result = @cachedClippedThroughBounds
    else
      @checkClippedThroughBoundsCache = WorldWdgt.geometryVersion
      @cachedClippedThroughBounds = @boundingBox().intersect @clipThrough()
      result = @cachedClippedThroughBounds

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWclippedThroughBounds()
        debugger
        console.error "CACHED_DERIVATION_DIVERGED -- clippedThroughBounds is broken"

    return result
  
  # this one does take into account orphanage and
  # visibility. The reason is that this is used to
  # find the "smallest damage rectangles"
  # which means that really we
  # are interested in what's visible on screen so
  # we do take into account orphanage and
  # visibility.
  clipThrough: ->
    # answer which part of me is not clipped by a Panel
    if @checkClipThroughCache == WorldWdgt.geometryVersion
      result = @cachedClipThrough
    else if @isOrphan() or !@visibleBasedOnIsVisibleProperty() or @isInCollapsedSubtree()
      @checkClipThroughCache = WorldWdgt.geometryVersion
      @cachedClipThrough = Rectangle.EMPTY
      result = @cachedClipThrough
    else
      firstParentClippingAtBounds = @firstParentClippingAtBounds()
      if !firstParentClippingAtBounds?
        firstParentClippingAtBounds = world
      firstParentClippingAtBoundsClipThroughBounds = firstParentClippingAtBounds.clipThrough()
      # translation edge (paint-time scroll, plan §3.2): the upstream clip lives in the clipping
      # parent's plane; when that parent scroll-translates the subtree I reach it through, the
      # clip must be expressed in MY plane (screen box B constrains plane points p with
      # p + t ∈ B ⇔ p ∈ B − t). The edge is the clipping parent's DIRECT child on my ancestor
      # chain (a non-clipping plane — a stack — can sit between me and the clipping viewport),
      # so climb to it before asking. Absent provider / zero translation: same object through.
      if firstParentClippingAtBounds.scrollTranslationOfChild?
        edgeChild = @
        edgeChild = edgeChild.parent while edgeChild.parent? and edgeChild.parent != firstParentClippingAtBounds
        if (translation = firstParentClippingAtBounds.scrollTranslationOfChild edgeChild)?
          firstParentClippingAtBoundsClipThroughBounds = firstParentClippingAtBoundsClipThroughBounds.translateBy translation.neg()
      @checkClipThroughCache = WorldWdgt.geometryVersion
      if @clipsAtRectangularBounds
        @cachedClipThrough = @boundingBox().intersect firstParentClippingAtBoundsClipThroughBounds
      else
        @cachedClipThrough = firstParentClippingAtBoundsClipThroughBounds
      result = @cachedClipThrough

    if world.doubleCheckCachedMethodsResults
      if !result.equals @SLOWclipThrough()
        debugger
        console.error "CACHED_DERIVATION_DIVERGED -- clipThrough is broken"

    return result

  # Affine transforms (docs/plans/affine-transforms-plan.md §4.5): map a damage rect from
  # THIS widget's plane up to the SCREEN plane, through each ancestor
  # TransformFrameWdgt ("island") on my parent chain that currently has a
  # non-identity transform. A widget not inside any non-identity island — the
  # overwhelming common case, and ALWAYS when the feature is dormant — gets its rect
  # back UNCHANGED (same object), so the damage-rect machinery stays byte-identical.
  # The pre-image is an axis-aligned virtual-plane rect; each island maps it to an
  # integer axis-aligned AABB (§4.3), so the result is a plain Rectangle safe to feed
  # the existing merge/dedupe. The mapped inner damage is clipped in the correct
  # (screen) plane against the OUTERMOST island's own visible rect (= its footprint ∩
  # its ancestor screen clips) — clipping the pre-image plane would not commute with
  # the transform (§4.11).
  # Every screen↔plane walk here is TWO-ARM (docs/archive/paint-time-scroll-translation-plan.md
  # §3.2): the island arm (a non-identity TransformFrameWdgt ancestor — similitude verbs) and
  # the translation arm (any ancestor answering `scrollTranslationOfChild(child)` for the child
  # edge just climbed through — an integer-Point translate applied to that child's subtree when
  # mapping plane→screen; `previous` tracks the edge so the question is per-child: a viewport
  # answers only for its contents, so its bars stay FIXED chrome with no stored role). An
  # ancestor with no non-identity island and no translation provider contributes nothing, so
  # off any mapped plane every walk still returns its input UNCHANGED (same object) — the
  # dormant guarantee the byte-exact suite stands on.
  mapRectToScreen: (aRect, depositBufferDamage = false) ->
    result = aRect
    outermostIslandClip = undefined
    previous = @
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        # §4.4 buffer cache — the "destination" (new-position) deposit: the PRE-mapping rect is in
        # THIS island's virtual (buffer) plane, so it is exactly the region this widget now occupies
        # in the island's buffer — and the damage lanes pass it already grown by the widget's
        # shadowExtendedRect, so it covers the shadow px in every crossed plane too. Deposit it as
        # content-damage. Only the two damage-flesh-out lanes pass depositBufferDamage=true; the OTHER
        # caller (_recordDrawnAreaForNextDamageRects, the paint-time snapshot) passes false, so a
        # mere repaint never dirties the buffer. Depositing on EACH crossed island handles nesting
        # for free. Zero dormant cost (off-island never enters).
        ancestor._depositIslandBufferDamageRect result if depositBufferDamage
        result = ancestor.transformSpec.mapRect result, ancestor.bounds
        # the OUTERMOST island's visible rect clips the mapped damage (§4.11) — read it at the
        # crossing (pure per geometryVersion, so the value equals an after-the-loop read) and let
        # any LATER translation step carry it along, so the final intersect happens with both
        # rects expressed in the same (screen) plane even when an island sits inside a scrolled
        # pane. Each crossing overwrites: only the outermost island's clip applies, as before.
        outermostIslandClip = ancestor.clippedThroughBounds()
      else if (translation = ancestor.scrollTranslationOfChild?(previous))?
        # translation arm: EXACT translate — no ±1px AA pad (nothing resamples), no buffer deposit
        result = result.translateBy translation
        outermostIslandClip = outermostIslandClip.translateBy translation if outermostIslandClip?
      previous = ancestor
      ancestor = ancestor.parent
    if outermostIslandClip?
      result = result.intersect outermostIslandClip
    result

  # Affine transforms (§4.6): map a SCREEN point down into THIS widget's plane, by
  # applying the INVERSE of each ancestor island's transform, OUTERMOST first (the
  # inverse of mapRectToScreen's innermost-first forward chain). A widget not inside
  # any non-identity island gets the point back UNCHANGED — so hit-testing is
  # byte-identical when dormant. Used by the hit-test predicate so a widget's
  # bounds/pixel test runs in the plane where its (virtual) geometry lives; corner
  # fall-through and per-pixel transparency then come out exact for free (§10.4).
  screenPointToMyPlane: (aPoint) ->
    # two-arm (see mapRectToScreen's header note): a step is an island (inverse similitude)
    # or a scroll translation (a bare Point, inverted by subtract)
    steps = undefined
    previous = @
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        steps ?= []
        steps.push ancestor              # innermost first
      else if (translation = ancestor.scrollTranslationOfChild?(previous))?
        steps ?= []
        steps.push translation
      previous = ancestor
      ancestor = ancestor.parent
    return aPoint if !steps?
    result = aPoint
    for step in steps by -1              # apply inverses outermost → innermost
      if step.transformSpec?             # an island step (a translation step is a bare Point)
        result = step.transformSpec.inverseMapPoint result, step.bounds
      else
        result = result.subtract step
    result

  # Affine transforms (§4.6): the exact inverse of screenPointToMyPlane — map a point in THIS
  # widget's (virtual) plane UP to the SCREEN plane, applying each ancestor island's FORWARD
  # transform innermost → outermost. A widget not inside any non-identity island gets the point
  # back UNCHANGED (same object), so this is byte-identical when dormant. Used by the macro
  # toolkit to click an island-inner widget at the on-screen pixel its virtual point maps to:
  # once an ancestor island scales/rotates, a widget's screen position is NOT its bounds
  # position, so `.center()` alone would click the wrong pixel (and miss).
  localPointToScreen: (aPoint) ->
    result = aPoint
    previous = @
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        result = ancestor.transformSpec.mapPoint result, ancestor.bounds
      else if (translation = ancestor.scrollTranslationOfChild?(previous))?
        result = result.add translation
      previous = ancestor
      ancestor = ancestor.parent
    result

  # Affine transforms (§4.6): true if a non-identity TransformFrameWdgt island is on my parent chain.
  # The shared predicate behind the Phase-1-symmetric interaction guards (handles refuse, float-drag
  # escalates to the island). Dormant returns false with no island. (This is the §9 memoization point:
  # a cached inside-an-island flag invalidated on reparent/spec change would replace this walk — banked.)
  _isInsideNonIdentityIsland: ->
    @_enclosingNonIdentityIsland()?

  # Affine transforms (§6 R2): the INNERMOST enclosing non-identity island (TransformFrameWdgt) on my
  # parent chain, or undefined. My (virtual) geometry lives in THIS island's plane — clippedThroughBounds and
  # the mapRectToScreen / screenPointToMyPlane chain are all expressed there — so ephemeral chrome that
  # must track me (a highlight) is parented HERE to composite through the transform for free (rotates +
  # clips with me, §4.6 halo-handle model). Dormant returns undefined (no island) ⇒ the highlight stays a
  # world child, byte-identical. Backs _isInsideNonIdentityIsland above (its one caller is boolean-context).
  _enclosingNonIdentityIsland: ->
    ancestor = @parent
    while ancestor?
      return ancestor if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
      ancestor = ancestor.parent
    undefined

  # The GENERAL siblings of the pair above (paint-time-scroll-translation plan §3.2): is any
  # MAPPING ancestor — a non-identity island OR a scroll-translation provider for the child
  # edge crossed — between me and the screen plane? The island pair stays for ROTATION-specific
  # policy (handles refuse, float-drag escalates, pick-out/re-express); this pair is for
  # PLANE-MAPPING policy — the call sites that must re-express coordinates or re-home overlay
  # chrome whenever my plane is mapped at all, however it is mapped (the drop re-centre gate,
  # the highlight re-home). Off any mapped plane: false / undefined — byte-identical dormant.
  _isInsideMappedPlane: ->
    @_enclosingMappedPlaneRoot()?

  # The INNERMOST mapping ancestor (island or translation provider), or undefined. For an
  # island the root is the island itself (overlay chrome parented into it composites through
  # the transform); for a scrolled pane it is the VIEWPORT — whose add() redirects non-chrome
  # into its contents, i.e. onto the scrolled plane.
  _enclosingMappedPlaneRoot: ->
    previous = @
    ancestor = @parent
    while ancestor?
      return ancestor if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
      return ancestor if ancestor.scrollTranslationOfChild?(previous)?
      previous = ancestor
      ancestor = ancestor.parent
    undefined

  # ---------------------------------------------------------------------------
  # PUBLIC GEOMETRY API UNDER TRANSFORMS — the two-vocabulary law.
  # Canonical spec: docs/archive/affine-geometry-api-plan.md (§1 is the normative text).
  #
  # THE LAW: a widget's geometry API is split into two families distinguishable BY NAME:
  #  - LAYOUT-BOX family (width/height/extent/bounds/boundingBox/position/center/left/…): the
  #    widget's OWN-plane layout box — plane-local, untransformed, integer. Inside an island these
  #    are virtual-plane values; outside, screen values. Transforms NEVER affect them; layout /
  #    settle / arrange / content code operate on these (the load-bearing invariant, plan §4.1).
  #  - SCREEN family (every name contains "screen": screenBounds/localPointToScreen/screenPoint-
  #    ToMyPlane/…): post-transform screen-plane values, possibly FRACTIONAL. NEVER feed them to
  #    layout / moveTo.
  # No non-"screen" method ever returns transformed geometry; no "screen" method ever returns
  # plane-local geometry. (The island's clippedThroughBounds/fullClippedBounds two-faces overrides
  # are framework-internal damage/hit machinery, NOT a public screen-bounds proxy — that is exactly
  # why screenBounds() exists; plan §1.2 / §4.11.)
  # ---------------------------------------------------------------------------

  # SCREEN family. The screen-plane axis-aligned bounding box of my layout box under all ancestor
  # island transforms — an exact, possibly-FRACTIONAL Rectangle (never feed it to layout / moveTo).
  # Walk @parent innermost→outermost (same order as localPointToScreen), mapping the rect's 4
  # corners through each non-identity island's EXACT (unpadded) matrix. NO ancestor-clip
  # intersection (that is mapRectToScreen's damage-lane job) and NO padding. Identity fast path: no
  # non-identity ancestor island ⇒ return @boundingBox() (the same object — zero-alloc dormant,
  # matching boundingBox / localPointToScreen). For the ISLAND itself the walk starts at @parent, so
  # its OWN transform (which applies to its CONTENT, not its slot box) is correctly excluded.
  screenBounds: ->
    result = @boundingBox()
    previous = @
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        result = ancestor.transformSpec.mapRectExact result, ancestor.bounds
      else if (translation = ancestor.scrollTranslationOfChild?(previous))?
        result = result.translateBy translation
      previous = ancestor
      ancestor = ancestor.parent
    result

  # My OWN sugar transform — getter symmetry with the 4C setters setRotationDegrees / setScaleFactor
  # (reads what they wrote). 0 / 1 for a bare widget AND for a widget that is CONTENT of an EXPLICIT
  # (non-sugar) island: the sugar getters mirror the sugar setters' scope. For the TOTAL visual
  # transform of my rendering (through explicit + nested islands) use accumulated*() below.
  rotationDegrees: ->
    @_enclosingSugarIsland()?.transformSpec.rotationDegrees ? 0

  scaleFactor: ->
    @_enclosingSugarIsland()?.transformSpec.scale ? 1

  # The TOTAL visual transform of my rendering: Σ rotationDegrees (normalized to [0,360)) and
  # ∏ scale over ALL ancestor non-identity islands (sugar AND explicit) — the linear part of the
  # accumulated similitude (plan 4D-2a: scalar rotations commute + multiply, so no matrix product /
  # decomposition; summing integer degrees is EXACT). The walk starts at @parent (STRICT ancestors),
  # and my own sugar island IS an ancestor, so my own transform is included. ONE greppable
  # accumulation shared with the pick-out (_pickOutRotatedFigureNoSettle) and drop-re-express
  # (_reExpressFigureForPlaneOfNoSettle) verbs. Off any island ⇒ 0 / 1.
  # Deliberately NO translation arm (unlike the mapping walks above): a scroll translation
  # contributes no rotation and no scale, so these two are complete as they are.
  accumulatedRotationDegrees: ->
    total = 0
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        total = total + ancestor.transformSpec.rotationDegrees
      ancestor = ancestor.parent
    ((total % 360) + 360) % 360

  accumulatedScaleFactor: ->
    product = 1
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        product = product * ancestor.transformSpec.scale
      ancestor = ancestor.parent
    product

  # Public, macro-callable predicate: true iff at least one STRICT ancestor island has a non-identity
  # spec — i.e. "my layout-box geometry does not coincide with my screen appearance". For an island
  # itself: false (its slot box IS plane geometry — its CONTENT is what transforms). The blessed
  # public name for the private _isInsideNonIdentityIsland (macros cannot call `_`-prefixed members).
  isVisuallyTransformed: ->
    @_enclosingNonIdentityIsland()?

  # ---------------------------------------------------------------------------
  # Affine transforms (§6 Phase 4B-universal): the halo ROTATION PROTOCOL. The rotate handle drives
  # ANY widget through these three, so it needs no knowledge of whether its target is a plain widget
  # (rotates by MATERIALIZING a sugar island via setRotationDegrees) or an explicit TransformFrameWdgt
  # island (which overrides all three to drive its own spec directly). Base = the plain-widget case.
  # ---------------------------------------------------------------------------
  # The SCREEN pivot for a halo rotation: the FIXED POINT of my sugar island's rotation. That fixed
  # point is the island's ANCHOR (its transformSpec._anchorFor) — which for an un-pinned island is my
  # bounds centre, but after §7.5 Bug D a collapse/resize can PIN it OFF the centre, so we must ask the
  # island for its true anchor rather than assume the centre (that assumption was one of the two
  # trip-ups this API unit exists to close — geometry-api-plan §1.4). Delegate to the island's own
  # screenAnchor() (the authoritative anchor→screen map). Bare-widget (no island yet, e.g. the FIRST
  # halo grab) fallback: my centre mapped to screen — dormant that is my plain centre, and it matches
  # the slot-centre anchor the about-to-materialise sugar island will use.
  rotationHalo_screenAnchor: ->
    island = @_enclosingSugarIsland()
    return island.screenAnchor() if island?
    @localPointToScreen @center()

  # My current halo rotation in degrees: my own sugar transform (the public getter), or 0 if I am not
  # (yet) wrapped — so a re-grab continues from where a prior rotation left off. rotationHalo_* is the
  # documented halo-consumer family; this stays as its blessed alias of rotationDegrees().
  rotationHalo_currentDegrees: ->
    @rotationDegrees()

  # Apply a halo rotation: the 4C property sugar (materialises a sugar island on demand, removes it at
  # identity). Self-settling; called per drag from the (allowlisted) rotate-handle stream — a 'slot'
  # island settles to nothing, so per-call settling is a no-op there.
  rotationHalo_apply: (deg) ->
    @setRotationDegrees deg

  # ---------------------------------------------------------------------------
  # Affine transforms (§6 Phase 4C): the Lively-flavoured property sugar. Rotate / scale ANY widget
  # by MATERIALIZING an enclosing TransformFrameWdgt island on demand, and REMOVING it when the
  # transform returns to identity — so the widget's structural identity is restored at identity (the
  # dormant guarantee + serialization cleanliness). These wrap the island's own setRotation/setScale.
  # The names are deliberately NOT the island's setRotation/setScale, so there is no layering-gate
  # name collision and calling them on a bare widget is unambiguous. Public tier owns the single
  # settle (the wrap/adjust/unwrap all run NoSettle inside it).
  # ---------------------------------------------------------------------------
  setRotationDegrees: (deg) ->
    @_settleLayoutsAfter => @_setRotationDegreesNoSettle deg

  _setRotationDegreesNoSettle: (deg) ->
    @_applyTransformSugarNoSettle deg, undefined

  setScaleFactor: (s) ->
    @_settleLayoutsAfter => @_setScaleFactorNoSettle s

  _setScaleFactorNoSettle: (s) ->
    # ⚠ `undefined` here is the degOrNil VALUE — "leave the rotation unchanged" — not a skip to
    # reach a later argument: this is a two-slot PARTIAL-UPDATE record, and its mirror one line
    # above writes the same absence in the other slot. No order removes it, so it is not a hole
    # under R3 (docs/architecture/constructor-and-parameter-conventions.md).
    @_applyTransformSugarNoSettle undefined, s

  # shared core: find-or-materialize the enclosing sugar island, apply the (partial) spec change,
  # then dematerialize if it returned to identity. degOrNil / sOrNil: undefined means "leave unchanged".
  _applyTransformSugarNoSettle: (degOrNil, sOrNil) ->
    island = @_enclosingSugarIsland()
    if !island?
      # nothing exists yet: materialize only if the target is non-identity (else it is a no-op).
      deg = degOrNil ? 0
      s = sOrNil ? 1
      return if (deg % 360 == 0) and (s == 1)
      island = @_materializeSugarIslandNoSettle()
    island._setRotationNoSettle degOrNil if degOrNil?
    island._setScaleNoSettle sOrNil if sOrNil?
    @_dematerializeSugarIslandIfIdentityNoSettle island

  # the enclosing island IFF it was materialized by the sugar AND wraps EXACTLY me (so adjusting it
  # only affects me). An explicitly-authored island (or one wrapping a larger subtree) is NOT reused —
  # it stays put; the sugar wraps a fresh island around just me. The sole-content test is
  # _enclosingSoleContentIsland's — this just adds the sugar gate up front (only islands define
  # _materializedBySugar, so the guard also rejects any non-island parent before the delegate runs).
  _enclosingSugarIsland: ->
    return undefined if !@parent?._materializedBySugar
    @_enclosingSoleContentIsland()

  # wrap me in a fresh sugar island IN PLACE: the island's slot box becomes my current bounds and I
  # become its single free-floating child, keeping my absolute position (virtual ≡ screen at identity).
  # The island inherits MY former index AND layoutSpec in my parent — so wrapping is position-invariant
  # (no z-order raise on the desktop, no slot reshuffle in an arranged panel). Capture both BEFORE the
  # reparent (which shrinks the sibling list). Orphan-safe: a parentless widget just gets an orphan island.
  _materializeSugarIslandNoSettle: ->
    formerParent = @parent
    myIndex = formerParent?.children.indexOf @
    myLayoutSpec = @layoutSpec
    # A sugar island TRACKS its single content's size (rough edge R3): materialize the tracking capability
    # variant, so resizing the wrapped widget grows the slot instead of clipping. TrackingTransformFrameWdgt
    # IS-A TransformFrameWdgt (every instanceof / serialization / dematerialize path is unchanged).
    island = new TrackingTransformFrameWdgt()
    island._materializedBySugar = true
    island.bounds = new Rectangle @left(), @top(), @right(), @bottom()
    # LENS pre-seed (island content preferences): the island is homed EMPTY first (order
    # comment below), so a FrameWdgt former parent's mount guard would find no knob on it
    # and create fresh BASE preferences — share MY content-stack knob NOW, so the mount
    # operates on the one object. The island's lens initialiser overrides cover every flow
    # where the island already holds its content when asked; this covers the one seam that
    # asks during the empty window.
    island._contentStackSpec = @_contentStackSpec if @_contentStackSpec?
    # HOME the (empty) island into MY former slot + spec FIRST, THEN reparent me into it. Order matters:
    # _addNoSettle fires the added widget's _reactToBeingAdded, and a widget whose appearance is DERIVED from
    # its nesting (a FrameWdgt's internal/external skin, via isInternal looking THROUGH this _materializedBySugar
    # island to the real parent) must derive against the island's TRUE parent -- so the island has to be homed
    # before I move in. The reverse order derived my skin while the island was still a detached root (parent
    # undefined), flipping a tilted window to the wrong skin. The final tree is identical either way (island ends at
    # myIndex, me free-floating inside it); homing an empty tracking island is safe (its _reLayoutChildren
    # no-ops with no content, and __add skips the extent recalculation). Orphan-safe: no formerParent => the
    # island stays a detached root and I move into it, exactly as before.
    formerParent?._addNoSettle island, atIndex: myIndex, layoutSpec: myLayoutSpec   # drop the (empty) island into MY former slot + spec (incl. a stretch record; my kept content-stack knob stays MINE — container reads find the riding spec slot-first, see contentStackSpec)
    island._addNoSettle @                                      # then reparent me into the now-homed island (free-floating child)
    island

  # if the sugar island is back at identity, unwrap: reparent me back into the island's parent at the
  # island's index + layoutSpec (position-invariant, the exact inverse of the wrap), preserve my absolute
  # position (identity ⇒ screen-coincident), then drop the now-empty island. Restores the exact
  # pre-materialize structure — the round-trip leaves no island behind and no z-order/slot change.
  _dematerializeSugarIslandIfIdentityNoSettle: (island) ->
    return if !island._materializedBySugar or !island.transformSpec.isIdentity()
    islandParent = island.parent
    return if !islandParent?
    islandIndex = islandParent.children.indexOf island
    islandLayoutSpec = island.layoutSpec
    pos = @position()
    islandParent._addNoSettle @, atIndex: islandIndex, layoutSpec: islandLayoutSpec   # reparent me back into the island's slot + spec (incl. a stretch record)
    @_moveToNoSettle pos                                          # preserve my absolute position (desktop case)
    # R2 (§6 affine): a highlight (or any layout-inert ephemeral chrome, isEphemeral) parented INTO this
    # island while it was rotated must ride OUT before we drop it — else _destroyNoSettle just nulls
    # island.children (it does not orphan/clean them), leaving the world's highlight bookkeeping dangling
    # on a dead widget. Dematerialize only happens at identity, where virtual ≡ screen, so each inert
    # child's bounds are already screen-coincident: re-home it to the island's parent at unchanged
    # position (the reconciler re-derives the exact parent next tick regardless). Iterate a COPY since
    # _addNoSettle mutates island.children. (The content @ is already out, so these are only chrome.)
    for inertChild in island.children.slice() when inertChild.isLayoutInert?()
      inertChildPos = inertChild.position()
      islandParent._addNoSettle inertChild                       # free-floating (default layoutSpec)
      inertChild._moveToNoSettle inertChildPos
    island._destroyNoSettle()                                    # drop the now-empty island (I was inserted before it)

  # ---------------------------------------------------------------------------
  # Affine transforms (§6 Phase 4D-2a): PICK-OUT. When a widget inside a non-identity island is grabbed,
  # resolve the FIGURE that comes onto the hand. Two cases (the grab dispatch calls this on the loose unit
  # the normal grabsToParentWhenDragged rules already picked — a window title resolves to the window, a
  # loose content child to the child):
  #   • I am my innermost island's SOLE content ⇒ grabbing me ≡ grabbing that island (and any outer islands
  #     it is in turn the sole content of), so REUSE the existing island (climb to the outermost sole-content
  #     island) — no churn, Phase-1's whole-figure grab. macroTransformFrameScaledDragged relies on this.
  #   • I am a genuine SUB-part (my innermost island wraps a larger subtree) ⇒ extract me and wrap me in a
  #     FRESH island carrying the accumulated similitude (_pickOutRotatedFigureNoSettle).
  # Off any island ⇒ returns me unchanged (byte-identical dormant). NoSettle: the grab's own settle covers
  # the extraction's re-fit of my former container.
  _resolvePickOutFigureNoSettle: ->
    island = @_enclosingNonIdentityIsland()
    if !island?
      # paint-time scroll (plan Phase 2c): grabbed OUT of a scrolled plane (no island on my
      # chain), my bounds are plane-local while the hand carries me on the SCREEN plane —
      # re-home me at my on-screen position so the lift has no jump (the translation-only
      # analogue of the island pick-out's centre-preserving re-home below). Dormant path:
      # off any mapped plane localPointToScreen returns the SAME object, so nothing moves.
      planePos = @position()
      screenPos = @localPointToScreen planePos
      @_applyMoveTo screenPos.round() if screenPos isnt planePos
      return @
    kids = island.childrenNotHandlesNorCarets()
    if kids? and kids.length == 1 and kids[0] == @
      # sole content: reuse; climb to the outermost island of the sole-content chain
      figure = island
      loop
        outer = figure._enclosingNonIdentityIsland()
        break if !outer?
        outerKids = outer.childrenNotHandlesNorCarets()
        break if !(outerKids? and outerKids.length == 1 and outerKids[0] == figure)
        figure = outer
      # §7.5 Bug G (reparent-transparency, PICK-UP NORMALIZATION): a PINNED anchor (Bug-D
      # anchor-stability, set by a tracked resize) breaks every downstream apply-site that assumes the
      # pivot is the slot centre — the 2b-i relative re-spec pivots about the pinned anchor and the 4D-1
      # placement homes the SLOT centre, so a tilted+RESIZED figure dropped into a counter-tilted
      # container lands off by O((I−sR)(A−centre)) (probe: −50,+49 px at 45°/−45°; the un-resized
      # control is exact). Normalize at the pick-up seam: re-express the similitude as its equivalent
      # undefined-anchor form (identical rendering, ≤1px rounding), so the ENTIRE hand-carry pipeline
      # (drag, re-spec, placement, re-home) runs its already-exact centre-pivot math.
      figure._normalizePinnedAnchorNoSettle()
      # §7.5 Bug F (reparent-transparency, PICK half): the reused figure keeps its user-observed look
      # when lifted to the hand (the identity plane). When the figure still has non-identity ANCESTOR
      # islands (e.g. a compensating wrapper living inside a tilted container), its own spec alone would
      # render differently on the hand than the accumulated look it had nested — so fold the ancestors
      # into its spec (degrees add, scales multiply — the 4D-2a scalar-composition finding) and re-home
      # so its visual centre stays put. Off nested planes (a figure sitting directly on the desktop — the
      # entire pre-Bug-F population) both accumulators are exactly 0/1 and this block is byte-identical
      # dormant. The transient mid-gesture re-spec is never painted (the synchronous-gesture argument):
      # both centre points below are NUMERIC values used only to compute the re-homed bounds that render
      # on the identity hand plane AFTER the grab reparents (which preserves numeric bounds), so they need
      # not share a coordinate frame here. UNDEFINED-anchor correct by that numeric argument; PINNED-anchor
      # correct because the move-level override (TransformFrameWdgt._applyMoveBy et al.) rides the anchor
      # on the re-home _applyMoveTo, restoring the fixed-point property (probe-verified 0.5px, scenarios
      # 4 + 5b — see docs §7.5 Bug F).
      degAnc = figure.accumulatedRotationDegrees()
      sAnc = figure.accumulatedScaleFactor()
      if !(degAnc == 0 and sAnc == 1)
        # visual centre BEFORE (pinned-anchor-safe READ: own-map via mapPoint honours a pinned anchor,
        # then up the ancestor planes)
        screenCentreBefore = figure.parent.localPointToScreen figure.transformSpec.mapPoint(figure.center(), figure.bounds)
        figure._setRotationNoSettle (((figure.transformSpec.rotationDegrees + degAnc) % 360) + 360) % 360
        figure._setScaleNoSettle figure.transformSpec.scale * sAnc
        if figure._materializedBySugar and figure.transformSpec.isIdentity()
          # the ancestors exactly cancel my spec (the drop→pick round-trip): the figure is now an IDENTITY
          # compensating sugar wrapper. Position it at the visual centre and RETURN it — determineGrabs
          # dissolves it self-settling before the grab, exactly as the drop side dissolves its re-expressed
          # sugar figure via the self-settling wrap AFTER target.add. The dissolve reparents the wrapper's
          # content into its ATTACHED parent (an off-settle layout mutation → a careless end-of-cycle push
          # if done bare), and this is a NoSettle method that must not self-settle (rule [G]) — so the
          # settle belongs at the non-NoSettle caller, NOT here. Dematerialize preserves the content's
          # position and the sugar wrapper hugs its content, so positioning the wrapper positions the
          # content. (The other pick-out paths reparent into a FRESH orphan island, which is audit-exempt.)
          figure._applyMoveTo screenCentreBefore.round().subtract figure.extent().floorDivideBy 2
          return figure
        # non-identity total: post-reparent the figure renders its own map at its numeric bounds — home
        # its visual centre back to where it was. The move-level anchor-ride (see the block comment)
        # keeps this exact for a pinned anchor too; undefined anchor is exact by the numeric argument.
        centreAfter = figure.transformSpec.mapPoint(figure.center(), figure.bounds)
        figure._applyMoveTo figure.position().add (screenCentreBefore.subtract centreAfter).round()
      return figure
    # genuine sub-part: extract + wrap in a fresh island
    return @_pickOutRotatedFigureNoSettle()

  # Affine transforms (§6 Phase 4D-2a): extract me from my island chain into a FRESH sugar-style island that
  # carries the ACCUMULATED similitude of ALL my ancestor islands, positioned so I stay screen-coincident
  # (no jump). Returns the fresh island for the hand to grab. The accumulated map's LINEAR part is exactly
  # (scale = ∏ ancestor scales, rotation = Σ ancestor degrees) — scalar rotations commute + multiply, so no
  # matrix product / decomposition and no TransformSpec.compose is needed (and summing integer degrees is
  # EXACT, dodging the atan2 wobble 4B had to quantize). Two similitudes with the same linear part differ
  # only by a translation, so matching ONE point (my centre) makes the fresh figure coincide with the
  # original everywhere: the fresh island pivots on its slot centre (= my centre), which renders my centre at
  # my (virtual) centre, and localPointToScreen(centre) — which composes all N ancestors — is where it was,
  # so translating by their difference re-homes the whole figure. For n=1 this is pixel-identical; for n≥2 it
  # resamples once instead of per-level (crisper — a new state anyway).
  _pickOutRotatedFigureNoSettle: ->
    # the accumulated similitude of ALL my ancestor islands (∏ scales, Σ degrees normalized) — the
    # public getters ARE this walk, extracted (byte-equivalent). Read them BEFORE _addNoSettle re-parents
    # me (they walk MY current ancestors).
    accScale = @accumulatedScaleFactor()
    accDeg = @accumulatedRotationDegrees()
    screenCentreBefore = @localPointToScreen @center()     # my on-screen centre BEFORE extraction
    island = new TrackingTransformFrameWdgt()
    island._materializedBySugar = true                     # behaves as a sugar island (auto-unwrap at identity, scalar serialization)
    island.transformSpec = new TransformSpec accDeg, accScale
    island.bounds = new Rectangle @left(), @top(), @right(), @bottom()   # slot = my bounds ⇒ slot centre = my centre
    island._addNoSettle @                                  # extract me from my old container into the fresh island
    island._applyMoveTo island.position().add (screenCentreBefore.subtract @center())   # re-home so my centre lands where it was
    island

  # Affine transforms (§7.5 Bug B latent 2, Option B): the enclosing island IFF it wraps EXACTLY me —
  # sugar OR explicitly authored. The ONE sole-content predicate (_enclosingSugarIsland delegates
  # here, adding its `_materializedBySugar` gate): for re-homing/classification, a sole-content
  # transform island is transform plumbing around ONE figure regardless of who authored it. Sugar-ONLY machinery
  # (materialize/dissolve/unwrap, halo anchor) keeps using _enclosingSugarIsland — an explicit island
  # must never auto-dissolve or be reused by the property sugar.
  _enclosingSoleContentIsland: ->
    p = @parent
    return undefined if !(p instanceof TransformFrameWdgt)
    kids = p.childrenNotHandlesNorCarets()
    return p if kids? and kids.length == 1 and kids[0] == @
    undefined

  # Affine transforms (§7.5 Bug B + latent 2, Option B): the outermost island of which I am (transitively)
  # the SOLE content — sugar or explicit — i.e. the whole "figure" that a RE-HOME (close-to-bin,
  # reopen, a future "send to desktop") must move AS A UNIT so its rotation/scale travels with it — or ME
  # when I am not island-wrapped. This is the re-home SIBLING of the pick-OUT verb
  # _resolvePickOutFigureNoSettle (4D-2a): pick-OUT may EXTRACT a sub-part onto the hand; re-home never
  # extracts — it moves the intact figure. ONE greppable home for every re-home site: route
  # close/reopen/eject through this, NEVER inline the climb. Pure (no mutation, no settle). Explicit
  # sole-content islands travel too (Option B): the island IS the authored transform, so leaving it behind
  # would strand an empty invisible frame AND lose the transform across close/reopen — the same principle
  # that locked Bug B's model (a) for sugar. A MULTI-child explicit island is not sole-content ⇒ not
  # climbed (content travels bare, siblings stay). Off any island ⇒ me.
  _enclosingIslandFigure: ->
    figure = @
    loop
      island = figure._enclosingSoleContentIsland()
      break if !island?
      figure = island
    figure

  # The container I really live in, seen THROUGH my sole-content island(s) — my @parent off any island
  # wrap, or the figure's parent when I am tilted/scaled (sugar) or explicitly islanded. The ONE
  # look-through idiom for "where does this widget really belong" (§7.5 Bug A/B + latent 2 Option B): a
  # widget's CLASSIFICATION must not be fooled by transform plumbing. FrameWdgt.isInternal
  # (internal/external skin) and BinWdgt.holds (bin residency) both classify against THIS, so a
  # tilted or explicitly-islanded widget is judged by its real home, not the island.
  _parentThroughIslands: ->
    @_enclosingIslandFigure().parent

  # Affine transforms (§6 Phase 4D-2b): the PAYLOAD-side look-through for drop POLICY. When a widget is
  # rotated/scaled it rides the hand as a transient _materializedBySugar TransformFrameWdgt, which HIDES its
  # content's class from every drop-policy predicate -- so a tilted WINDOW arrives as a "transform frame" and
  # bypasses the dwell-to-arm gate (requiresDeliberateEmbedding), sticky re-embed, and the wantsDropOfChild
  # type checks. This returns my sole content THROUGH sugar wrapper(s) so those predicates see the real payload
  # class; off any sugar figure (a plain widget, or an EXPLICIT authored island -- a real container, not
  # sugar) it returns ME. The payload-side sibling of _parentThroughIslands (the container-side
  # look-through). Consult it ONLY where the payload's CLASS/policy is inspected -- NEVER at geometry/add sites,
  # which must keep the figure (it is what actually gets placed + parented).
  _dropPolicyProxy: ->
    figure = @
    loop
      break if !(figure instanceof TransformFrameWdgt) or !figure._materializedBySugar
      content = figure.childrenNotHandlesNorCarets()?[0]
      break if !content?
      figure = content
    figure

  # Affine transforms (§6 Phase 4D-2b): RE-EXPRESS a dropped SUGAR FIGURE relative to the plane it lands in.
  # When a _materializedBySugar figure (from a 4D-2a pick-out or a 4C rotate/scale) is float-dropped into a
  # container that lives inside a non-identity island, its spec is ABSOLUTE (Σ degrees / ∏ scales over its
  # former ancestor islands) but it is about to composite THROUGH the destination plane's transform as well --
  # so without re-expression a 30° figure dropped into a 30° window would render at 60° (transforms compose;
  # the 4D-1 block maps only POSITION). Re-express the figure's spec RELATIVE to the destination plane:
  #     rel_r = figure.deg − Σ(destination-plane island degrees),  rel_s = figure.scale ÷ ∏(… island scales)
  # so composited through the plane it renders at its ORIGINAL absolute look. When rel is identity (a
  # return-to-SAME-plane round-trip: x−x, x÷x are IEEE-exact and the absolute spec was BUILT as Σ/∏ over the
  # same chain in the same order at pick-out) the figure becomes an identity sugar island -- the drop's
  # post-add _unwrapIfIdentitySugarNoSettle then dissolves it (the 4C auto-unwrap), so a round-trip leaves no
  # island behind. Returns me (the re-spec'd figure) for the 4D-1 position-map + target.add to place. SCOPE
  # (locked): ONLY _materializedBySugar figures re-express; an EXPLICIT island nest-composes like any content
  # (the user authored that frame -- mutating its spec on drop would rewrite their structure). Off any sugar
  # figure, or into an identity plane, a no-op returning me unchanged: a non-island payload lacks
  # _materializedBySugar (⇒ byte-identical dormant), and a rotated figure dropped onto the plain desktop
  # re-specs to its own value (the setters early-return unchanged). Inverse of _pickOutRotatedFigureNoSettle's
  # accumulation; NoSettle -- the drop's target.add carries the settle.
  _reExpressFigureForPlaneOfNoSettle: (target) ->
    # §7.5 Bug F (reparent-transparency, DROP half): EVERY payload keeps the look it had on
    # the hand — not just sugar figures. A bare payload is a figure whose own transform is identity, so
    # its relative similitude vs the destination plane is (0 − plane, 1/plane): when the plane is
    # non-identity, wrap it in a fresh COMPENSATING sugar island at rel so it does not visibly rotate/
    # scale at the moment of drop ("what you see while dragging is what you get"). Explicit (non-sugar)
    # islands still nest-compose untouched (the 4D-2b scope rule).
    if !@_materializedBySugar
      return @ if @ instanceof TransformFrameWdgt   # explicit island payload: nest-compose, never re-spec
      degPlane = target.accumulatedRotationDegrees()
      sPlane = target.accumulatedScaleFactor()
      return @ if degPlane == 0 and sPlane == 1     # identity plane — the common path, byte-identical dormant
      relDeg = (((0 - degPlane) % 360) + 360) % 360
      island = new TrackingTransformFrameWdgt()
      island._materializedBySugar = true
      # explicit 'slot' (claimsSpace arc S2, owner decision 2026-07-17): a COMPENSATING wrapper is
      # invisible look-correction plumbing (it exists so the payload does NOT appear to rotate at
      # the drop moment), not a user-authored transform — it must never claim layout space in the
      # tilted container it lands in. The 4C/4D-2a sugar islands, by contrast, FOLLOW the
      # 'footprint' default (they carry a user-visible rotation — D1's mainstream case).
      island.transformSpec = new TransformSpec relDeg, 1 / sPlane, "slot"
      # slot = my bounds (I am on the hand, screen coords); the wrapper pivots on the slot centre so my
      # on-screen look is unchanged, and the 4D-1 block below places the wrapper by its visual centre.
      island.bounds = new Rectangle @left(), @top(), @right(), @bottom()
      island._addNoSettle @
      return island
    # The destination plane's linear part: the accumulated similitude over the non-identity islands the
    # dropped payload will composite through -- target's ancestors. target is never itself a non-identity
    # island (islands refuse drops, so dropTargetFor climbs past them), so target.accumulated*() (STRICT
    # ancestors) equals the target-inclusive walk this used to inline -- byte-equivalent (a normalized Σ
    # differs from the raw sum only by a multiple of 360, which relDeg's own mod cancels; the ∏ is the
    # same ordered product). Mirrors _pickOutRotatedFigureNoSettle's accumulation (this is its inverse).
    degPlane = target.accumulatedRotationDegrees()
    sPlane = target.accumulatedScaleFactor()
    relDeg = (((@transformSpec.rotationDegrees - degPlane) % 360) + 360) % 360
    relScale = @transformSpec.scale / sPlane
    @_setRotationNoSettle relDeg   # the island's own spec cores; each early-returns when unchanged (identity
    @_setScaleNoSettle relScale    # plane ⇒ no-op ⇒ dormant byte-identical). rel identity ⇒ I become identity.
    @

  # Affine transforms (§6 Phase 4D-2b): the UNWRAP half of the drop re-expression, invoked on a JUST-DROPPED
  # figure. Self-settling twin of _unwrapIfIdentitySugarNoSettle -- the drop calls it AFTER target.add's settle
  # has closed, so the dematerialize's NoSettle re-home needs its own settle (else a careless end-of-cycle
  # push). The canonical thin wrap; the core self-guards, so a non-identity / non-sugar receiver just returns
  # itself (the settle then flushes nothing).
  _unwrapIfIdentitySugar: ->
    @_settleLayoutsAfter => @_unwrapIfIdentitySugarNoSettle()

  # If _reExpressFigureForPlaneOfNoSettle re-spec'd me to identity (rel was identity) I am now a
  # _materializedBySugar island at identity nested in my drop target, so I should DISSOLVE -- my content
  # becomes the target's own child at my slot, no nested-island buildup (the 4D risk-2 round-trip guarantee).
  # This is EXACTLY the 4C auto-unwrap, so I delegate to the proven _dematerializeSugarIslandIfIdentityNoSettle
  # (which reparents my sole content into my parent at my slot + preserves its position + rides inert chrome
  # out + drops me) rather than re-homing by hand -- and I am placed by the SAME 4D-1 path a non-identity
  # re-expressed figure uses, so there is no bespoke positioning. Returns my content on unwrap, else me
  # unchanged (not a sugar island, or still non-identity ⇒ I stay a relative wrapper). Off any island ⇒ me.
  _unwrapIfIdentitySugarNoSettle: ->
    return @ if !(@_materializedBySugar and @transformSpec?.isIdentity())
    content = @childrenNotHandlesNorCarets()?[0]
    return @ if !content?
    content._dematerializeSugarIslandIfIdentityNoSettle @
    content

  # Affine transforms (§6 Phase 4D-2a): the shared figure resolution for BOTH pick-up entry points — the
  # drag pipeline (ActivePointerWdgt.determineGrabs) and the menu "pick up" item (pickUpMenuAction) — so
  # the two cannot drift. Two steps:
  #   1. Resolve the FIGURE that comes onto the hand (_resolvePickOutFigureNoSettle): when I am grabbed from
  #      inside a non-identity island, either REUSE the existing island (I am its sole content — Phase-1's
  #      whole-figure grab, no churn) or a FRESH island carrying the accumulated N-deep similitude (I am a
  #      genuine sub-part, extracted + re-homed screen-coincident). Off any island this returns me UNCHANGED
  #      ⇒ byte-identical dormant. NoSettle: the extraction's re-fit of my former container rides the
  #      caller's own grab settle (the drag's @grab, pickUpMenuAction's pickUp).
  #   2. §7.5 Bug F (reparent-transparency): a drop→pick round-trip can leave an IDENTITY compensating sugar
  #      wrapper (the -deg wrapper's spec folded to identity against its +deg container on pick-out).
  #      DISSOLVE it — self-settling (_unwrapIfIdentitySugar) — so the BARE content is what goes on the hand,
  #      the sibling of the drop side's post-add self-settling unwrap. Guarded so it fires ONLY for the
  #      identity round-trip wrapper: a plain widget has no _materializedBySugar, a genuinely rotated/scaled
  #      figure is non-identity. (The dissolve reparents into the ATTACHED parent — a settling layout
  #      mutation — which is why THIS is a non-NoSettle helper and the pick-out resolver stays NoSettle.)
  # Returns the figure to grab.
  # DECLARED deferred settle (claimsSpace arc S2): step 1's Bug-F ancestor-fold calls the island's
  # _set*NoSettle cores, whose claim reflow (_invalidateLayout) fires now that sugar figures
  # default to 'footprint' — an off-settle push the caller's own grab settle carries (the drag's
  # @grab, pickUpMenuAction's pickUp), exactly as step 1's contract above always stated. The
  # declaration window makes that contract explicit to the end-of-cycle capstone audit.
  _resolvePickUpFigure: ->
    figure = @_deferredSettleDeclare => @_resolvePickOutFigureNoSettle()
    if figure._materializedBySugar and figure.transformSpec?.isIdentity()
      # nosettle-sanctioned: called ONLY from event-stream contexts (the drag pipeline determineGrabs and
      # the menu pickUpMenuAction), never mid-pass, so the deliberate self-settling dissolve is correct —
      # and keeping it self-settling (rather than the NoSettle core) preserves determineGrabs' exact,
      # byte-identical pre-extraction cadence (this whole two-step was inline there before).
      figure = figure._unwrapIfIdentitySugar()
    figure

  # Widget accessing - simple changes: translate me + my children + repaint.
  # (Stage 5, 2026-07-01) The re-fit seam this used to fire is DELETED -- the settle loop now re-fits my tracking
  # container AFTER I settle (see _reFitMyTrackingContainerAfterSettle) -- so this immediate mutator is PURE geometry
  # now (what the FLOWRULE always wanted), a thin wrapper over the shared move core _applyMoveByBase. The "AndNotify"
  # suffix is historical -- but this twin is NOT collapsible into _applyMoveByBase (2026-07-01 twin-collapse verdict):
  # it is the polymorphic DISPATCH POINT for the ClippingAtRectangularBoundsMixin scroll-optimization OVERRIDE
  # (which repaints via @_changed, not @_fullChanged) and TransformFrameWdgt's anchor-ride override, whereas bare _applyMoveByBase
  # is the uniform base translate the top-down arrange calls for leaf children. Folding the overrides onto _applyMoveByBase
  # would route arrange moves through them on clipping panels and change their damage regions -- so the two names are a
  # genuine dispatch distinction, not redundant twins. (Only the truly-redundant SILENT-commit twins collapsed in that
  # pass: _commitExtentAndNotify folded into the __commitExtent leaf, _commitBoundsAndNotify + _applyGrantedBounds into _commitBounds.)
  _applyMoveBy: (delta) ->
    @_applyMoveByBase delta

  # The bare move primitives _applyMoveByBase / _applyMoveToBase, used by the top-down arrange for LEAF children: translate me
  # + my children + repaint via the UNIFORM base translate. A leaf child is placed through these rather than
  # _applyMoveBy / _applyMoveTo precisely so its move takes the base path and NOT the
  # ClippingAtRectangularBoundsMixin / TransformFrameWdgt overrides _applyMoveBy dispatches to (see the
  # _applyMoveBy note above -- that override difference is why the two are not collapsible). _applyMoveByBase is
  # the shared move core (returns true iff it actually moved).
  _applyMoveByBase: (delta) ->
    return false if delta.isZero()
    @__breakMoveResizeCaches()
    @_fullChanged()
    @bounds = @bounds.translateBy delta
    @_assertBoundsWellFormed "_applyMoveByBase"   # move ROOT: children inherit this (finite) delta via __commitMoveBy, so the root check covers the subtree
    @children.forEach (child) ->
      child.__commitMoveBy delta
    return true

  _applyMoveToBase: (aPoint) ->
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      @_applyMoveByBase delta

  __commitMoveBy: (delta) ->
    @__breakMoveResizeCaches()
    @bounds = @bounds.translateBy delta
    @children.forEach (child) ->
      child.__commitMoveBy delta
  
  __breakMoveResizeCaches: ->
    # EMPTY-HAND CARVE-OUT (load-bearing -- measured: hover hit-testing stays ~96%-cached
    # because of this): a BARE pointer move must NOT bump geometryVersion, or every mouse
    # move would invalidate every version-keyed bounds cache in the world. The hand
    # compensates locally: its fullBounds / fullClippedBounds / clippedThroughBounds /
    # clipThrough overrides all recompute fresh (ActivePointerWdgt), so the hand never
    # serves a stale version-keyed bounds. With children (mid float-drag) the bump proceeds
    # as normal.
    if @ == world.hand
      if @children.length == 0
        return
    WorldWdgt.geometryVersion++

  # The desktop's position-only imposition from the child's StretchLayoutSpec (the panel
  # consumer instead GRANTS whole boxes through the child's _reLayout — see
  # StretchablePanelWdgt._reLayout; the desktop moves without sizing, so it keeps this
  # imposer).
  _moveInDesktopToFractionalPosition: (boundsOfParent) ->
    if !boundsOfParent?
      boundsOfParent = @parent.bounds

    # we do one dimension at a time here for a subtle reason: if
    # say a window has the left side beyond the left side of the desktop
    # then its recorded left-edge fraction is NEGATIVE
    # and as one shrinks the browser the window comes TO THE RIGHT.
    # This might make some mathematical sense but is very unintuitive so
    # we just don't move widgets along the dimensions that have a negative
    # edge fraction
    # ⚠ Fractional IMPOSITION — here and on the panel's granted path — MUST ride the
    # polymorphic PLAIN twins (_applyMoveTo / _applyExtent), never the Base twins:
    # FALSIFIED BOTH WAYS (auto-bookkeeping arc P1, 2026-08-05): a TransformFrameWdgt
    # island OVERRIDES _applyMoveTo to ride its pinned anchor along (Bug-G), so a
    # Base-twin imposition strands the anchor and renders a tilted stretch child offset;
    # and _applyExtent's schedule-valve gives a resized composite child the deferred
    # second re-lay its interior (wrapping text, nested scroll) needs to converge -- on
    # the Base twin both classes of test churned. Imposition is arrange-driven but its
    # TARGETS are arbitrary figures, so the polymorphic dispatch is load-bearing (base
    # Widget._reLayout's granted path routes through exactly these twins, which is what
    # sanctions the panel's grant shape).
    spec = @layoutSpec
    if spec.leftFraction > 0
      @_applyMoveTo new Point boundsOfParent.left() + Math.round(spec.leftFraction * boundsOfParent.width()), @top()
    if spec.topFraction > 0
      @_applyMoveTo new Point @left(), boundsOfParent.top() + Math.round(spec.topFraction * boundsOfParent.height())

  
  # this one actually immediately changes the position and
  # bounds of widgets
  _applyMoveTo: (aPoint) ->
    delta = aPoint.toLocalCoordinatesOf @
    if !delta.isZero()
      @_applyMoveBy delta

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  moveTo: (aPoint) ->
    @_settleLayoutsAfter => @_moveToNoSettle aPoint

  # Non-settling move core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredPosition + invalidate,
  # no flush -- rides an OUTER settle. Callers: public moveTo (self-settles) + _moveToDeferredSettle
  # (rides the ONE end-of-cycle flush). Feature code uses those PUBLIC entrypoints, never this core directly.
  # (The per-move-step fractional remember that used to sit here recorded PRE-flush geometry -- the
  # staleness class the post-flush re-record drain fixed; the handle's release enqueue is the one
  # gesture record now, so the hook and its widgetStartingTheChange plumbing are deleted.)
  _moveToNoSettle: (aPoint) ->
    if not @isFreeFloating()
      return
    else
      aPoint = aPoint.round()
      newX = Math.max aPoint.x, 0
      newY = Math.max aPoint.y, 0
      newPos = new Point newX, newY
      unless @position().equals newPos
        @desiredPosition = newPos
        @_invalidateLayout()

  # PRIVATE DEFERRED-SETTLE move entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _moveToNoSettle core).
  _moveToDeferredSettle: (aPoint) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_moveToNoSettle aPoint
    else
      @_settleLayoutsAfter => @_moveToNoSettle aPoint


  # Record my proportional situation in my holding panel — a StretchLayoutSpec derived from
  # CURRENT geometry, created/updated on the FIGURE (my enclosing sole-content island) w.r.t.
  # the figure's REAL holding panel, not on ME w.r.t. @parent (§5c: when I am wrapped in a
  # sugar island a handle gesture mutates ME, but the panel iterates + reads the ISLAND — so
  # the record must live there; _enclosingIslandFigure() is identity off any island ⇒
  # byte-identical dormant for the entire un-wrapped population; guarded on fig.parent? so a
  # content wrapped in an ORPHAN island skips instead of throwing). The framework OWNS
  # ordinary placement records (auto-bookkeeping arc, 2026-08-05): a widget entering a
  # fractional-consuming holder is seeded automatically (the __add seed -> the world's fill
  # drain station), so a plain builder never calls this — builders may place before OR after
  # adding, since the arrange-time heal's pre-placement guess is marked PROVISIONAL and the
  # drain re-derives it once at builder-final geometry (the D8 provenance gate; the historical
  # place-before-add builder rule is retired). The remaining explicit callers are the
  # RE-RECORD family: sites re-placing or re-sizing a widget that ALREADY carries a recorded
  # spec (drop, duplicate, file-load, app re-home, spawnNextTo of a stored widget, uncollapse,
  # handle-release via the post-flush drain), which the fill drain deliberately respects.
  # ⚠ Gated on the figure's parent CONSUMING the record: the F6 sites fire for drops /
  # uncollapses into ARBITRARY containers (stacks, documents, nested windows), and arming an
  # ACTIVE spec there would shadow the container's own adoption (a stack child whose
  # layoutSpec is suddenly a stretch spec breaks every isStackElementActive path) — the old
  # field writes were inert on non-consuming parents, an armed spec is not, so the recorder
  # carries the membership gate for every caller.
  _rememberFractionalSituationInHoldingPanel: (provisional = false) ->
    fig = @_enclosingIslandFigure()
    return if !fig.parent? or !fig.parent.consumesFractionalGeometryOf fig
    # ⚠ Same doctrine, other axis: a spec that OWNS placement (a corner-armed desktop
    # furniture piece -- the one owning kind a CONSUMING holder can host) must not be
    # replaced by a stretch record either -- the arrange places the widget FROM that spec,
    # and the __add seed fires for every consumed entrant, so without this gate the drain
    # would disarm a corner knob one cycle after its creator armed it. (A stretch spec
    # answers ownsPlacement() false, so re-records pass through untouched.)
    return if fig.layoutSpec?.ownsPlacement()
    spec = fig.layoutSpec
    unless spec?.isStretchElement?()
      spec = new StretchLayoutSpec()
      fig._setLayoutSpec spec
    spec.recordFor fig, provisional
  
  __commitMoveTo: (aPoint) ->
    # no cache-break here: __commitMoveBy breaks the caches itself, so a zero-delta move
    # no longer bumps the cache version key (the Tier-D D4 discipline).
    delta = aPoint.toLocalCoordinatesOf @
    @__commitMoveBy delta  if (delta.x isnt 0) or (delta.y isnt 0)
  
  _moveLeftSideTo: (x) ->
    @_applyMoveTo new Point x, @top()
  
  _moveRightSideTo: (x) ->
    @_applyMoveTo new Point x - @width(), @top()

  _moveBottomSideTo: (y) ->
    @_applyMoveTo new Point @left(), y - @height()
  
  _moveToSideOf: (aWidget) ->
    @_applyMoveTo aWidget.topRight().add new Point 10, -Math.round((@height() - aWidget.height())/2)
    @_moveWithin @parent
  
  _moveFullCenterTo: (aPoint) ->
    @_applyMoveTo aPoint.subtract @fullBounds().extent().floorDivideBy 2
  
  # make sure I am completely within another Widget's bounds
  _moveWithin: (aWdgt) ->
    # in case of widgets with deferred layouts we need
    # to look into desired extent and desired position
    if @desiredExtent?
      newBoundsForThisLayout = @desiredExtent
      @desiredExtent = undefined
    else
      newBoundsForThisLayout = @extent()

    if @desiredPosition?
      newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
      @desiredPosition = undefined
    else
      newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    # "bake" the "deferred" size and position
    # into the current size and position
    @_applyGrantedBounds newBoundsForThisLayout

    # Clamp me inside aWdgt via the ONE clamp home, then bake the move (immediate twin).
    # Net translation is identical to the old per-axis _applyMoveBy quartet (per-axis,
    # right/bottom first + left/top last-wins); one _applyMoveTo replaces four incremental
    # bakes -- intermediate damage-rects differ, but repaint is idempotent over the settled world.
    @_applyMoveTo @_clampedPositionWithin aWdgt, @position(), @extent()
    return

  # ONE home for the keep-me-inside-aWdgt position clamp (consumed by the immediate
  # _moveWithin bake AND the deferred _moveWithinNoSettle core): clamp right/bottom FIRST,
  # left/top LAST (last-wins), so a too-big widget pins its top-left and window-bar
  # controls stay reachable. Pure -- no reads of @, no mutation.
  _clampedPositionWithin: (aWdgt, pos, ext) ->
    newX = pos.x
    newY = pos.y
    rightOff = (newX + ext.x) - aWdgt.right()
    if rightOff > 0 then newX = newX - rightOff
    if newX < aWdgt.left() then newX = aWdgt.left()
    bottomOff = (newY + ext.y) - aWdgt.bottom()
    if bottomOff > 0 then newY = newY - bottomOff
    if newY < aWdgt.top() then newY = aWdgt.top()
    new Point newX, newY

  # Deferred core of the public moveWithin (the _moveToNoSettle lattice pattern): clamp me
  # inside aWdgt using the not-yet-applied @desired* geometry when present, then DEFER the move
  # via the move CORE (cores call cores -- NOT the public moveTo, which would be the rule-[C]
  # public-calls-public shape), so it settles in the recalculateLayouts -> _reLayout phase
  # together with any other pending change.
  _moveWithinNoSettle: (aWdgt) ->
    ext = if @desiredExtent?   then @desiredExtent   else @extent()
    pos = if @desiredPosition? then @desiredPosition else @position()
    @_moveToNoSettle @_clampedPositionWithin aWdgt, pos, ext

  # Canonical thin wrap: the PUBLIC deferred "keep me inside aWdgt" -- one settle over the
  # _moveWithinNoSettle core. (_moveWithin is the IMMEDIATE sibling for bake-now callers.)
  moveWithin: (aWdgt) ->
    @_settleLayoutsAfter => @_moveWithinNoSettle aWdgt

  # more complex Widgets, e.g. layouts, might
  # do a more complex calculation to get the
  # minimum extent
  getMinimumExtent: ->
    @minimumExtent

  _setMinimumExtent: (@minimumExtent) ->

  # Widget accessing - dimensional changes requiring a complete redraw
  # The polymorphic extent-apply -- the override DISPATCH POINT (TextWdgt / ListWdgt /
  # TrackingTransformFrameWdgt / ViewportWdgt specialize it for their own,
  # non-composite reasons). The base is _applyExtentBase (exactly like _applyMoveBy -> _applyMoveByBase: ONE
  # body per behaviour, two names for dispatch; the bare twin is the override-BYPASSING base apply the
  # top-down arrange uses) PLUS the SCHEDULE-VALVE (B4 hook retirement §9-N1, gate made STRUCTURAL by
  # §9-N4, ordered-downwalk plan, 2026-07-16): an immediate resize of any widget WITH CHILDREN schedules
  # its re-lay through the phase-valve -- in-pass the same flush's next round heals it, off-pass the
  # wrapping settle / the end-of-cycle flush does, always before the next paint. No declared capability
  # gates this (N4 deleted _placesChildrenInLayout + its lint): "has children" is the structural fact --
  # a childless widget's COMPLETE heal is _reLayoutSelf, which _applyExtentBase fires on every real
  # commit, so scheduling it would buy nothing (measured: the ungated variant adds ~12k schedules per
  # suite run for zero healing, incl. 142 end-of-cycle CaretWdgt scroll-follow re-lays -- plan §11).
  # This valve RETIRED the Stage-A SYNCHRONOUS hook (_reLayoutMyChildrenAfterImmediateResize -- itself
  # the unification of the INV-2 self-protecting-resize idiom,
  # docs/archive/layout-regressions-2026-07-icons-plots-editghosts-plan.md, whose 9th forgotten hand-copy
  # proved the opt-in unenforceable): the settle ENGINE is the one healer of composite interiors on
  # every route -- the ordered walk, the B3 frame-changed injection (the bypass path, also ungated by
  # N4), and this valve (the immediate path). A ctor that _applyExtents a placeholder size does so
  # BEFORE its first child add (verified per class, §11), so the gate is inert mid-construction and the
  # ctor-tail settle lays the built children out -- the retired _compositeChildrenBuilt guard's job.
  # Scheduling from an apply is the DELIBERATE, SANCTIONED exception to rule [E]'s schedule ban
  # (check-layering.js names exactly this line): the valve enqueues SELF only (no climb in-pass),
  # converges (a re-lay's own re-commit hits the equal-extent top guard, so no re-enqueue), and never
  # runs feature code synchronously. Mid-re-lay self-applies (base _reLayout applies its own new extent
  # through HERE) self-enqueue benignly: _reLayout / __reLayoutOneSettleNode marks the widget valid right
  # after, and the next round's sweep drops the entry. Nothing notifies: the notify-by-mutation seam
  # was deleted 2026-07-01 (the settle-time up-edge does any container re-fit), and the historical *AndNotify
  # names were renamed away 2026-07-02 (Tier B -- this method WAS _applyExtentAndNotify). Ordering is
  # load-bearing: _applyExtentBase COMMITS first, so when the composite's _reLayout re-commits its own frame
  # (bounds-first) the equal-extent top guard here absorbs that re-entry as a no-op.
  _applyExtent: (aPoint) ->
    if aPoint.equals @extent()
      return
    @_applyExtentBase aPoint
    if @children.length != 0
      @_scheduleRelayoutRespectingPhase()

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setExtent: (aPoint) ->
    @_settleLayoutsAfter => @_setExtentNoSettle aPoint

  # Non-settling extent core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent + invalidate,
  # but do NOT flush -- so the mutation rides an OUTER settle. Two callers: the public setExtent (self-settles
  # via _settleLayoutsAfter) and the _setExtentDeferredSettle (rides the ONE end-of-cycle flush). Feature
  # code uses one of those PUBLIC entrypoints, never this core directly.
  # (The per-resize-step fractional remember that used to sit here recorded PRE-flush geometry -- the
  # staleness class the post-flush re-record drain fixed; the handle's release enqueue is the one
  # gesture record now, so the hook and its widgetStartingTheChange plumbing are deleted.)
  _setExtentNoSettle: (aPoint) ->
    if not @isFreeFloating()
      return
    else
      aPoint = aPoint.round()
      newWidth = Math.max aPoint.x, 0
      newHeight = Math.max aPoint.y, 0
      newExtent = new Point newWidth, newHeight
      unless @extent().equals newExtent
        @desiredExtent = newExtent
        @_invalidateLayout()

  # PRIVATE DEFERRED-SETTLE extent entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _setExtentNoSettle core).
  _setExtentDeferredSettle: (aPoint) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setExtentNoSettle aPoint
    else
      @_settleLayoutsAfter => @_setExtentNoSettle aPoint

  
  # The silent extent-commit LEAF: round + min-extent clamp + commit @bounds, NO repaint / NO self-relayout. Returns
  # true iff @bounds actually changed. This is the bottom of the extent-sizing family -- external agents sizing a
  # widget (construction-time defaultSize / initial extent) call it directly, exactly like its __commitWidth /
  # __commitHeight siblings. (Collapsed 2026-07-01: the single-underscore _commitExtentAndNotify was a pure
  # pass-through to this leaf once the re-fit seam it used to fire was deleted -- it is gone, and its ~20 callers
  # reach the leaf directly. The §4.2 arrange still applies geometry through the non-notifying _apply* path; this
  # leaf is what those apply methods, and _commitBounds, commit through.)
  # GEOMETRY FINITENESS GUARD (always-on; ONE cheap check per bounds-COMMIT, not per read). My committed
  # @bounds must be FINITE: a NaN/Infinity coordinate is NEVER legitimate (a FRACTIONAL one IS -- vector
  # icons, rotated strokes -- so we assert ONLY finiteness, never integer-ness, and false-positive on
  # nothing). The native canvas silently TOLERATES non-finite draw args, so such a bug stays invisible
  # until it surfaces far downstream as an SWCanvas clip() throw ("Point ... must be a finite number") --
  # an error console + many widgets stop painting. Catch it HERE instead, at the commit SOURCE (my ~6
  # `@bounds =` leaves: __commitExtent/Width/Height + the move commits), on BOTH backends, naming the
  # widget + the value + a stack: a mystery paint crash becomes a pinpointed error. The distinctive
  # NON_FINITE_GEOMETRY signature is what the boot-smoke / apps-launch gates and the SystemTest runners
  # fail on (see Fizzygum-tests). console.error, NOT throw -- non-fatal, so the guard never itself becomes
  # the crash it guards against. Born from the 2026-07-15 plot-uncollapse NaN
  # (KeepsRatioWhenInVerticalStackMixin returned undefined -> FrameWdgt `stackHeight += undefined` -> NaN
  # window height -> NaN damage rect). (This supersedes the old dormant no-op Point/Rectangle `debugIfFloats`
  # hooks, deleted in the same arc: a per-accessor check there was too hot AND would false-positive on the
  # legitimate fractional values that flow through those accessors; the never-legitimate non-finite case is
  # better caught once, HERE, at the bounds-commit source with the owning widget in hand.)
  _assertBoundsWellFormed: (where) ->
    o = @bounds.origin
    c = @bounds.corner
    unless isFinite(o.x) and isFinite(o.y) and isFinite(c.x) and isFinite(c.y)
      console.error "NON_FINITE_GEOMETRY: #{@constructor.name} committed non-finite @bounds #{@bounds} via #{where}\n" + (new Error()).stack
    else unless Number.isInteger(o.x) and Number.isInteger(o.y) and Number.isInteger(c.x) and Number.isInteger(c.y)
      # INTEGER-PLACEMENT gate (Layer A): a widget is PLACED and SIZED in integer pixels; only Layer B (desired
      # geometry, kept in @desiredPosition / @desiredExtent) and Layer C (internal content rendering) are
      # fractional. The arrange-apply path no longer rounds for callers (the DELIBERATE-since-2015 "round at the
      # producer, assert here" contract, whose debugIfFloats assertion was silently stubbed to a no-op in 2018 and
      # this restores). Like NON_FINITE, wired into the headless runners' fail-gate. See
      # docs/archive/fractional-widget-bounds-investigation-plan.md + docs/architecture/integer-pixel-placement-and-sizing.md.
      console.error "NON_INTEGER_GEOMETRY: #{@constructor.name} committed fractional @bounds #{@bounds} via #{where}\n" + (new Error()).stack

  __commitExtent: (aPoint) ->
    aPoint = aPoint.round()
    minExtent = @minimumExtent  # the __ leaf reads the field directly (getMinimumExtent is the non-overridden accessor -> @minimumExtent, so byte-identical); keeps __commitExtent a pure bottom (§3c)
    if ! aPoint.ge minExtent
      aPoint = aPoint.max minExtent
    newWidth = Math.max aPoint.x, 0
    newHeight = Math.max aPoint.y, 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + newWidth, @bounds.origin.y + newHeight
    if @bounds.equals newBounds then return false
    @bounds = newBounds
    @_assertBoundsWellFormed "__commitExtent"
    @__breakMoveResizeCaches()
    return true

  # Base extent-apply WITHOUT the polymorphic override: commit @bounds + @_changed repaint + @_reLayoutSelf. THE
  # single body of the extent-apply pair -- the polymorphic _applyExtent base is a pure pass-through to
  # this. A container arranging a child top-down uses this to apply the child's measured extent while BYPASSING
  # the child's own _applyExtent override (e.g. VerticalStackPanelWdgt applies its arranged height
  # via _applyExtentBase so it does NOT re-enter its own _reLayoutChildren -- the frame commit that follows handles
  # that). The re-fit seam this pair used to differ on is gone (2026-07-01); the override-bypass keeps the two
  # NAMES distinct.
  _applyExtentBase: (aPoint) ->
    unless aPoint.equals @extent()
      # no cache-break here: __commitExtent breaks the caches itself, under its own did-anything-change
      # guard -- so a round/min-clamp no-op commit no longer bumps the clipped-bounds cache version key
      # (misses cost recompute, never values -- the Tier-D D4 discipline).
      @__commitExtent aPoint
      @_changed()
      @_reLayoutSelf()


  # (proper-layouts, 2026-07-01) The notify-by-mutation seams that re-fit a freefloating content's
  # size-tracking container (_announceLayoutPropertyChangeToContainer / _announceGeometryChangeToContainer)
  # are DELETED -- that dependency now rides the uniform dirty-tree (the D1 climb-through in _invalidateLayout)
  # and the settle-time re-fit below. See docs/archive/proper-layouts-geometry-seam-removal-plan.md.

  # (proper-layouts §4.3 / Stage 5, 2026-07-01) Re-fit MY size-tracking container now that I have SETTLED.
  # Called by the settle loop (WorldWdgt._recalculateLayoutsBody) right after my chain-top _reLayout completes --
  # NOT by the geometry mutators. This is the ORDERED-settle successor to the DELETED notify-by-mutation geometry
  # seam (the old _announceGeometryChangeToContainer, which fired from the extent-commit and _applyMoveBy
  # mutators per mutation). A freefloating child's _invalidateLayout does not climb to its
  # size-tracking container, so the container must be re-fit explicitly when my geometry changes. The old seam
  # did that at MUTATION time -- while I was mid-settle -- so the container read my HALF-applied geometry and had
  # to re-fit again and again (an empirical fixpoint the old iteration cap backstopped). Firing at
  # SETTLE-completion instead, the container reads my FINAL geometry and re-fits correctly: for a simple chain a
  # bounded O(depth) up-walk (leaf content -> container -> its container -> ...), each widget re-fit once after its
  # content settles. (Constrained NESTED containers -- a width-capping stack of window cells inside a resized outer
  # window -- still re-negotiate size over a SMALL bounded number of re-visits; measured suite-wide peak 10, see
  # WorldWdgt._recalculateLayoutsBody.) The immediate mutators are now PURE (no layout side effect) -- what the
  # FLOWRULE always wanted. Reverse-probe: OLD-seam OFF + this up-edge = 165/165 byte-exact at dpr1/dpr2/webkit,
  # so §8's "irreducible in-pass seam" verdict was over-general. Both containers are covered: a NON-text-wrapping
  # viewport a level up past my non-tracking @contents PanelWdgt (@parent.parent), and my direct parent
  # (stack/window). _reFitContainer gates on _reLayoutChildren?, so a non-tracking parent is a no-op. OVERLAY
  # CHROME (carets, resize handles -- isLayoutInert) is excluded from every container's content-bounds
  # (TreeNode.childrenNotHandlesNorCarets), so re-fitting for it would be pure waste -- skip it. (Capability
  # `?()`, not a Widget base default -- type-test-elimination convention.) docs/archive/proper-layouts-geometry-seam-removal-plan.md.
  _reFitMyTrackingContainerAfterSettle: ->
    return if @isLayoutInert?()
    return unless @parent?
    @_reFitContainer @parent.parent if @_amIDirectlyInsideNonTextWrappingViewport()
    @_reFitContainer @parent

  # The ONE phase-dispatch primitive for the whole "re-fit a container at the next settle point" family:
  # the drag/drop gesture handlers (PanelWdgt / ViewportWdgt / VerticalStackPanelWdgt
  # _reactToChildDropped / _reactToChildGrabbed / _reactToChildRemoved), the ORDERED settle-time re-fit
  # (_reFitMyTrackingContainerAfterSettle above, called by the settle loop after each chain-top settles), the
  # attach re-fit, and the newParentChoice* menu actions all route through here. Two states:
  #  - INSIDE a layout pass (world._recalculatingLayouts): ENQUEUE the container into the recalculateLayouts
  #    until-loop via the shared bare-push atom (__markForRelayout). Enqueuing is legal mid-pass -- unlike
  #    _invalidateLayout the atom neither throws (the freeze guard, see _invalidateLayout below) nor climbs to
  #    ancestors; it enqueues only the directly-affected container.
  #  - OUTSIDE a pass: _invalidateLayout() so the next doOneCycle re-fits the container.
  # Gated on _reLayoutChildren? so only a tracking container (Window / Stack / Viewport -- the only
  # classes that define it) reacts; any other widget is a no-op. Low-level (leading underscore) so lint
  # rule [F] exempts it, and the callers read as pure intent (@_reFitContainer @parent / @_reFitContainer()).
  # DETERMINISM: the gesture + menu callers fire OUTSIDE passes, so their in-pass arm is dead (kept uniform
  # for safety); the settle-time re-fit's in-pass enqueue IS live and is the determinism-exempt path
  # (deferred-layout-OVERVIEW.md §11).
  #
  # (proper-layouts Phase D, 2026-06-28) The cross-method `return if container._adjustingContentsBounds`
  # suppression was DELETED here. Post-Phase-C every container arrange is a fixed point, so re-enqueuing a
  # container that is mid its OWN _positionAndResizeChildren now CONVERGES (one extra convergence pass instead
  # of being skipped) rather than looping forever -- which is why the skip is no longer needed for correctness.
  # (proper-layouts Phase E, 2026-06-28) The @_adjustingContentsBounds field itself is now GONE too: its last
  # use was the per-arrange re-entrancy guard, retired by having each container arrange apply its own geometry
  # through the override-bypassing _applyExtentBase (the interim _resizeOwn*SkippingChildRelayout helpers were
  # inlined away in Tier D, 2026-07-02).
  # (Stage 5, 2026-07-01) The notify-by-mutation geometry seam the immediate mutators used to fire is fully DELETED:
  # its in-pass half is now the ordered settle-time re-fit above (_reFitMyTrackingContainerAfterSettle -- see that
  # method's comment for the mechanism + the reverse-probe record), its off-pass half the uniform dirty-tree (bare
  # _invalidateLayout at the semantic points). docs/archive/proper-layouts-geometry-seam-removal-plan.md.
  _reFitContainer: (container = @) ->
    return unless container?._reLayoutChildren?
    container._scheduleRelayoutRespectingPhase()

  # The PHASE-VALVE, shared by the re-fit seam (_reFitContainer, which also serves the
  # scatter-into-scroll-contents seam), the collapse/unCollapse cores, the composite
  # SCHEDULE-VALVE in _applyExtent (B4 hook retirement, ordered-downwalk plan §9-N1 -- the ONE
  # rule-[E]-sanctioned immediate-mutator caller, named in check-layering.js), and the scroll
  # panel arrange's declared-contents schedule: schedule MY re-layout correctly in EITHER phase.
  # In-pass, enqueue just me with the no-climb atom (a bare _invalidateLayout THROWS mid-pass; the
  # directly-affected widget needs no climb); off-pass, take the canonical climbing
  # _invalidateLayout.
  _scheduleRelayoutRespectingPhase: ->
    if world?._recalculatingLayouts
      @__markForRelayout()
    else
      @_invalidateLayout()


  _applyWidth: (width) ->
    @_applyExtent new Point(width or 0, @height())

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setWidth: (width) ->
    @_settleLayoutsAfter => @_setWidthNoSettle width

  # Non-settling width core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent + invalidate,
  # no flush. Callers: public setWidth (self-settles) + _setWidthDeferredSettle (rides the end-of-cycle flush).
  _setWidthNoSettle: (width) ->
    if not @isFreeFloating()
      return
    else
      newWidth = Math.max width, 0
      newExtent = new Point newWidth, @height()
      unless @extent().equals newExtent
        @desiredExtent = newExtent
        @_invalidateLayout()

  # PRIVATE DEFERRED-SETTLE width entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _setWidthNoSettle core).
  _setWidthDeferredSettle: (width) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setWidthNoSettle width
    else
      @_settleLayoutsAfter => @_setWidthNoSettle width
  
  __commitWidth: (width) ->
    w = Math.max Math.round(width or 0), 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.origin.x + w, @bounds.corner.y
    return if @bounds.equals newBounds
    @bounds = newBounds
    @_assertBoundsWellFormed "__commitWidth"
    # cache-break under the did-anything-change guard, like __commitExtent (the D4/E1 discipline)
    @__breakMoveResizeCaches()
  
  _applyHeight: (height) ->
    @_applyExtent new Point(@width(), height or 0)

  # high-level geometry-change API,
  # you don't actually change the geometry right away,
  # you just ask for the desired change and wait for the
  # layouting mechanism to do its best to satisfy it
  setHeight: (height) ->
    @_settleLayoutsAfter => @_setHeightNoSettle height

  # Non-settling height core (the setMaxDim/_setMaxDimNoSettle pattern): record @desiredExtent + invalidate,
  # no flush. Callers: public setHeight (self-settles) + _setHeightDeferredSettle (rides the end-of-cycle flush).
  _setHeightNoSettle: (height) ->
    if not @isFreeFloating()
      return
    else
      newHeight = Math.max 0, height
      newExtent = new Point @width(), newHeight
      unless @extent().equals newExtent
        @desiredExtent = newExtent
        @_invalidateLayout()

  # PRIVATE DEFERRED-SETTLE height entrypoint -- see the FAMILY comment on _setMaxDimDeferredSettle (rule [O]
  # caller-allowlist; world.deferredSettlingEnabled A/B switch; BOTH branches reach the _setHeightNoSettle core).
  _setHeightDeferredSettle: (height) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setHeightNoSettle height
    else
      @_settleLayoutsAfter => @_setHeightNoSettle height
  
  __commitHeight: (height) ->
    h = Math.max Math.round(height or 0), 0
    newBounds = new Rectangle @bounds.origin, new Point @bounds.corner.x, @bounds.origin.y + h
    return if @bounds.equals newBounds
    @bounds = newBounds
    @_assertBoundsWellFormed "__commitHeight"
    # cache-break under the did-anything-change guard, like __commitExtent (the D4/E1 discipline)
    @__breakMoveResizeCaches()
  
  # The write half of the `corner radius` pin an appearance contributes (BoxyAppearance /
  # BubblyAppearance / MenuAppearance all declare it), and the target of that shape's
  # "corner radius..." prompt. Both dispatch on the WIDGET — a pin's setter is called as
  # `consumer[pin.setterName]` and the prompt as `@widget[action]` — which is why this must live
  # where every wearer can answer it, not on the one subclass that happened to introduce it.
  #   The pin-setter contract (widget-authoring-guidelines §11): every delivery — wire, prompt Ok,
  # controller — passes ONE argument, the value.
  setCornerRadius: (radius) ->
    if typeof radius is "number"
      @cornerRadius = Math.max radius, 0
    else
      newRadius = parseFloat radius
      if !isNaN newRadius
        @cornerRadius = Math.max newRadius, 0
    @_changed()

  setColor: (aColor) ->
    if aColor
      if @color?.equals aColor
        return

      @color = aColor
      @_changed()

    return aColor

  setBackgroundColor: (aColor) ->
    if aColor

      if @backgroundColor?.equals aColor
        return

      @backgroundColor = aColor
      @_changed()

    return aColor

  # The principal value this widget offers to a spreadsheet reference (dataflow spec §9.3): the value
  # of my PRINCIPAL PIN. Widgets that declare no principal pin answer undefined here; the reference
  # read then falls back to the widget itself (that fallback lives at the read site — see the
  # spreadsheet's widget-valued-cell path).
  #   The widget SAYS which pin is principal and the pin says how to read it. The alternative — probing
  # every widget for a few particular method names in a fixed priority order, falling through to a
  # FIELD — cannot tell "exports nothing" from "happens to carry a field of that name", and the
  # difference is real: on StringFieldWdgt and MenuHeader `@text` holds a child WIDGET rather than a
  # string, so a `@text` fallback exports a TextWdgt. StringFieldWdgt's principal pin reads `getValue`
  # (`@text.text`); MenuHeader declares no pin, so it exports nothing.
  exportedValue: ->
    pin = @principalPin()
    return undefined unless pin?.getterName?
    return @[pin.getterName]?()

  # The dataflow node-protocol value reader (spec §3; DataflowEngine header): a widget node's current value IS
  # its exported value, so when a ported wire delivers, the engine PULLS the producer widget's exportedValue,
  # and the equal-value cutoff compares it after each edge apply.
  # Plain widgets (slider, text) inherit this; computing patch nodes override it to return their @output.
  dataflowValue: -> @exportedValue()

  # Widget displaying ---------------------------------------------------------

  # There are three fundamental methods for rendering and displaying anything.
  # * updateBackBuffer: this one creates/updates the local canvas of this widget only
  #   i.e. not the children. For example: a ColorPickerWdgt is a Widget which
  #   contains three children Widgets (a color palette, a greyscale palette and
  #   a feedback). The updateBackBuffer method of ColorPickerWdgt only creates
  #   a canvas for the container Widget. So that's just a canvas with a
  #   solid color. As the
  #   ColorPickerWdgt constructor runs, the three childredn Widgets will
  #   run their own updateBackBuffer method, so each child will have its own
  #   canvas with their own contents.
  #   Note that updateBackBuffer should be called sparingly. A widget should repaint
  #   its buffer pretty much only *after* it's been added to its first parent and
  #   whenever it changes dimensions. Things like changing parent and updating
  #   the position shouldn't normally trigger an update of the buffer.
  #   Also note that before the buffer is painted for the first time, they
  #   might not know their extent. Typically text-related Widgets know their
  #   extensions after they painted the text for the first time...
  # * paintIntoAreaOrBlitFromBackBuffer: takes the local canvas and paints it to a specific area in a passed
  #   canvas. The local canvas doesn't contain any rendering of the children of
  #   this widget.
  # * fullPaintIntoAreaOrBlitFromBackBuffer: recursively draws all the local canvas of this widget and all
  #   its children into a specific area of a passed canvas.

  
  
  boundsContainPoint: (aPoint) ->
    @bounds.containsPoint aPoint

  calculateKeyValues: (aContext, clippingRectangle) ->
    damageBox = clippingRectangle.intersect(@bounds).round()
    # test whether anything that we are going to be drawing
    # is visible (i.e. within the clippingRectangle)
    if damageBox.isNotEmpty()
      delta = @position().neg()
      src = damageBox.translateBy(delta).round()

      sl = src.left() * ceilPixelRatio
      st = src.top() * ceilPixelRatio
      al = damageBox.left() * ceilPixelRatio
      at = damageBox.top() * ceilPixelRatio
      w = Math.min(src.width() * ceilPixelRatio, @width() * ceilPixelRatio - sl)
      h = Math.min(src.height() * ceilPixelRatio, @height() * ceilPixelRatio - st)

    return [damageBox,sl,st,al,at,w,h]

  # EPHEMERAL capability (owner's term). An ephemeral is a transient overlay owned wholly by the
  # per-cycle reconciler (WorldWdgt.addHighlightingWidgets / PinoutsOverlay.reconcile): it is
  # hit-test-excluded (never steals mouseEnter / clicks / drops — ActivePointerWdgt.topWdgtUnderPointer),
  # casts no shadow (skipsAddShadowManagement below), and is skipped by world-snapshot serialization
  # (Serializer.serializeWorld). Capability, not a type test (type-test-elimination convention): reads
  # the _ephemeralOverlay flag, so dedicated overlay classes AND ad-hoc reconciler-marked instances qualify.
  isEphemeral: -> @_ephemeralOverlay is true

  # A widget added to the world normally gains a drop-shadow (Widget._addNoSettle). Ephemerals opt
  # out — "not anything material the user clicks/drags". The caret ALSO opts out (it is not an
  # ephemeral — it is excluded from hit-testing separately — but is likewise immaterial), so it
  # overrides this directly. (Folded here from HighlighterWdgt's old dedicated override.)
  skipsAddShadowManagement: -> @isEphemeral()

  turnOnHighlight: ->
    if !@highlighted
      @highlighted = true
      # declare into the highlight style channel (target -> style descriptor) with the legacy
      # translucent-blue fill — the only style today; the drag arc (Phase 2+) adds outline styles.
      world.widgetsToBeHighlighted.set @, HighlighterWdgt.fillStyle(Color.BLUE, 50)
      @_changed()

  turnOffHighlight: ->
    if @highlighted
      @highlighted = false
      world.widgetsToBeHighlighted.delete @
      @_changed()


  preliminaryCheckNothingToDraw: (clippingRectangle, aContext) ->

    if !@isVisible
      return true

    if clippingRectangle.isEmpty()
      return true

    if aContext == world.worldCanvasContext and @isOrphan()
      return true

    # The two LIVE-TREE visibility gates apply when painting the world canvas
    # OR a TransformFrameWdgt island buffer (a live-tree render through a
    # transform island -- same idiom as the damage-rects recording below): a
    # hidden or collapsed widget must not appear just because its ancestors are
    # tilted. Conditioned (not unconditional) because SCRATCH renders --
    # icon/thumbnail canvases painting detached widgets -- legitimately paint
    # regardless of live-tree visibility. The orphan gate above stays
    # world-canvas-only for the same reason (an island cannot contain orphans,
    # a thumbnail render IS one).
    if (aContext == world.worldCanvasContext or world.paintingIntoIslandBuffer?) and !@visibleBasedOnIsVisibleProperty()
      return true

    if (aContext == world.worldCanvasContext or world.paintingIntoIslandBuffer?) and @isInCollapsedSubtree()
      return true

    return false

  _recordDrawnAreaForNextDamageRects: ->
    if @childrenBoundsUpdatedAt < WorldWdgt.frameCount
      @childrenBoundsUpdatedAt = WorldWdgt.frameCount
      # Affine transforms: record the SCREEN footprint (mapped through my ancestor islands WHILE I am still
      # attached and being painted), NOT the raw virtual rect. fleshOut(Full)Broken erases the "source"
      # (where-I-was) rect from these; if it re-mapped a stored VIRTUAL rect at flush time instead, a widget
      # DETACHED between paint and flush — a close/destroy (_destroyNoSettle / _closeNoSettle issue
      # _fullChanged() then sever @parent, re-homing me to the bin) — would map through an undefined/bin
      # chain (an identity) and erase the WRONG (un-transformed) rect, leaving the rotated on-screen footprint
      # stale (owner bug: closing a tilted converter's inner window). mapRectToScreen returns the SAME rect
      # off any island ⇒ byte-identical dormant. (Field names kept; they now hold the screen-plane footprint.)
      # Shadow inclusion: the recorded footprints cover what this paint ACTUALLY painted, shadow
      # included, so the erase (source) side of the next flush never reconstructs shadow history —
      # a removed/shrunk shadow erases with the shadow that PAINTED, not with today's shadowInfo.
      # The shadow extension is applied in MY OWN plane BEFORE mapping (see shadowExtendedRect:
      # the map composes an island's scale and rotation over it), and the island stash below
      # carries the same extended rect (the buffer IS my plane).
      fullVirtual = @shadowExtendedRect @fullClippedBounds()
      @clippedBoundsWhenLastPainted = @mapRectToScreen @shadowExtendedRect @clippedThroughBounds()
      @fullClippedBoundsWhenLastPainted = @mapRectToScreen fullVirtual
      # §4.4 buffer cache — the "source" (old-position) lane. When painting INTO an island buffer,
      # stash the PRE-mapping virtual full-bounds (shadow-inclusive, per the above) and the island.
      # If this widget later MOVES within (or is removed from) the stationary island, the flesh-out
      # source lane deposits this OLD footprint as buffer-damage so the partial rebuild erases the
      # vacated region — the buffer-plane twin of the screen-footprint erase above (the NEW footprint
      # rides the mapRectToScreen deposit).
      # undefined on every ordinary (non-island) paint ⇒ dormant-free; consumed+cleared at flesh-out.
      if world.paintingIntoIslandBuffer?
        @_islandBufferSourceIsland = world.paintingIntoIslandBuffer
        @_islandBufferSourceVirtualRect = fullVirtual
      else if @_islandBufferSourceIsland?
        @_islandBufferSourceIsland = undefined

  # Occlusion culling (docs/plans/occlusion-culling-plan.md P1): the axis-aligned rectangle this widget
  # provably paints FULLY OPAQUE, in LOGICAL px world coordinates, or undefined. It is the geometry both
  # avenues of the plan share (Avenue A scans it per damage rect; Avenue B would cache it).
  # CONSERVATIVE BY DESIGN: any uncertainty MUST yield undefined -- a wrong (too-big) rect silently drops
  # pixels of whatever is painted beneath the coverer, caught only by the pixel-exact SystemTests.
  # Every gate is evaluated at RUNTIME (never baked per class): appearances are swapped live
  # (e.g. FrameWdgt._deriveAndSetBodyAppearance flips Rectangular<->Boxy on re-parenting).
  opaqueCoveredRect: ->
    # (1) The paint must route through the plain appearance delegation. Widget::paintIntoAreaOrBlit-
    # FromBackBuffer just delegates to @appearance (every widget class now routes through it — the
    # former nine custom painters each moved their override into their own Appearance subclass, whose
    # constructors fall to this switch's else -> undefined), but BackBufferMixin still overrides it to blit
    # an offscreen buffer of unknown per-pixel opacity. This prototype-identity check excludes its
    # consumers.
    return undefined if @paintIntoAreaOrBlitFromBackBuffer isnt Widget::paintIntoAreaOrBlitFromBackBuffer
    # (2) ephemeral overlays (highlights, drag affordances) are translucent screen-toppers, never coverers
    return undefined if @isEphemeral()
    # (3) the fill runs at globalAlpha = @alpha (RectangularAppearance), and (4) @color must be a
    # solid opaque colour (else fillStyle emits rgba(...) -- Color.toString gates on _a == 1)
    return undefined if @alpha != 1
    return undefined if !@color? or @color._a != 1
    # Dispatch on the EXACT appearance class (CoffeeScript switch compares with ===): a subclass
    # appearance may add arbitrary drawing (drawAdditionalPartsOnBaseShape) and must NOT inherit a
    # coverage claim. DesktopAppearance falls to the else -> undefined (the world occludes nothing).
    switch @appearance?.constructor
      when RectangularAppearance
        if @backgroundColor? and @backgroundColor._a == 1
          # an opaque backgroundColor fills the FULL clipped bounds, padding ring included
          @boundingBox()
        else
          # the main @color fill clips to the tight box (bounds inset by the four paddings)
          @boundingBoxTight()
      when BoxyAppearance
        # inscribed box: the straight edges between corners fill crisply to the bounds; the corner
        # areas are cut away by the rounding (anti-aliased on native, hard-edged on SWCanvas)
        # -> inset every side by cornerRadius + 1 (conservative)
        @boundingBox().insetBy Math.max(@appearance.getCornerRadius(), 0) + 1
      else
        undefined

  # in general, the children of a Widget could be outside the
  # bounds of the parent (they could also be much larger
  # then the parent). This means that we have to traverse
  # all the children to find out whether any of those overlap
  # the clipping rectangle. Note that we can be smarter with
  # PanelWdgts, as their children are actually all contained
  # within the parent's boundary.
  #
  # Note that if we could dynamically and cheaply keep an updated
  # fullBounds property, then we could be smarter
  # in discarding whole sections of the scene graph.
  # (see https://github.com/davidedc/Fizzygum/issues/150 )
  #
  # To draw a widget, basically you first have to draw its shadow
  # and then you draw the contents. See methods below.
  #
  # How the shadow painting works -----------------
  # IMPORTANT: a widget NEVER bakes its own shadow into its back-buffer. The ONLY
  # shadow mechanism is this unified recursive re-paint: a widget that has a shadow
  # (@shadowInfo) re-paints its WHOLE subtree once more, faintly and offset, BEHIND
  # the normal paint. The offset is an arbitrary integer-px VECTOR — any direction,
  # asymmetric is fine: the pass is two vector operations (cull rect translated by
  # −offset, ctx translated by +offset), with no directional assumption anywhere.
  # THE SHADOW-PASS PAINT CONTRACT: a shadow is the caster's per-pixel COVERAGE,
  # chroma always black — a shadow occludes light, so it may only darken, never
  # carry the caster's own colours (a caster lighter than the background would
  # otherwise cast a GLOW — the tilted-window faint-shadow bug, fixed 2026-08-02).
  # Coverage means per-pixel OPACITY, not a hard mask: a translucent widget casts a
  # proportionally fainter shadow (appliedShadow.alpha × its alpha), glyph AA edges
  # shade proportionally, a hole casts nothing. Every paint leaf honours the
  # contract by the cheapest correct means: appearances that control their fills
  # swap them to Color.BLACK under appliedShadow; buffer blits (BackBufferMixin,
  # the island composite) blit a cached black-silhouette twin
  # (HTMLCanvasElement.blackSilhouetteOf); arbitrary-coloured art (icons, the
  # clock) renders to a scratch and blits its silhouette
  # (Appearance._paintDamagedAreaAsBlackSilhouette). In that scratch the
  # size-aware icons' LIGHT role (halo + light interiors) ERASES coverage
  # (SizeAwareIconAppearance._useLight, destination-out): the halo is visually
  # background, not ink, so an icon's shadow is its dark line-work — never the
  # halo-envelope blob. Hover/selection overlays are
  # not part of the caster's ink and are skipped in the shadow pass. (There is no
  # per-glyph / per-widget baked shadow: a per-glyph shadowOffset/shadowColor
  # route is deliberately not reintroduced; a COLOURED shadow, if ever wanted,
  # would be an explicit ShadowInfo field, not a paint-path accident.)
  # If appliedShadow is defined, it means that we are painting the whole
  # of the widget recursively AS SHADOW. Since there are no shadows of a shadow
  # so we can skip the "just shadow" part, and we paint the widget as shadow.
  # If appliedShadow is NOT defined, then it means that we just have to paint the widget,
  # which might have a shadow. If it does have a shadow, then we first paint it
  # as shadow, then we paint it as non-shadow. If it doesn't have a shadow, then
  # we just paint it as non-shadow.

  fullPaintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # used to track which widget has been throwing
    # an error while painting
    world.paintingWidget = @

    # if there is a shadow "property" object
    # then first draw the shadow of the tree
    # If appliedShadow is defined, then we just want to paint the
    # content as shadow, so we skip this paragraph because we don't have
    # to paint a shadow for a shadow.
    if !appliedShadow? and @shadowInfo?
      @_fullPaintIntoAreaOrBlitFromBackBufferJustShadow aContext, clippingRectangle, @shadowInfo

    # draw the proper contents of the tree. Potentially, draw them faintly as shadow.
    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      # Record last-painted bounds when drawing to the world canvas OR into a
      # TransformFrameWdgt island buffer (docs/plans/affine-transforms-plan.md §4.5): a
      # widget inside a non-identity island paints into the island's buffer (not the
      # world canvas), so without this its virtual last-painted snapshot would never
      # update and the flesh-out "source" (cleanup-of-old-position) rect would be
      # missing. world.paintingIntoIslandBuffer is undefined on every ordinary paint, so
      # this is byte-identical when the feature is dormant.
      if aContext == world.worldCanvasContext or world.paintingIntoIslandBuffer?
        @_recordDrawnAreaForNextDamageRects()
      @_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow aContext, clippingRectangle, appliedShadow


  # to draw the shadow, most of the times you have to draw the whole
  # of the contents, but with a darker/fainter color, and with
  # transparency.
  #
  # The only variant is that if a Panel if fully opaque, then the shadow is just
  # a rectangle, we don't need to draw anything inside the panel to
  # contribute to the shadow of the panel
  #
  # In this function the parameter "appliedShadow" MUST contain a shadow info.
  # This parameter will cause the whole widget to be painted recursively as shadow.
  _fullPaintIntoAreaOrBlitFromBackBufferJustShadow: (aContext, clippingRectangle, appliedShadow) ->
    # the culling rect moves OPPOSITE the paint (a pixel at P shows the shadow of content
    # at P − offset), as a VECTOR — any direction, any asymmetry. Rectangle.translateBy
    # takes ONE argument (Point or scalar): passing -x, -y here would silently degrade
    # the translate to a scalar of the x component, mis-culling asymmetric offsets.
    clippingRectangle = clippingRectangle.translateBy appliedShadow.offset.neg()

    if !@preliminaryCheckNothingToDraw clippingRectangle, aContext
      aContext.save()
      aContext.translate appliedShadow.offset.x * ceilPixelRatio, appliedShadow.offset.y * ceilPixelRatio

      @_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow aContext, clippingRectangle, appliedShadow

      aContext.restore()
  

  # this just draws the tree of the widgets recursively, potentially "normally" or
  # potentially more faintly to draw a shadow.
  # The only variant is that the Panel
  # draws its background, then its contents AND THEN its stroke
  # (because otherwise its content would paint over its stroke)
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    @children.forEach (child) ->
      child.fullPaintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    @_paintEditorSelectionOverlayIfSelected aContext, clippingRectangle, appliedShadow

  # The editor-focus SELECTION overlay, drawn AFTER my whole subtree so a CONTAINER's frame sits on top of
  # its children (at own-content level the children would hide it, leaving only a partial frame). Called as
  # the widget-type's LAST paint step: here, at the tail of the base content-paint; a clipping panel calls
  # it instead at the tail of its fullPaintIntoAreaOrBlitFromBackBuffer (after its border re-draw, which
  # itself runs after the children). TransformFrameWdgt's non-identity island renders children into its
  # buffer where each draws its own, so a rotated island's selected content warps for free. Never in the
  # shadow pass, and only for the ONE selected widget (an O(1) check), so calculateKeyValues costs nothing
  # on the common path.
  _paintEditorSelectionOverlayIfSelected: (aContext, clippingRectangle, appliedShadow) ->
    return if appliedShadow? or !@_showsSelectionOverlay()
    [damageBox, sl, st, al, at, w, h] = @calculateKeyValues aContext, clippingRectangle
    return unless damageBox? and damageBox.isNotEmpty() and w >= 1 and h >= 1
    @_drawSelectionOverlay aContext, al, at, w, h

  # ... when you want to hide something
  # but you don't want to generate any
  # damage rectangles
  __hide: ->
    if !@isVisible
      return
    @isVisible = false
    WorldWdgt.noteVisibilityOrCollapseChange()

  hide: ->
    if !@isVisible
      return

    @__hide()

    @_fullChangedIncludingShadowOwner()


  show: ->
    if @isVisible
      return
    if @visibleBasedOnIsVisibleProperty() == true
      return
    @isVisible = true
    WorldWdgt.noteVisibilityOrCollapseChange()

    @_fullChangedIncludingShadowOwner()
  
  toggleVisibility: ->
    @isVisible = not @isVisible
    WorldWdgt.noteVisibilityOrCollapseChange()
    @_fullChangedIncludingShadowOwner()

  # SELF-SETTLE (single-mutation tier). _beforeChildCollapsed now tears down the bar buttons through the
  # NON-settling core (_destroyNoSettle), and _reactToChildCollapsed re-fits via immediate mutators + _reFitContainer, so
  # _collapseNoSettle reaches no public setter. Anchored on (@parent ? @) (the container that re-lays-out).
  # THIN wrapper: the already-collapsed guard lives in the core (check-layering [H]), not before the settle.
  collapse: ->
    @_settleLayoutsAfter => @_collapseNoSettle()

  _collapseNoSettle: ->
    # IDEMPOTENT -- the SOLE collapse guard (the public collapse() is a thin settle wrapper). A direct caller --
    # a layout pass that decides collapse by width (FrameWdgt._positionAndResizeChildren)
    # -- may collapse a NOT-yet-collapsed child MID-PASS (e.g. the FIRST
    # layout of an under-construction window, now that orphan construction settles -- see
    # docs/archive/orphan-settledness-plan.md), so the re-layout the collapse schedules goes through the PHASE-VALVE
    # (in-pass -> the no-climb __markForRelayout; off-pass -> _invalidateLayout), exactly like the re-fit seam
    # _reFitContainer -- never a bare _invalidateLayout, which THROWS mid-pass. The no-op-when-already-collapsed
    # guard still short-circuits the common repeat call.
    return if @collapsed
    @parent?._beforeChildCollapsed? @
    @collapsed = true
    WorldWdgt.noteVisibilityOrCollapseChange()
    @_scheduleRelayoutRespectingPhase()
    @_fullChangedIncludingShadowOwner()
    @parent?._reactToChildCollapsed? @

  # SELF-SETTLE (single-mutation tier). _beforeChildUnCollapsed re-creates the bar buttons through the
  # NON-settling core (createAndAdd* -> @_addNoSettle; the button constructors add their innards on ORPHANS,
  # exempt from the flush-throw), and _reactToChildUnCollapsed re-fits via immediate mutators, so _unCollapseNoSettle reaches
  # no public setter. Anchored on @ (the canonical wrap; the global flush re-lays-out the container).
  # THIN wrapper: the guard lives in the core (check-layering [H]), not before the settle.
  unCollapse: ->
    @_settleLayoutsAfter => @_unCollapseNoSettle()

  _unCollapseNoSettle: ->
    # IDEMPOTENT -- the SOLE unCollapse guard (the public unCollapse() is a thin settle wrapper). See
    # _collapseNoSettle for why a direct layout-pass caller needs the no-op (avoid re-running the hooks
    # mid-pass) AND why the re-layout goes through the PHASE-VALVE (in-pass -> the no-climb
    # __markForRelayout; off-pass -> _invalidateLayout): a bare _invalidateLayout THROWS mid-pass, which a
    # width-driven uncollapse during the FIRST layout of an under-construction window now hits (orphan
    # construction settles -- see docs/archive/orphan-settledness-plan.md), exactly symmetric to _collapseNoSettle.
    # Guard on @collapsed -- this widget's OWN collapse flag. The redundant `return if !@isInCollapsedSubtree()`
    # was REMOVED: isInCollapsedSubtree() is the RECURSIVE self-or-ancestor query, and once @collapsed is true
    # it necessarily returns true, so that second guard was DEAD code.
    return if !@collapsed
    @parent?._beforeChildUnCollapsed? @
    @collapsed = false
    WorldWdgt.noteVisibilityOrCollapseChange()
    @_scheduleRelayoutRespectingPhase()
    @_fullChangedIncludingShadowOwner()
    @parent?._reactToChildUnCollapsed? @

  
  SLOWisInCollapsedSubtree: ->
    if @collapsed
      return true
    if @parent?
      return @parent.SLOWisInCollapsedSubtree()
    return false

  # Cached on visibilityVersion, exactly like visibleBasedOnIsVisibleProperty: the only
  # two @collapsed writes (collapse/unCollapse cores) bump it, and a reparent bumps it
  # via noteStructureChange -- so the stamp invalidates in exactly the situations the
  # walk's inputs can change, and moves never touch it (no empty-hand interaction).
  # Measured before caching (2026-07-03): 310k node-visits / ~149 ms in one menu-hover
  # test -- an uncached O(depth) walk on every hit-test / damage-rect guard.
  isInCollapsedSubtree: ->
    if @checkIsInCollapsedSubtreeCache == WorldWdgt.visibilityVersion
      result = @cachedIsInCollapsedSubtree
    else
      if @collapsed
        result = true
      else if @parent?
        result = @parent.isInCollapsedSubtree()
      else
        result = false
      @checkIsInCollapsedSubtreeCache = WorldWdgt.visibilityVersion
      @cachedIsInCollapsedSubtree = result

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWisInCollapsedSubtree()
        debugger
        console.error "CACHED_DERIVATION_DIVERGED -- isInCollapsedSubtree is broken"

    return result
  
  removeFromTree: ->
    # FREEFLOATING-skip centralized in _invalidateLayout(triggeringChild): pass @ so the parent skips
    # when I'm freefloating -- removing a freefloating child doesn't change the parent's layout.
    @parent?._invalidateLayout(@)
    @__breakMoveResizeCaches()
    WorldWdgt.noteStructureChange()
    # invalidate BEFORE the detach (same order as the destroy path): the shadow-owner walk
    # needs the parent chain, which removeChild severs.
    @_fullChangedIncludingShadowOwner()
    @parent.removeChild @

  # My name in the product's own words: window titles, inspector and console titles, the drag-embed
  # hint, the shortcut auto-namer, the name a saved file gets.
  #   DERIVED from my class name, because a name every class has to REMEMBER to write is a name most
  # of them do not write — 200 of 267 widget classes carry no override, and the flat `"generic
  # widget"` this replaces was what all 200 of them called themselves, in title bars and file names
  # alike. Deriving makes the default TRUE instead of merely present, and an override an editorial
  # improvement rather than the only way to avoid a lie.
  #   Lowercase words, because that is what every consumer wants: they drop it into a sentence ("drop
  # it into the …?"), parenthesise it ("Object Inspector (analog clock)"), or prefix it ("Console
  # for: …", which lowercases defensively today). Override when the derivation reads wrong, or when
  # the thing has a NAME of its own rather than a description — "Desktop", "Bin", "Fizzytiles",
  # "Docs Maker".
  colloquialName: ->
    bareName = @constructor.name.replace /(Wdgt|Morph)$/, ""
    return "widget" if bareName == ""
    # split camelCase humps, keeping a run of capitals together as ONE word ("HTMLBox" -> "html box",
    # not "h t m l box"). A digit stays glued to its word and a digit-then-capital is not a hump, so
    # "3D" splits wrongly — the three classes that hit it state their name instead.
    spaced = bareName.replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2")
    spaced.toLowerCase()

  representativeIcon: ->
    new WidgetIconWdgt

  # Swap me for a PointerWdgt pointing at me. PointerWdgt is an experimental family that ships
  # only in the full build, so this is inert without it — the two entry points (the "make
  # pointer" demo menu item and PointerWdgt's own restore) are absent there too.
  createPointerWdgt: ->
    return unless PointerWdgt?
    # a widget with no parent has nowhere to BE replaced, and the add below would throw on it
    return unless @parent?
    myPosition = @positionAmongSiblings()
    widgetToAdd = new PointerWdgt @
    @parent.add widgetToAdd, atIndex: myPosition
    widgetToAdd.setBounds @position(), new Point 150, 20
    # ⚠ A container may EVICT me as part of accepting my replacement, in which case the add above
    # has ALREADY done the removal half of this swap and I am parentless: a FrameWdgt holds exactly
    # ONE content widget and swaps it (FrameWdgt._addNoSettle -- `@removeChild @contents`), so a
    # receiver that IS a window's content reaches this line already detached. Adding is NOT
    # universally additive, and a caller that swaps has to say which half of the swap it still owes.
    #   Asking the container to do the whole swap (`@parent.replaceChild @, widgetToAdd`) is the
    # tidier shape and deliberately NOT built: it would be a container protocol with exactly one
    # caller. Introduce it with the SECOND one.
    @removeFromTree() if @parent?

  # THE MENU ADAPTER for the "create shortcut" item — the shape shared with
  # PanelWdgt.makeFolderFromMenu and StringWdgt.setFontNameFromMenu. ButtonWdgt dispatches a FIXED
  # 4-slot convention (`@target[@action].call @target, theButton, subject, arg1, arg2`), so a menu item
  # carrying no arguments of its own still arrives with WIDGETS in the leading slots. Keeping the
  # adapter separate from the verb is what lets createReference take the parameters IT wants: a menu
  # click means "a shortcut to me, on the desktop, auto-named", which is exactly the no-argument call.
  # ⚠ Point menu items and triggers at THIS, never at createReference: the verb has no defence of its
  # own, and the three overrides of it that would each need one are the reason to have a door here.
  createReferenceFromMenu: ->
    @createReference()

  # PUBLIC self-settling entry (double-clicks, the menu adapter above, macro/user code). The
  # NON-settling core _createReferenceNoSettle is what a drop recipient calls (it runs inside the
  # drop's settle, so a public add/setExtent would re-enter the flush guard and throw under the
  # single-mutation tier).
  # ⚠ ORDER — the place leads because every caller supplies one while the name is usually left to
  # untitledNamingService; with the name in front, the two drop recipients have to skip a slot to
  # reach the place they care about (R3's hole test, whose remedy for a two-slot list is this
  # reorder rather than an options bag). The whole family shares the one order.
  # opts.representsContents — THE ARROW CONTRACT declaration (reference-widgets plan §4.4),
  # threaded to the shortcut's constructor: the FILING paths (createReferenceAndClose,
  # PanelWdgt.makeFolder) pass true (the icon left behind IS the widget's primary
  # representation — bare art, deep copy), while this default — the deliberate
  # "create shortcut" alias — stays a reference (arrow badge, shallow copy).
  createReference: (placeToDropItIn = world, referenceName, opts = {}) ->
    @_settleLayoutsAfter => @_createReferenceNoSettle placeToDropItIn, referenceName, opts

  # The COMPLETE createReference minus the settle. add -> _addNoSettle and setExtent -> _applyExtent
  # (the shortcut is freshly added freefloating, so the immediate raw size is byte-identical to the
  # deferred desired-extent path; same add-then-size order as the public version, so the icon grid
  # positions identically once the enclosing settle re-fits).
  _createReferenceNoSettle: (placeToDropItIn = world, referenceName, opts = {}) ->
    # don't create new reference if it exists already
    for w in placeToDropItIn.children
      if w.isShortcutTo?(@)
        return

    widgetToAdd = @_buildShortcutWidget referenceName, opts
    # this "add" is going to try to position the
    # new icon into a grid
    placeToDropItIn._addNoSettle widgetToAdd
    widgetToAdd._applyExtent new Point 75, 75
    # public-call-sanctioned: bringToForeground is the heavily-public z-order verb (macros/user
    # code drive it) — settle-free, consciously reused by this core.
    @bringToForeground()

  # THE ONE seam deciding WHICH shortcut class represents me, consulted by the core above — so
  # the answer holds on EVERY creation path: the menu's "create shortcut", a folder-drop filing,
  # and the save-close prompt all reach it. Overridden by FrameWdgt (its CONTENT may specialize
  # — a script window yields a run-on-double-click ScriptShortcutWdgt) and FolderWindowWdgt
  # (a folder shortcut). Pure builder: the core places and sizes what this returns.
  _buildShortcutWidget: (referenceName, opts) ->
    new DocumentShortcutWdgt @, referenceName, representsContents: opts.representsContents

  # PUBLIC self-settling entry; _createReferenceAndCloseNoSettle is the core a drop recipient calls
  # (FolderShortcutWdgt / FolderPanelWdgt._reactToChildDropped, inside the drop's settle).
  # This is a FILING ritual (the SaveShortcutPromptWdgt "Ok" path routes here too), so the icon
  # left behind declares content — no arrow, deep copy — per the arrow contract (plan §4.4).
  createReferenceAndClose: (placeToDropItIn = world, referenceName) ->
    @_settleLayoutsAfter => @_createReferenceAndCloseNoSettle placeToDropItIn, referenceName

  _createReferenceAndCloseNoSettle: (placeToDropItIn = world, referenceName) ->
    @_createReferenceNoSettle placeToDropItIn, referenceName, representsContents: true
    # the reference just created (or already existing -- the create dedups)
    # keeps me reachable, so file straight to the SHELF
    @_closeNoSettle world.shelfWdgt

  # Widget full image:
  # Fixes https://github.com/jmoenig/morphic.js/issues/7
  # and https://github.com/davidedc/Fizzygum/issues/160
  #
  # EVERY parameter is optional and no caller supplies them all, so there is no positional head
  # and they all ride opts (R3, docs/architecture/constructor-and-parameter-conventions.md):
  #   bounds      the region to image; absent means my own fullBounds, grown to cover any shadow
  #   noShadow    image me with my shadow suppressed — wins over forceShadow if both are set
  #   forceShadow give me the standard float-drag shadow for the shot if I have none of my own
  fullImage: (opts = {}) ->
    bounds = opts.bounds
    noShadow = opts.noShadow ? false
    forceShadow = opts.forceShadow ? false

    shadowHadBeenReplacedOrAdded = false

    if noShadow
      originalShadow = @shadowInfo
      @shadowInfo = ShadowInfo.noShadow()
      shadowHadBeenReplacedOrAdded = true
    else if forceShadow and !@hasShadow()
      # in this case originalShadow is undefined
      # because the widget has no shadow
      # and the widget will get undefined shadow back
      # again at the end of this method
      originalShadow = undefined
      @shadowInfo = new ShadowInfo new Point(4, 4), 0.2
      shadowHadBeenReplacedOrAdded = true


    if !bounds?
      bounds = @fullBounds()
      # if we do want the shadow, and there is one, then
      # we have to consider bigger bounds for the full widget — the union of the
      # content and the content translated by the offset (the imaging twin of
      # shadowExtendedRect's union, deliberately WITHOUT its expandBy(1) AA margin:
      # fullImage never included one, which keeps positive-offset images byte-identical).
      # A corner-ward growBy would SHRINK the canvas for a negative offset component
      # and clip the widget; the union covers any offset direction, and the
      # -bounds.origin ctx translate below places an up-left extension correctly.
      if !noShadow and @hasShadow()
        bounds = bounds.merge bounds.translateBy @shadowInfo.offset


    img = HTMLCanvasElement.createOfPhysicalDimensions bounds.extent().scaleBy ceilPixelRatio
    ctx = img.getContext "2d"
    # ctx.useLogicalPixelsUntilRestore()
    # we are going to draw this widget and its children into "img".
    # note that the children are not necessarily geometrically
    # contained in the widget (in which case it would be ok to
    # translate the context so that the origin of *this* widget is
    # at the top-left of the "img" canvas).
    # Hence we have to translate the context
    # so that the origin of the entire bounds is at the
    # very top-left of the "img" canvas.
    ctx.translate -bounds.origin.x * ceilPixelRatio , -bounds.origin.y * ceilPixelRatio
    @fullPaintIntoAreaOrBlitFromBackBuffer ctx, bounds

    if shadowHadBeenReplacedOrAdded
      @shadowInfo = originalShadow

    img

  # shadow is added to a widget by
  # the ActivePointerWdgt while floatDragging
  addShadow: (offset = new Point(4, 4), alpha = 0.2) ->
    @__addShadow offset, alpha
    @_fullChanged()

  __addShadow: (offset, alpha) ->
    @shadowInfo = new ShadowInfo offset, alpha
  
  hasShadow: ->
    @shadowInfo?
  
  removeShadow: ->
    if @hasShadow()
      @shadowInfo = undefined
      @_fullChanged()

  # The rect my paint touches, in MY OWN plane, when my content occupies aRect: the content,
  # its shadow (exactly the content translated by the offset — a union, not a scalar growth,
  # so ANY offset direction is covered and an asymmetric offset costs no overdraw on its
  # short axis), and 1 px of AA fringe. Without a shadow: aRect itself. The damage machinery
  # applies this IN MY OWN PLANE, BEFORE mapping to screen — my plane is where the shadow
  # paints, so an ancestor island's map then composes scale AND rotation over it exactly (a
  # post-map grow cannot: rotation turns the offset's screen direction, scale multiplies it).
  # Consumed by the flesh-out DESTINATION lanes and my own painted-footprint record
  # (_recordDrawnAreaForNextDamageRects); the flesh-out SOURCE lanes need no shadow term
  # because that record is already shadow-inclusive — adding one there would double-cover and
  # hide a record-time regression from the fixtures. (The shadow PAINTER is equally
  # direction-agnostic — the cull and ctx translates are vectors — so this rect is exact
  # for any offset.)
  shadowExtendedRect: (aRect) ->
    return aRect if !@shadowInfo?
    (aRect.merge aRect.translateBy @shadowInfo.offset).expandBy 1



  # Widget updating ///////////////////////////////////////////////////////////////
  _changed: ->
    # dropped while a _repaintAsOneUnit block is open: the unit's owner issues
    # the one covering mark at close, so per-child marks inside it would only
    # proliferate redundant damage rects. Each drop is COUNTED (monotonic, on
    # the world) so the closing unit can tell a vacuous body from one that
    # tried to mark — see _repaintAsOneUnit's skip condition.
    if world._damageSuppressionDepth > 0
      world._suppressedMarkAttempts++
      return

    # if the widget is attached to a hand then there is also a shadow to
    # change, so the whole carried composite must repaint — the hand
    # invalidates itself in this public notification
    if @isBeingFloatDragged()
      world.hand.noteCarriedWidgetChanged()
      return

    # you could check directly if it's in the array
    # but we use a flag because it's faster.
    if !@paintBoundsMaybeChanged
      # if we already issued a fullChanged on this widget
      # then there is no point issuing a change too.
      if !@fullPaintBoundsMaybeChanged
        world.widgetsWithMaybeChangedPaintBounds.push @
        @paintBoundsMaybeChanged = true

  # to actually make sure if a widget has changed
  # position, you need to check it and all its
  # parents.
  # See comment on the fullPaintBoundsMaybeChanged
  # property above for more info.
  hasMaybeChangedPaintBounds: ->
    if @fullPaintBoundsMaybeChanged or @paintBoundsMaybeChanged
      return true
    else
      if @parent?
        return @parent.hasMaybeChangedPaintBounds()
      else
        return false
  
  # See comment on the fullPaintBoundsMaybeChanged
  # property above for more info.
  _fullChanged: ->
    # (on the suppression depth and the attempt count see the note in `_changed` above)
    if world._damageSuppressionDepth > 0
      world._suppressedMarkAttempts++
      return
    # check if we already issued a fullChanged on this widget
    if !@fullPaintBoundsMaybeChanged
      world.widgetsWithMaybeChangedFullPaintBounds.push @
      @fullPaintBoundsMaybeChanged = true

  # fullChanged, but shadow-aware: if I contribute to an ancestor's shadow, the repaint
  # must start from the first parent OWNING that shadow (breaking only my own rect would
  # leave its stale shadow on screen), so walk up to it. A bare @_fullChanged needs this
  # walk iff the operation changes what the subtree CONTRIBUTES to an ancestor-owned
  # silhouette (appear/disappear/shape) — a move erases via the recorded shadow-inclusive
  # footprint, z-order cannot change the opacity union, and add/removeShadow's receiver
  # IS the owner, so those stay bare. Used by the appear/disappear structural verbs
  # (destroy/hide/show/toggleVisibility/removeFromTree/collapse/uncollapse/add).
  _fullChangedIncludingShadowOwner: ->
    firstParentOwningMyShadow = @firstParentOwningMyShadow()
    if firstParentOwningMyShadow?
      # cross-invalidation-sanctioned: shadow plumbing — the repaint must start from the
      # ancestor OWNING my shadow, or its stale shadow stays on screen
      firstParentOwningMyShadow._fullChanged()
    else
      @_fullChanged()

  # Run fn (a bulk child-positioning pass) with per-widget damage recording
  # suspended, then mark ME as the one damage unit covering everything fn did:
  # my box bounds every child the pass placed, so ONE owner rect replaces N
  # child rects at flush. Suspension nests: an inner unit's cover fires under
  # the outer depth and is dropped, and the outer owner's box covers it. The
  # restore AND the cover sit in `finally` — neither an early return nor a
  # throwing _reLayout can leak the depth or lose the covering repaint.
  # The cover is SKIPPED when provably vacuous: fn completed and not one
  # suppressed mark was attempted inside the unit — nothing the marking tiers
  # (_apply*/_reLayout) can see changed (an unchanged-bounds re-lay is all
  # identity no-ops), so the cover would only repaint identical pixels.
  # Nesting stays sound: an inner unit that saw attempts fires its cover
  # SUPPRESSED, which itself counts as an attempt, so the outer unit sees the
  # advancement; an inner unit with zero attempts contributes none. On an
  # exception the work fn did is unknown — cover unconditionally.
  _repaintAsOneUnit: (fn) ->
    attemptsAtOpen = world._suppressedMarkAttempts
    completed = false
    world._damageSuppressionDepth++
    try
      fn()
      completed = true
    finally
      world._damageSuppressionDepth--
      if !completed or world._suppressedMarkAttempts isnt attemptsAtOpen
        @_fullChanged()

  # Widget accessing - structure //////////////////////////////////////////////

  # Hierarchy/bounds change methods come in tiers (see
  # docs/architecture/layering-naming-convention.md): public self-settling setters at the top,
  # then the `_<name>NoSettle` cores and the `_apply*`/`_apply*Base` corners the
  # re-layout routines use, down to the `__commit*` leaves that trigger no
  # orchestration. (The old "silent"/"raw" method families were renamed away
  # 2026-07-02.)
  #
  # It's important that lower-level functions don't ever call the higher-level
  # functions, as that's architecturally incorrect and can cause infinite loops in
  # the invocations.

  _reactToBeingAdded: (whereTo, beingDropped) ->
    @_reLayoutSelf()

  # _addNoSettle (NOT add): these run from _addOrRemoveAdders during a layout pass, so a
  # self-settle would re-enter the flush guard; for the other caller
  # (showResizeAndMoveHandlesAndLayoutAdjusters, a menu action) it is byte-identical
  # because the frame settles anyway.
  # The index is the whole point of these two -- they compute it from MY own slot -- so they take
  # only the add family's other option, spelled the same way it is spelled on add().
  addAsSiblingAfterMe: (aWdgt, opts = {}) ->
    myPosition = @positionAmongSiblings()
    @parent._addNoSettle aWdgt, atIndex: (myPosition + 1), layoutSpec: opts.layoutSpec

  addAsSiblingBeforeMe: (aWdgt, opts = {}) ->
    myPosition = @positionAmongSiblings()
    @parent._addNoSettle aWdgt, atIndex: myPosition, layoutSpec: opts.layoutSpec

  # The layoutSpec a widget takes when added with NO explicit one -- the default for add() / _addNoSettle()'s
  # layoutSpec option. Plain widgets are free-floating; a widget with an intrinsic placement overrides this
  # so a caller can write the uniform `parent.add child` (no spec at the call site) and still get the right
  # attachment. The destination is passed so the placement can depend on it (e.g. a HandleWdgt corner-attaches
  # only to the very widget it resizes -- its @target -- and is free-floating on the world / hand otherwise).
  defaultLayoutSpecWhenAddedTo: (destination) ->
    undefined

  # ===== structural add =====
  # add() is the PUBLIC self-settling entry: it links the widget in through the private,
  # NON-settling _addNoSettle and then flushes layouts once (_settleLayoutsAfter), so a
  # top-level caller (app / macro / event handler) is left with a consistent world -- no manual
  # settle/yield. _addNoSettle is the COMPLETE add minus the settle (shadow management + structural
  # link-in + the fractional-record seed enqueue); add() is just the settle-wrap over it. Callers that
  # run INSIDE a layout pass (_reLayout / _reLayoutSelf), build their own innards during
  # construction, or tear down / re-home from a private chain call _addNoSettle DIRECTLY (it does not
  # settle, so it neither re-enters the flush guard nor triggers a redundant relayout). They are
  # byte-identical to going through add(): for a fresh non-world child the shadow step is a no-op
  # removeShadow. See docs/archive/deferred-layout-refit-and-add-design.md (D3).
  # No default for layoutSpec here on purpose: _addNoSettle is the ONE resolver
  # (`opts.layoutSpec ? aWdgt.defaultLayoutSpecWhenAddedTo(@)`). A default here too would state the
  # fallback twice — and since the base answer IS undefined, it also called the resolver twice per
  # add: once here, then again in the core because `?` saw the undefined it had just produced.
  # The options bag is handed to the core UNCHANGED, so the two faces of the same operation share
  # one vocabulary; the overrides below add keys (notContent, positionInPlane) that only their own
  # cores read, and a key its receiver does not read is simply ignored -- which is what lets one
  # caller write the same add against any container in the family.
  # opts.atIndex -- WHERE AMONG THE SIBLINGS, an integer index into @children (it reaches
  #   TreeNode._addChild as `@children.splice atIndex, 0, node`), NOT a screen position: a
  #   container that wants the latter takes opts.positionInPlane.
  # opts.layoutSpec -- the attachment; absent means ask the widget (see the core).
  # opts.beingDropped -- true only on the drop path, so a receiver can tell a user gesture from a
  #   programmatic add.
  add: (aWdgt, opts = {}) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, opts

  # _addNoSettle -- the COMPLETE add minus the settle. The single NON-settling core behind add() and
  # every internal layout-time / construction-time / teardown adder (it must NOT
  # flush layouts: it runs inside another mutation's settle, during construction, or from a
  # private teardown chain). Full semantics: shadow management + invalidate + __add (which
  # enqueues the fractional-record seed) + _reactToBeingAdded / _reactToChildAdded /
  # _reactToChildRemoved callbacks, but never recalculateLayouts. (The shadow step folds in
  # what add() used to do in its settle-wrap; it is a no-op for the fresh non-world
  # children the internal adders pass.)
  _addNoSettle: (aWdgt, opts = {}) ->
    atIndex = opts.atIndex
    layoutSpec = opts.layoutSpec ? aWdgt.defaultLayoutSpecWhenAddedTo(@)
    beingDropped = opts.beingDropped

    # let's check if we are trying to add
    # an ancestor of me below me.
    # That would be impossible to do,
    # so we return undefined to signal the error.
    if aWdgt.isAncestorOf @
      return undefined

    # shadow management (folded in from add()'s old settle-wrap): added to the world a widget
    # gains a drop-shadow; added anywhere else it loses one. Transient overlays (highlighter,
    # caret) opt out via skipsAddShadowManagement. For a fresh non-world child removeShadow is a
    # no-op, so the internal adders that call _addNoSettle directly stay byte-identical.
    unless aWdgt.skipsAddShadowManagement?()
      if @ == world
        aWdgt.addShadow()
        # adding to the world cancels scheduled tooltips, so a tooltip doesn't pop over what the
        # button just opened (e.g. the Simple Document "snippets" button).
        if !(aWdgt instanceof ToolTipWdgt)
          ToolTipWdgt.cancelAllScheduledToolTips()
      else
        aWdgt.removeShadow()

    previousParent = aWdgt.parent
    # FREEFLOATING-skip via _invalidateLayout(triggeringChild): pass aWdgt so its OLD parent skips
    # when aWdgt is freefloating (removing it only changes that parent's layout if it laid it out).
    # This runs BEFORE _setLayoutSpec below, so the param reads aWdgt's OLD spec -- correct. (The NEW
    # container is invalidated AFTER _setLayoutSpec, further down, also via the param.)
    aWdgt.parent?._invalidateLayout(aWdgt)

    aWdgt._fullChangedIncludingShadowOwner()

    aWdgt._setLayoutSpec layoutSpec
    # NEW-container invalidate via the param: _setLayoutSpec above set aWdgt.layoutSpec to the NEW
    # spec, so passing aWdgt makes me (the new container) skip iff aWdgt is now freefloating -- same
    # as the old `if layoutSpec != FREEFLOATING` guard, now centralized in _invalidateLayout.
    @_invalidateLayout(aWdgt)

    # cross-invalidation-sanctioned: structural-move dispatcher — the add orchestration
    # invalidates the widget being re-homed (its own tiers run non-notifying here)
    aWdgt._fullChanged()
    @__add aWdgt, atIndex: atIndex, skipExtentCalculation: true
    aWdgt._reactToBeingAdded @, beingDropped
    if previousParent?._reactToChildRemoved?
      previousParent._reactToChildRemoved aWdgt

    if @_reactToChildAdded?
      @_reactToChildAdded aWdgt

    # (The old synchronous world-add HALF-record died with the spec fold: it half-planted
    # POSITION so the drain's either-missing condition would complete the pair at
    # builder-final geometry -- an atomic StretchLayoutSpec cannot represent a half-record,
    # and the __add seed's drain alone IS the last-write-wins record.)
    return aWdgt

  sourceChanged: ->
    @_reLayoutSelf?()
    @_changed?()

  # this is done before the updating of the
  # backing store in some widgets that
  # need to figure out their whole
  # layout (which depends on the children)
  # before painting themselves
  # e.g. the MenuWdgt
  _reLayoutSelf: ->

  calculateAndUpdateExtent: ->

  # Does this container CONSUME this child's proportional placement record (a
  # StretchLayoutSpec on the child)? ONE membership rule per consumer, asked by the __add
  # seed below, both world drain stations, AND the consumer's own reflow -- so the seed's
  # exclusions and the arrange's read exclusions cannot drift. True only for the two
  # consumers -- WorldWdgt (desktop reflow on browser resize, position-only) and
  # StretchablePanelWdgt (full proportional re-lay) -- each stating its COMPLETE child
  # rule. Class-level query (type-test-elimination idiom -- no instanceof at the ask site).
  consumesFractionalGeometryOf: (child) ->
    false

  # The structural link-in, one level below _addNoSettle: it shares that family's option
  # vocabulary so the same key means the same thing at every layer of the add chain.
  # opts.atIndex -- WHERE AMONG THE SIBLINGS (an index into @children; absent means append), NOT a
  #   screen position. See TreeNode._addChild, which is where the confusion this name retires cost
  #   two callers a silently dropped placement.
  # opts.skipExtentCalculation -- the entrant's extent is about to be set by the caller, so do not
  #   compute it here. Named rather than positional because the one caller that passes it was
  #   writing a bare `true` at the call site (R1 names that a smell) and the two that wanted only
  #   atIndex had to write `undefined` past it (R3).
  __add: (aWdgt, opts = {}) ->
    # the widget that is being
    # attached might be attached to
    # a clipping widget. So we
    # need to do a "changed" here
    # to make sure that anything that
    # is outside the clipping Widget gets
    # painted over.
    owner = aWdgt.parent
    if owner?
      owner.removeChild aWdgt
    if aWdgt.isPopUpMarkedForClosure?
      aWdgt.isPopUpMarkedForClosure = false
    @_addChild aWdgt, opts.atIndex
    if !opts.skipExtentCalculation
      aWdgt.calculateAndUpdateExtent()
    # FRACTIONAL-RECORD SEED (framework-owned; stretch-fractional auto-bookkeeping arc):
    # entering a holder that consumes this child's fractional geometry REQUESTS a
    # proportional record (a StretchLayoutSpec); the world's drain station derives it
    # once, AFTER the current JS turn's builder code finished placing things -- "last
    # write wins", the semantics the historical per-call-site
    # _rememberFractionalSituationInHoldingPanel() protocol implemented by hand at every
    # placement endpoint. The membership exclusions (layout-inert chrome, the hand,
    # desktop icons) live in each consumer's consumesFractionalGeometryOf -- the ONE rule
    # the seed, the drains, and the consumer's reflow all ask. NOT recorded synchronously
    # here: many builders place AFTER adding, so an add-time record would pin
    # pre-placement geometry (the deferred-seed reasoning).
    if world? and @consumesFractionalGeometryOf aWdgt
      world.pendingFractionalBookkeepingSeeds.add aWdgt
    

  # Duplication and Serialization /////////////////////////////////////////


  # Duplicate the whole FIGURE — the widget PLUS any enclosing transform-island plumbing — not just the
  # content widget. A widget's rotation/scale does not live on the widget: it lives on an enclosing
  # TransformFrameWdgt island of which the widget is the sole content (materialized by the
  # setRotationDegrees/setScaleFactor sugar). @fullCopy's scope is @allChildrenBottomToTop() — my own
  # subtree — so copying the CONTENT leaves the island out and the copy "resets" its transform.
  # _enclosingIslandFigure() resolves that island (or returns me off any island — the entire
  # un-transformed population, so this is byte-identical dormant there). The island's fullCopy deep-copies
  # the transform for free (§1a: TransformSpec rides the Duplicator walk). Offset the copy from the
  # FIGURE's position; the island's _applyMoveTo rides a pinned anchor along (Bug-G), so a plain offset
  # move of the copied figure is anchor-safe.
  duplicateMenuAction: ->
    figure = @_enclosingIslandFigure()
    aFullCopy = figure.fullCopy()
    return if !aFullCopy?
    aFullCopy._unlockFromPanels()
    world.add aFullCopy
    aFullCopy._applyMoveTo figure.position().add new Point 10, 10
    # RE-RECORD (the F6 family, auto-bookkeeping arc): the copy deep-copied the ORIGINAL's
    # fractional bookkeeping, which the fill-only seed respects -- re-derive at the offset
    # position or the next desktop reflow snaps the copy onto the original.
    aFullCopy._rememberFractionalSituationInHoldingPanel()

  # The OTHER duplication verb: same figure resolution as duplicateMenuAction (see its comment above for
  # why the copy must be the FIGURE and not the bare content), but the copy goes ONTO THE HAND instead of
  # standing where the original is. Normalize a possibly-pinned anchor first, matching the Bug-G pick-up
  # seam — the whole hand-carry pipeline assumes a slot-centre pivot. Only islands define
  # _normalizePinnedAnchorNoSettle (the `?.` no-ops off any island); the copy is a detached root, so no
  # settle is needed here — pickUp's own settle covers it.
  # PUBLIC API WITH NO MENU ITEM, deliberately: arc 3 phase 7 unified the two entry pages onto ONE
  # "duplicate" item meaning copy-in-place (the less surprising end-user behaviour), so this variant is
  # reachable only programmatically. Do not re-add it to a context menu without an owner decision.
  duplicateAndPickItUp: ->
    figure = @_enclosingIslandFigure()
    aFullCopy = figure.fullCopy()
    aFullCopy?._normalizePinnedAnchorNoSettle?()
    aFullCopy?.pickUp()

  # in case we copy a widget, if the original was in some
  # data structures related to damaged widgets, then
  # we have to add the copy too.
  alignCopiedWidgetToDamageInfoDataStructures: (copiedWidget) ->
    # the world owns its damage-bookkeeping lists — it inherits the mark onto the
    # copy itself in this public notification (widget-citizenship point 2); this
    # deep-copy hook used to push onto world.widgetsWithMaybeChanged* directly
    world.noteWidgetCopied @, copiedWidget

  # in case we copy a widget, if the original was in some
  # stepping structures, then we have to add the copy too.
  alignCopiedWidgetToSteppingStructures: (copiedWidget) ->
    if world.steppingWdgts.has @
      world.steppingWdgts.add copiedWidget

  # in case we copy a widget, if the original was receiving
  # keyboard events, then we have to add the copy too.
  alignCopiedWidgetToKeyboardEventsReceiversSet: (copiedWidget) ->
    if world.keyboardEventsReceivers.has @
      world.keyboardEventsReceivers.add copiedWidget

  # THE ARROW CONTRACT's copy closure (reference-widgets plan §4.4): the set of widgets that
  # count as IN-STRUCTURE for a copy or a save of me — my own subtree, PLUS, through every
  # in-structure icon that presents as content (ShortcutWdgt.representsContents), the referent's
  # whole FIGURE (island included, the same resolution close/trash use), recursively. The
  # visited-set fixpoint matters: folder-in-folder filings make reference-through-containment
  # cycles constructible, and the Duplicator's identity map only handles cycles INSIDE the walk,
  # not in this set computation before it. An ARROW'D in-structure shortcut contributes nothing —
  # its referent stays outside the set, so a copy shares it, per its own glyph.
  # Returns {structure, referentFigures}: `structure` feeds the Duplicator's in-structure set and
  # the Serializer's object table (Serializer.buildEnvelope is the second consumer — one closure,
  # so copy and save cannot disagree about what a content icon carries); `referentFigures` are
  # the contributed figures, which the copy path files to the SHELF (fullCopy below) and the save
  # path encodes as detached embedded roots (their restore homing lives in
  # ShortcutWdgt._afterDeserialization).
  allWidgetsInStructureForCopy: ->
    structure = @allChildrenBottomToTop()
    inStructure = new Set structure
    referentFigures = []
    i = 0
    while i < structure.length
      w = structure[i]
      i++
      continue unless w.representsContents and w.referencedWidget? and !w.referencedWidget.destroyed
      figure = w.referencedWidget._enclosingIslandFigure()
      continue if inStructure.has figure
      referentFigures.push figure
      for member in figure.allChildrenBottomToTop()
        continue if inStructure.has member
        inStructure.add member
        structure.push member
    {structure, referentFigures}

  # note that the entire copying mechanism
  # should also take care of inserting the copied
  # widget in whatever other data structures where the
  # original widget was.
  # For example, if the Widget appeared in a data
  # structure related to the damage rectangles mechanism,
  # we should place the copied widget there.
  # double-settle-sanctioned: branch-exclusive — the destroyed arm informs and returns before
  # the settle-wrapped referent filing can run.
  fullCopy: ->
    if @destroyed
      @inform "The item you are\ntrying to copy\nis dead!"
      return undefined
    {structure, referentFigures} = @allWidgetsInStructureForCopy()
    duplicator = new Duplicator structure
    copiedWidget = duplicator.duplicate @
    if referentFigures.length > 0
      @_settleLayoutsAfter => @_fileCopiedReferentFiguresToShelfNoSettle duplicator, referentFigures
    return copiedWidget

  # The copy-side placement rule (plan §4.4): each contributed referent's fresh copy is
  # explicitly FILED to the shelf — the drain cannot home it (a reachable orphan is homeless,
  # not misfiled), and the copy must not appear open on the desktop even when the original's
  # window is open. The icon copy itself lands wherever the gesture puts it, as today. The
  # copied shortcuts' tracker enrollment is the Duplicator's own
  # alignCopiedWidgetToReferenceTracker hook, which also marks the storage sort.
  _fileCopiedReferentFiguresToShelfNoSettle: (duplicator, referentFigures) ->
    for figure in referentFigures
      world.shelfWdgt._addRestingWidgetNoSettle duplicator.cloneOf figure
    world.noteStorageMembershipMayHaveChanged()
    return

  # Serialization — delegates to the src/serialization/ Serializer. Unlike the old dev-only
  # prototype this replaced, serialize/deserialize SHIP in all builds (including production):
  # they are a product feature, so they carry NO homepage-strip markers. Only the dev
  # "test menu" entries that drive them (serialiseToMemory etc., MenusHelper.testMenu) stay
  # homepage-stripped. See docs/architecture/serialization-duplication-reference.md.
  serialize: (opts) ->
    Serializer.serializeWidget @, opts


  # Deserialization -----------------------------------


  # Returns the restored, DETACHED widget (the caller attaches it). Callers that need the
  # async-decode readiness promise (SWCanvas image/canvas decode) should call
  # Deserializer.deserialize directly and await its .whenReady; the widget returned here
  # fills its canvases in within a frame.
  deserialize: (serializationString) ->
    Deserializer.deserialize(serializationString).widget

  # Save this widget subtree to a downloaded *.fzw.json file over file:// (a product
  # feature — ships in all builds). A SerializationError (an external pointer that can't be
  # encoded, ...) becomes a friendly, path-carrying dialog rather than an uncaught throw.
  saveToFile: ->
    # Serialize the whole FIGURE (widget + transform-island plumbing), the same figure resolution as
    # duplicateMenuAction, so a rotated/scaled widget saves WITH its transform. Serializing the bare
    # CONTENT loses it: the Serializer clears the ROOT's parent by policy (the island is the parent), and
    # because the content also keeps a non-parent reference to its island the walk actually THROWS a
    # SerializationError ("… is outside the serialized structure") rather than silently dropping it —
    # either way the saved *.fzw.json is wrong. Off any island the figure IS me (byte-identical). The
    # filename stays derived from the CONTENT — the thing the user believes they are saving — not the
    # invisible frame. Restore needs no change: FileLoading attaches whatever the envelope's root is, and
    # a restored TransformFrameWdgt root is proven live (§1a).
    figure = @_enclosingIslandFigure()
    try
      envelope = figure.serialize prettyPrint: true
    catch error
      if error instanceof SerializationError
        world.inform error.toString()
        return
      else
        throw error
    FileSaving.saveStringAsFile envelope, @colloquialName() + ".fzw.json"

  # Injecting code /////////////////////////////////////////

  # if a function, the txt must contain the parameters and
  # the arrow and the body
  injectProperty: (propertyName, txt) ->
    # this.target[propertyName] = evaluate txt
    @evaluateString "@" + propertyName + " = " + txt
    # if we are saving a function, we'd like to
    # keep the source code so we can edit Coffeescript
    # again.
    if Utils.isFunction @[propertyName]
      @[propertyName + "_source"] = txt
      # log the instance-scope source edit so a world snapshot can carry it (§12). The edit
      # also rides serialization on its own via `<name>_source` -> {"$src"}; the registry adds
      # auditability. (A re-injection during a snapshot restore re-logs harmlessly — the loader
      # replaces the whole registry from the snapshot's records.)
      world?.sourceEditsRegistry?.recordInstanceEdit? @, propertyName, txt
    @sourceChanged()

  injectProperties: (codeBlurb) ->

    codeBlurb = codeBlurb.replace(/^[ \t]*$/gm,"\n")
    codeBlurb = codeBlurb + "\n# end injected code"

    # ([a-zA-Z_$][0-9a-zA-Z_$]*) is the variable name
    regex = /^([a-zA-Z_$][0-9a-zA-Z_$]*)[ \t]*=[ \t]*([^]*?)(?=^[\w#$])/gm

    while (m = regex.exec(codeBlurb))?
      # This is necessary to avoid infinite loops with zero-width matches
      if m.index == regex.lastIndex
        regex.lastIndex++
      @injectProperty m[1],m[2]

  # the remove twin of injectProperty ("Own" keeps it clear of InspectorWdgt's
  # same-named zero-arg button actions, which would otherwise shadow these on
  # inspectors -- inspectors are Widgets too): drops the member AND its
  # <name>_source companion -- the companion rides serialization as {"$src"}
  # and would re-inject the removed member on snapshot restore.
  removeOwnProperty: (propertyName) ->
    delete @[propertyName]
    delete @[propertyName + "_source"]
    @sourceChanged()

  # the rename twin: re-keys the member and moves the <name>_source companion
  # with it, so a snapshot restores the member under the new name only.
  renameOwnProperty: (oldName, newName) ->
    @[newName] = @[oldName]
    delete @[oldName]
    if @[oldName + "_source"]?
      @[newName + "_source"] = @[oldName + "_source"]
      delete @[oldName + "_source"]
    @sourceChanged()

  # Widget dragging (and dropping) /////////////////////////////////////////
  
  # (In this comment section "non-float" dragging and "dragging" are
  # interchangeable unless made explicit)
  #
  # Usually when you "stick" a Widget A onto another B, it
  # remains "solid" to its parent, so A grabs to B when dragged.
  #
  # On the other hand, a SliderButton doesn't grab to the parent when
  # dragged, rather it's loose, as expected. (The fact that it
  # stays within the bounds of the parent when dragged is another matter).
  #
  # So via this method the system can determine what the
  # "top of the drag" is starting from any Widget.
  # The process of finding the top of the drag involves going up
  # the chain and finding the first Widget that is loose. Then that
  # will be the top of the drag, and the whole TREE under that widget
  # will be dragged.
  #
  # If the widgets grab each other up to the WorldWdgt, then the World
  # can't be dragged, so there is no drag happening.
  #
  # Usually though at some point up the chain a widget won't
  # grab to its parent, so a dragging top is indeed found.
  #
  # Example chain: A grabs to parent B doesn't grab to parent C.
  # So A can be dragged: the whole tree under B is dragged (i.e. A B in
  # this case).
  #
  # If going up the chain of "grabbing" Widgets a Widget rejects being
  # dragged then the drag will be prevented. This rejection happens
  # via the "rejectDrags" method. In that way, for example
  # for the ColorPaletteWdgt, you can avoid grabs (because drags on
  # a ColorPaletteWdgt are expected to pick colors).
  #
  # So in the case above if B returns true in rejectDrags, then B
  # can be dragged and none of the children of B can be dragged either
  # (so: nor A nor B can't be dragged).
  #
  # Note that there is no away to prevent users from "picking up"
  # a Widget and then do a drag (which in that case would be a FLOATING drag).

  grabsToParentWhenDragged: ->
    # Affine transforms (§6 Phase 4D-2a): the Phase-1-symmetric escalation guard that USED to force a
    # widget inside a non-identity island to grab-to-parent (so a float-drag lifted the whole island) is
    # REMOVED — the loose unit is now resolved by the normal rules below, and ActivePointerWdgt's grab
    # dispatch maps it to the on-hand figure via _resolvePickOutFigureNoSettle (reuse the existing island
    # when the grabbed widget is its sole content — the Phase-1 whole-figure grab, no jump — or extract +
    # re-wrap a genuine sub-part). This is what lets you pick a SUB-widget OUT of an island. (Non-float
    # drags — sliders/handles — are unaffected: findFirstLooseWidget checks nonFloatDragging FIRST.)
    if @parent?

      if @parent == world
        return @isLockingToPanels

      if @_amIDirectlyInsideViewport()
        if @parent.parent.canScrollByDraggingForeground and @parent.parent.anyScrollBarShowing()
          return true
        else
          return @isLockingToPanels

      if @parent instanceof PanelWdgt
        return @isLockingToPanels

      # not attached to desktop, not inside a scrollable Panel
      # and not inside a Panel.
      # So, for example, when this widget is attached to another widget
      # attached to the world (because then it should remain solid
      # with the parent) — UNLESS the parent DECLARES this child detachable
      # (wantsDetachOfChild, a parent-side opt-in query like wantsDropOfChild): a
      # non-panel HOST whose child is a payload, not a part. First client: the spreadsheet
      # widget-entry cell (F4) — its hosted payload must float-drag back out exactly as it
      # would out of a panel, and without this the grab climbs to the window and the payload
      # is ungrabbable. No other class defines the query, so everywhere else this is inert.
      if @parent.wantsDetachOfChild? @
        return false
      return true

    # doesn't have a parent
    return false

  rejectDrags: ->
    @defaultRejectDrags

  # finds the first widget (including this one)
  # that doesn't grab to its parent
  # returns undefined if going up the grabbing chain
  # a widget rejects the drag
  findFirstLooseWidget: ->
    if @rejectDrags()
      return undefined

    if @nonFloatDragging?
      return @

    if !@grabsToParentWhenDragged()
      return @

    scanningWidgets = @
    while scanningWidgets.parent?
      scanningWidgets = scanningWidgets.parent

      if scanningWidgets.rejectDrags()
        return undefined

      if scanningWidgets.nonFloatDragging?
        return scanningWidgets

      if !scanningWidgets.grabsToParentWhenDragged()
        return scanningWidgets

    return undefined

  findRootForGrab: ->
    return @findFirstLooseWidget()

  # Asked by ShortcutWdgt.bringUpReferencedWidget before I am shown: do I owe myself any
  # CONTENT first? Almost nothing does — a widget resting in storage is already whole — so the
  # default runs the callback INLINE. That is correctness rather than economy: going through a
  # promise regardless would defer every shortcut click by a microtask, moving the open a whole
  # world cycle later, and the SystemTest suite measures cycles (../Fizzygum-tests/DETERMINISM.md).
  # ExamplesFolderWindowWdgt is the one overrider: its contents are five openers whose art is a LAZY
  # part, so it fetches them here, the first time it is opened.
  # ⚠ This DOES add a public member to Widget.prototype, which every inspector lists, so it churns
  # the inspector reference set — recaptured deliberately. The alternative (defining it only on the
  # folder and dispatching with ?()) would have been chosen to dodge a screenshot rather than on
  # merits: "is this widget ready to be shown?" is a question any bring-up target can be asked, and
  # a hook with a sensible default is what that is.
  whenReadyToBeBroughtUp: (callback) ->
    callback()

  # Am I loose content living directly on a viewport's plane? Two role queries on the
  # grandparent (scroll-frame role plan P3): isMyContentsPanel — is my parent the panel that
  # the viewport clips and scrolls (any plane class: the default ScrolledPaneWdgt, a folder/tool
  # panel, a stack) — and contentsPanelHoldsLooseContent, which a ListWdgt answers false to
  # (its pane holds rows machinery, not loose content).
  _amIDirectlyInsideViewport: ->
    if @parent?.parent?.isMyContentsPanel? @parent
      return @parent.parent.contentsPanelHoldsLooseContent()
    return false

  _amIDirectlyInsideNonTextWrappingViewport: ->
    if @_amIDirectlyInsideViewport()
      if !@parent.parent.isTextLineWrapping
        return true
    return false

  # the only trick here is that we stop at the first
  # clipping widget, because if a widget is inside a clipping
  # widget, it doesn't contribute to any shadow.
  firstParentOwningMyShadow: ->
    if @hasShadow()
      return @

    scanningWidgets = @
    while scanningWidgets.parent?
      scanningWidgets = scanningWidgets.parent
      if scanningWidgets.clipsAtRectangularBounds
        return undefined
      if scanningWidgets.hasShadow()
        return scanningWidgets

    return undefined

  # if true, then the drag will be a float drag
  # otherwise it will be a nonfloating drag
  detachesWhenDragged: ->
    true
  
  isBeingFloatDragged: ->

    if !world.hand?
      return false

    # first check if the hand is floatdragging
    # anything, in that case if it's floatdragging
    # it can't be non-floatdragging
    if world.hand.nonFloatDraggedWdgt?
      return false

    # then check if my root is the hand
    if @root() == world.hand
      return true

    # if we are here it means we are not being
    # nonfloatdragged
    return false

  # Widget dragging (and dropping) /////////////////////////////////////////

  # finds the first parent that is a PopUp
  firstParentThatIsAPopUp: ->
    if !@parent? then return @
    return @parent.firstParentThatIsAPopUp()

  anyParentPopUpMarkedForClosure: ->
    if @isPopUpMarkedForClosure
      return true
    else if @parent?
      return @parent.anyParentPopUpMarkedForClosure()
    return false

  rootForFocus: ->
    if !@parent? or
      @parent == world
        return @
    @parent.rootForFocus()

  _moveInFrontOfSiblings: ->
    @moveAsLastChild()
    @_fullChanged()

  isInForeground: ->
    @rootForFocus()?.isLastChild()

  bringToForeground: ->
    # No-op guards: an already-last focus-root cannot be raised further, and a PARENTLESS
    # root (the world itself — every empty-desktop click routes here via mouseDownLeft —
    # or an orphan) has nothing to be raised within. In both cases the raise is structural
    # no-op and the invalidation below a gratuitous full repaint of the root — the
    # overwhelmingly common case, since every left-click press routes here. Suppressing
    # it is pixel-identical: repaint is byte-idempotent.
    return if @isInForeground() or !@rootForFocus()?.parent?
    @rootForFocus()?.moveAsLastChild()
    # cross-invalidation-sanctioned: z-order structural verb — invalidates the focus-root
    # it just raised (the moved widget), same dispatcher shape as _addNoSettle's
    @rootForFocus()?._fullChanged()


  # note that "propagateKillPopUps" doesn't necessarily
  # go up the "parent" trail, for pop ups this method goes up
  # another trail of pop up ownership named via the
  # "widgetOpeningThePopUp" property, that is
  # independent of the parent trail
  propagateKillPopUps: ->
    if @parent?
      @parent.propagateKillPopUps()

  mouseDownLeft: (pos) ->
    @bringToForeground()
    @escalateEvent "mouseDownLeft", pos

  mouseClickLeft: (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

  onClickOutsideMeOrAnyOfMyChildren: (functionName, arg1, arg2, arg3)->
    if functionName?
      @clickOutsideMeOrAnyOfMeChildrenCallback = [functionName, arg1, arg2, arg3]
      world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.add @
    else
      world.wdgtsDetectingClickOutsideMeOrAnyOfMeChildren.delete @

  _reactToBeingDropped: (whereIn) ->
    # RE-RECORD (the F6 family, auto-bookkeeping arc): a dropped widget usually carries
    # fractional bookkeeping from wherever it lived before, and the fill-only seed respects
    # existing values -- so every drop re-derives at the drop position explicitly. (For a
    # first-ever drop this coincides with what the seed's drain would fill.)
    @_rememberFractionalSituationInHoldingPanel()
    
  wantsDropOfChild: (aWdgt) ->
    return @_acceptsDrops

  # the SELF drop gate (public, pure, positive — layering/naming convention §3): the base default is
  # "yes, droppable"; BinOpenerWdgt overrides to refuse (the old FrameWdgt internal/external override
  # was replaced by ActivePointerWdgt's drag-embed dwell-to-arm state machine —
  # docs/specs/drag-embed-interaction-spec.md §6). (ex-rejectsBeingDropped,
  # polarity-flipped; a base default is required so a widget with no override still defaults droppable.)
  wantsToBeDropped: ->
    return true

  # Drag-embed PAYLOAD CLASS (docs/specs/drag-embed-interaction-spec.md §4). A payload that
  # requiresDeliberateEmbedding must be ARMED by a dwell (spec §6) before a release embeds it into a
  # receptive container; plain payloads embed instantly, as today. Base = plain (false); FrameWdgt
  # overrides true. (Capability, not `isFrame` at call sites — type-test-elimination convention.)
  requiresDeliberateEmbedding: ->
    return false

  enableDrops: ->
    @_acceptsDrops = true

  disableDrops: ->
    @_acceptsDrops = false
  
  pickUp: ->
    oldParent = @parent
    oldParent?._beforeChildPickedUp? @
    world.hand.grab @
    # if one uses the "deferred" API then we need to look
    # into the "desiredExtent" as the true extent has yet
    # to be settled
    if @desiredExtent?
      @_applyMoveTo world.hand.position().subtract @desiredExtent.floorDivideBy 2
    else
      @_applyMoveTo world.hand.position().subtract @fullBounds().extent().floorDivideBy 2
    # the DISPATCHER owns the callback's settle (rule [J] — the _reactToChildGrabbed twin in
    # ActivePointerWdgt.grab): the hook is a settle-neutral core (a framed citizen rebuilds its
    # payload through _resetToDefaultContents, GenericPanelWdgt), and this single settle
    # flushes it at the gesture — consistent on return, not riding the end-of-cycle flush. grab's own
    # settles above are already closed (dotted .grab — not a [T] subject pairing), so this opens
    # cleanly outside any pass.
    @_settleLayoutsAfter => oldParent?._reactToChildPickedUp? @

  # The menu "pick up" item (buildBaseWidgetClassContextMenu). Bare `pickUp` grabs the CONTENT widget the
  # menu opened on — which, for a rotated/scaled widget, rips the content off the hand un-transformed AND
  # strands the now-empty sugar island in the tree (nothing dissolves a contentless island). Resolve the
  # pick-up FIGURE first (the SAME resolution the drag path uses — reuse the sole-content island, so the
  # transform rides the hand and no island is stranded), then grab it via pickUp. Off any island the figure
  # IS me ⇒ identical to the old behaviour. Left as a distinct entry point (not a change to bare `pickUp`)
  # because pickUp has programmatic callers on DETACHED widgets (deserialiseFromMemoryAndAttachToHand,
  # test helpers) for which figure resolution is a no-op anyway.
  pickUpMenuAction: ->
    @_resolvePickUpFigure().pickUp()

  grabbedWidgetSwitcheroo: ->
    @
  
  situation: ->
    # answer a dictionary specifying where I am right now, so
    # I can slide back to it if I'm dropped somewhere else
    if @parent
      return (
        origin: @parent
        position: @position().subtract @parent.position()
      )
    undefined
  
  # Widget utilities ////////////////////////////////////////////////////////
  
  # Create a resize/move HandleWdgt of `type` and corner-attach it to myself (I become its @target), tracking
  # it in the temporary-adjusters set so it is torn down when handles are hidden. _addNoSettle (not add): a
  # hover-shown handle rides the showResize caller's frame, byte-identical to the old in-constructor corner-
  # attach. The explicit defaultLayoutSpecWhenAddedTo(@) is needed because a DIRECT _addNoSettle bypasses add()'s
  # default-arg resolution (and an intermediate container _addNoSettle, e.g. a windowed target, would otherwise
  # re-default the unset spec to FREEFLOATING before it reaches the handle).
  _addAndTrackHandle: (type) ->
    handle = new HandleWdgt type
    @_addNoSettle handle, layoutSpec: handle.defaultLayoutSpecWhenAddedTo(@)
    world.temporaryHandlesAndLayoutAdjusters.add handle

  # CONVERT (end-of-cycle-flush-drawdown): showing the resize/move handles is a DISCRETE menu/click action, so it
  # SELF-SETTLES (one flush per outermost public mutation). The handles attach via _addNoSettle (_addAndTrackHandle /
  # addAsSibling*), which only RIDE a settle; the trigger chain (mouseClickLeft -> trigger) provided none, so the
  # _addNoSettle invalidate rode the per-frame end-of-cycle flush. The recursion to @parent goes through the
  # NON-settling core so the whole show-handles tree flushes ONCE. (ViewportWdgt overrides the core, not this.)
  showResizeAndMoveHandlesAndLayoutAdjusters: ->
    @_settleLayoutsAfter => @_showResizeAndMoveHandlesAndLayoutAdjustersNoSettle()

  _showResizeAndMoveHandlesAndLayoutAdjustersNoSettle: ->
    # Affine transforms (§6 4A-2): resize/move handles now work on a widget INSIDE a non-identity
    # island — HandleWdgt.nonFloatDragging (and the grab-start offset in ActivePointerWdgt) map the
    # drag pointer through screenPointToMyPlane, so the dragged edge follows the island's rotated/
    # scaled axes. The Phase-1 refusal guard that used to `return` here is therefore lifted. (Float-
    # drag of island content resolves the on-hand figure via ActivePointerWdgt.determineGrabs →
    # _resolvePickOutFigureNoSettle — reuse the island when I am its sole content, else pick-out;
    # the old Phase-1 grabsToParentWhenDragged island-escalation was removed by 4D-2a.)
    if @isFreeFloating()
      # idempotent: this is reachable while my handles are already up (the
      # public method is callable without the menu-open teardown running in
      # between), and a repeat invocation must not stack a second identical
      # handle set on top of the first — the duplicates are invisible (same
      # positions) but double-paint the hairline glyphs and their shadows
      return if @children.some (c) -> world.temporaryHandlesAndLayoutAdjusters.has c
      @_addAndTrackHandle "resizeHorizontalHandle"
      @_addAndTrackHandle "resizeVerticalHandle"
      @_addAndTrackHandle "moveHandle"
      @_addAndTrackHandle "resizeBothDimensionsHandle"
      # Affine transforms (§6 Phase 4B-universal): EVERY free-floating widget gets a rotate handle at
      # the top-right of its halo. Dragging it rotates the widget via the halo rotation protocol
      # (rotationHalo_apply → the 4C sugar materialises an island on demand; an explicit island drives
      # its own spec). Requires 4A-2 (drag-delta mapping) so the sibling resize/move handles stay
      # correct once a rotation is in play.
      @_addAndTrackHandle "rotateHandle"
    else
      stackSiblingBefore = @lastSiblingBeforeMeSuchThat (m) -> m.layoutSpec?.isDivisionElement?()
      if stackSiblingBefore? and !@siblingBeforeMeIsA(StackElementsSizeAdjustingWdgt)
        newAdjuster = new StackElementsSizeAdjustingWdgt
        newAdjuster._divisionBox.axis = stackSiblingBefore.layoutSpec.axis
        world.temporaryHandlesAndLayoutAdjusters.add \
          @addAsSiblingBeforeMe newAdjuster, layoutSpec: newAdjuster._divisionBox


      stackSiblingAfter = @firstSiblingAfterMeSuchThat (m) -> m.layoutSpec?.isDivisionElement?()
      if stackSiblingAfter? and !@siblingAfterMeIsA(StackElementsSizeAdjustingWdgt)
        newAdjuster = new StackElementsSizeAdjustingWdgt
        newAdjuster._divisionBox.axis = stackSiblingAfter.layoutSpec.axis
        world.temporaryHandlesAndLayoutAdjusters.add \
          @addAsSiblingAfterMe newAdjuster, layoutSpec: newAdjuster._divisionBox
      if @parent?
        @parent._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle()

  
  # Pop a one-line bubble showing a VALUE. ⚠ The empty case is ABSENCE, not falsiness: `0`, `""`
  # and `false` are values somebody asked to see — the evaluation menu's "show selection" hands
  # this whatever the selected snippet evaluated to — so this tests `msg?`, never `msg`. Absence
  # is spelled the way the language spells it, as everywhere else in the codebase.
  # The `toString?` arm is not defensiveness about ordinary values: an object built with a null
  # prototype has no `toString` at all, and `String x` THROWS on it rather than answering.
  inform: (msg) ->
    text =
      if not msg?           then "undefined"
      else if msg.toString? then msg.toString()
      else Object.prototype.toString.call msg
    m = new MenuWdgt @, target: @, title: text
    m.addMenuItem "Ok"
    m.popUpCenteredAtHand world

  # The door to the Text/Number prompts. msg/callback are operands HERE — every
  # caller of this method supplies all three — but options on the constructors,
  # where SaveShortcutPromptWdgt supplies neither; this is the one place that
  # translates. opts: defaultContents, intendedWidth, floorNum, ceilingNum, isRounded.
  prompt: (msg, target, callback, opts = {}) ->

    promptOpts = Object.assign {}, opts, msg: msg, callback: callback

    # dispatch on the numeric ceiling (the old slider condition): a numeric
    # prompt gets the slider, a plain one is text-only.
    if opts.ceilingNum? or WorldWdgt.preferencesAndSettings.useSliderForInput
      prompt = new NumberPromptWdgt @, target, promptOpts
    else
      prompt = new TextPromptWdgt @, target, promptOpts

    prompt.popUpAtHand()
    prompt.tempPromptEntryField.text.edit()

  # The door to the code-entry prompt. It takes no numeric range — CodePromptWdgt
  # has no slider — so the head stops at the three operands.
  textPrompt: (msg, target, callback, opts = {}) ->

    prompt = new CodePromptWdgt target, (Object.assign {}, opts, msg: msg, callback: callback)
    world.openFrameWith prompt, (new Point 460, 400), world.hand.position().subtract(new Point 50, 100)


  # E5-exempt: three operands, no hole — no caller skips one to reach a later one.
  pickColor: (msg, callback, defaultContents) ->
    colorPrompt = new ColorPromptWdgt @, @, msg: msg, callback: callback, defaultContents: defaultContents
    colorPrompt.popUpAtHand()

  inspect: ->
    @spawnInspector @

  # the single inspector entry point. Every inspect path routes here:
  # the world menu and widget context-menu "inspect" items, the "dev -> inspect"
  # item (MenusHelper), and a text editor's "inspect selection". This is the
  # convenience wrapper that opens the inspector WINDOWED — its content fills a
  # 560x410 FrameWdgt that supplies the chrome + background + resizer. The
  # InspectorWdgt also renders and resizes correctly on its OWN now
  # (`world.add new InspectorWdgt target`): when free-floating it paints its own
  # background and is resized via its @resizer handle. This wrapper stays the
  # default for the menu/inspect paths; the naked path is the additional mode.
  # The inspectors are the LAZY `meta-tools` part, and these two methods are the only places core
  # reaches them. Two consequences, both deliberate:
  #
  # ⚠⚠ 1. `if InspectorWdgt?` is GONE and must not come back. For an eager part that guard reads
  # "this artifact does not have it, do nothing"; for a lazy one the class is equally undefined
  # merely because nobody has fetched it yet, so the guard would silently swallow the user's click
  # forever. The two cases need opposite responses, and only a PART-level question separates them:
  # `world.parts.isAvailable` asks "did this artifact ship it at all" (a `lean` build did not, and
  # there is genuinely nothing to open), and the await handles "here, but not yet".
  #
  # ⚠⚠ 2. The class is named as a STRING. buildSystem/check-part-edges.js requires a guard wherever
  # core names a part-owned class as a SYMBOL, and the correct guard for a lazy part does not exist
  # -- so the gate's own sanctioned escape applies: name it as DATA (`window["InspectorWdgt"]`)
  # after the load, exactly as PartsRegistry.launch does. Read that gate's "ONE DELIBERATE BLIND
  # SPOT" note before changing this back to a bare identifier.
  #
  # An inspector also reads class MEMBER MAPS, which exist only once the class source text has been
  # ingested -- and on a `sources: "lazy"` build that has deliberately not happened yet. So the part
  # and the reflective layer are both awaited here, in that order.
  # ⚠ Both already-loaded cases stay SYNCHRONOUS (whenAllLoaded runs its callback inline, and the
  # layer keeps its own `if loaded then ... else ...` branch): every build the suite runs has both
  # long before anything asks, and deferring the open by even a microtask would move the inspector's
  # appearance a world cycle later -- which the SystemTest suite measures (it drives the world cycle
  # by cycle, ../Fizzygum-tests/DETERMINISM.md), across the ~15 tests that open one.
  spawnInspector: (inspectee) ->
    return unless world.parts.isAvailable "meta-tools"
    openTheInspector = ->
      # door-callback law (PartsRegistry's header), guarding here rather than at the
      # whenAllLoaded hop because this closure runs after a SECOND await (the reflective
      # layer) — one guard at the acting site covers both waits
      return if inspectee.destroyed
      inspector = new (window["InspectorWdgt"]) inspectee
      world.openFrameWith inspector, (new Point 560, 410), world.hand.position().subtract(new Point 50, 100)
    world.parts.whenAllLoaded ["meta-tools"], ->
      if reflectiveLayerIsLoaded() then openTheInspector() else ensureReflectiveLayerLoaded().then openTheInspector

  # The console does NOT read the class member maps, so it needs the part but not the reflective
  # layer. See spawnInspector above for why the guard is part-level and the class named as data.
  createConsole: ->
    return unless world.parts.isAvailable "meta-tools"
    openTheConsole = =>
      # door-callback law (PartsRegistry's header): I can die while the part is in flight
      return if @destroyed
      consoleWdgt = new (window["ConsoleWdgt"]) @
      world.openFrameWith consoleWdgt, (new Point 285, 290), world.hand.position().subtract(new Point 50, 100)
    world.parts.whenAllLoaded ["meta-tools"], openTheConsole

  spawnNextTo: (widgetToBeNextTo, whereToAddIt) ->
    if !whereToAddIt?
      whereToAddIt = widgetToBeNextTo.parent
    whereToAddIt.add @
    @_applyMoveTo widgetToBeNextTo.center()
    @_moveWithin whereToAddIt
    
  
  # Widget menus ////////////////////////////////////////////////////////////////
  
  # context Menus are whatever appears when one right-clicks
  # on something. It could be a custom menu, or the standard
  # menu on the desktop, or a menu to disambiguate which
  # widget it's being selected...
  buildContextMenu: ->

    widgetToAskMenuTo = @

    # check if a parent wants to take over my menu (and hopefully
    # merge some of my entries!). In such case let it open the
    # menu. Used for example for scrollable text (which is text inside
    # a ViewportWdgt).
    # the FIELD is the single truth (Widget default false; TextAreaWdgt sets
    # it true) — the `instanceof ViewportWdgt` qualifier is dropped, and the one non-scroll
    # writer (SimpleTextPanelWdgt's dead constructor write) deleted with it; old saved
    # documents are normalized at load (type-test-elimination ε; see
    # SimpleTextPanelWdgt._afterDeserialization)
    anyParentsTakingOverMyMenu = @allParentsTopToBottomSuchThat (m) ->
      m.takesOverAndMergesChildrensMenus
    if anyParentsTakingOverMyMenu? and anyParentsTakingOverMyMenu.length > 0
      widgetToAskMenuTo = anyParentsTakingOverMyMenu[0]

    if widgetToAskMenuTo.overridingContextMenu
      return widgetToAskMenuTo.overridingContextMenu()

    if world.isDevMode
      hierarchyMenuWidgets = widgetToAskMenuTo.getHierarchyMenuWidgets()
      # if the widget is attached to the world then there is no
      # disambiguation to do, just build the context menu.
      # Same if there would be one only entry in the hierarchyMenu
      # then again just build the context menu for that entry.
      # Otherwise we actually have to build the spacial
      # demultiplexing menu.
      if widgetToAskMenuTo.parent is world
        return widgetToAskMenuTo.buildWidgetContextMenu()
      else if hierarchyMenuWidgets.length < 2
        return hierarchyMenuWidgets[0].buildWidgetContextMenu()
      else
        return widgetToAskMenuTo.buildHierarchyMenu hierarchyMenuWidgets

  getHierarchyMenuWidgets: ->
    hierarchyMenuWidgets = []
    # Spacial multiplexing
    # (search "multiplexing" for the other parts of
    # code where this matters)
    # There are two interpretations of what this
    # list should be:
    #   1) all widgets "pierced through" by the pointer
    #   2) all widgets parents of the topmost widget under the pointer
    # 2 is what is used in Cuis
    parents = @allParentsTopToBottom()
    parents.forEach (each) ->
      # only add widgets that have a menu, and
      # leave out the world itself and the widgets that are about
      # to be destroyed
      if (each.buildWidgetContextMenu) and (each isnt world) and (!each.anyParentPopUpMarkedForClosure())
        # leave out a construct's internal structure — there is no need for the user to know
        # or have access to it. Two declarations decide (scroll-frame role plan P3):
        # * the PARENT hides a contained widget (a viewport hides its contents panel —
        #   plain pane or stack alike — and a folder window hides its viewport): the
        #   hidesContainedWidgetFromHierarchyMenu ?() query;
        # * the widget hides ITSELF (a MenuRowsPanelWdgt, the internal body of a menu /
        #   prompt / list): the hiddenFromHierarchyMenu ?() query.
        if (!(each.parent?.hidesContainedWidgetFromHierarchyMenu? each)) and
         (!each.hiddenFromHierarchyMenu?())
          hierarchyMenuWidgets.push each

    hierarchyMenuWidgets
  
  # When user right-clicks on a widget that is a child of other widgets,
  # then it's ambiguous which of the widgets she wants to operate on.
  # An example is right-clicking on a ToolTipWdgt: did she
  # mean to operate on the speech bubble or did she mean to operate on
  # the text widget contained in it?
  # This menu lets her disambiguate.
  buildHierarchyMenu: (widgetsHierarchy) ->
    if !widgetsHierarchy?
      widgetsHierarchy = @getHierarchyMenuWidgets()
    menu = new MenuWdgt @, target: @
    widgetsHierarchy.forEach (each) ->
      textLabelForWidget = each.toString().slice 0, 50
      textLabelForWidget = textLabelForWidget.replace "Wdgt", ""
      menu.addMenuItem textLabelForWidget + " ➜", each, "popupDeveloperMenu", closesUnpinnedPopUps: false, representsAWidget: true

    menu

  popupDeveloperMenu: (widgetOpeningThePopUp)->
    @buildWidgetContextMenu(widgetOpeningThePopUp).popUpAtHand()

  popUpColorSetter: ->
    @pickColor "color:", "setColor", Color.BLACK


  transparencyPopout: (menuItem)->
    @prompt menuItem.parent.title + "\nalpha\nvalue:", @, "setAlphaScaled",
      defaultContents: (@alpha * 100).toString()
      floorNum: 1
      ceilingNum: 100
      isRounded: true

  # the pinout debug overlay lives in its own dev-only collaborator (src/PinoutsOverlay.coffee),
  # reached through a soak so a build without it simply has no pinouts. These two stay here
  # because they are the widget's own context-menu ACTIONS (MenusHelper wires the menu items
  # to these names on the target widget).
  # ⚠ They take NOTHING: the menu wires them onto the very widget being pinouted, so the subject is
  # the RECEIVER. Four dispatcher slots here would only route `@` back in as an argument — and did,
  # which is what made the one macro caller write `w.showOutputPins undefined, w`.
  showOutputPins: ->
    world.pinouts?.show @

  removeOutputPins: ->
    world.pinouts?.remove @

  buildBaseWidgetClassContextMenu: (widgetOpeningThePopUp) ->

    menu = new MenuWdgt widgetOpeningThePopUp, target: @, title: ((@constructor.name.replace "Wdgt", "") or (@constructor.toString().replace "Wdgt", "").split(" ")[1].split("(")[0])

    # ONE widget context menu — no isIndexPage fork; "duplicate" is copy-IN-PLACE everywhere (D2).
    # See docs/archive/build-arc-3-phase-7-menu-topology.md.
    menu.addMenuItem "color...", @, "popUpColorSetter", toolTip: "choose another color \nfor this widget"
    menu.addMenuItem "transparency...", @, "transparencyPopout", toolTip: "set this widget's\nalpha value"
    menu.addMenuItem "resize/move...", @, "showResizeAndMoveHandlesAndLayoutAdjusters", toolTip: ("show a handle\nwhich can be floatDragged\nto change this widget's" + " extent")
    menu.addLine()
    # opt-out capability (?-dispatched, nothing on Widget): the bin opener refuses duplication —
    # the bin is one singleton, so a second opener could only alias it while its arrow-less icon
    # promises the thing itself (the arrow contract, reference-widgets plan §4.4).
    if !@_refusesDuplication?()
      menu.addMenuItem "duplicate", @, "duplicateMenuAction", toolTip: "make a copy"
    menu.addMenuItem "save to file…", @, "saveToFile", toolTip: "save this widget\nto a *.fzw.json file"
    menu.addMenuItem "create shortcut", @, "createReferenceFromMenu", toolTip: "creates a reference to this wdgt and leaves it on the desktop"
    menu.addMenuItem "pick up", @, "pickUpMenuAction", toolTip: "disattach and put \ninto the hand"
    menu.addMenuItem "attach...", @, "attach", toolTip: "stick this widget\nto another one"
    menu.addMenuItem "inspect", @, "inspect", toolTip: "open a window\non all properties"
    menu.addLine()

    # capability, instead of `(parent instanceof PanelWdgt) and !(parent instanceof ViewportWdgt)`
    # (type-test-elimination ε) — see PanelWdgt.childrenCanLockToMe
    if @parent?.childrenCanLockToMe?()
      if @parent == world
        whereToOrFrom = "desktop"
      else
        whereToOrFrom = "panel"
      if @isLockingToPanels
        menu.addMenuItem "unlock from " + whereToOrFrom, @, "toggleIsLockingToPanels", toolTip: "make this widget\nunmovable"
      else
        menu.addMenuItem "lock to " + whereToOrFrom, @, "toggleIsLockingToPanels", toolTip: "make this widget\nmovable"

    # "hide" leaves a widget with no product way back (only the dev tools can bring it round), so
    # it is dev-gated rather than page-gated. Same for the unrecoverable "destroy".
    if world.isDevMode
      menu.addMenuItem "hide", @, "hide"

    if @isFrame?()
      menu.addMenuItem "close", @, "close"
    else
      menu.addMenuItem "delete", @, "close"

    # only when it DIFFERS from the row above: with no inbound liveness edge, close/delete
    # already files binward and the drain keeps it there — the row would be a synonym paying
    # menu rent (reference-widgets plan §4.3; the P2 bind-row lesson).
    if @_wouldTrashSeverAnything()
      menu.addMenuItem "move to trash", @, "moveToTrash", toolTip: "sever every shortcut and wire\npointing at this widget,\nthen file it in the bin"

    # The dev/test tail. Each entry is gated on what makes it MEANINGFUL rather than on which page
    # we are: "dev ➜" and "destroy" on dev mode, "test menu ➜" on the demo family actually shipping
    # (a production build has no `demoMenus` at all).
    if world.isDevMode
      menu.addLine()
      menu.addMenuItem "dev ➜", menusHelper, "popUpDevToolsMenu", closesUnpinnedPopUps: false, toolTip: "dev tools"
      # ⚠ target is `world`, NOT `@`. The door has to live on ONE class, and putting it on Widget
      # adds a public member to every widget's prototype -- which the inspector faithfully lists, so
      # it churns the inspector-list reference screenshots for a method that has nothing to do with
      # the widget being inspected. The menu machinery passes the widget through the ARGUMENTS
      # (`@target[@action].call @target, @, @subjectOfAction`) rather than
      # through the target, so the door receives the same widget whatever the target is.
      menu.addMenuItem "test menu ➜", world, "popUpDemoTestMenu", closesUnpinnedPopUps: false, toolTip: "debugging and testing operations"  if world.parts.isAvailable "demos"
      menu.addMenuItem "destroy", @, "fullDestroy"

    menu

  # Widget-specific menu entries are basically the ones
  # beyond the generic entries above.
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    if @layoutSpec?.isStackElementActive?()
      # it could be possible to figure out layouts when the vertical
      # stack doesn't contrain the content widths but it's rather
      # more complicated so we are not doing it for the time
      # being
      if @parent?.constrainContentWidth
        @layoutSpec.addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu
    # a DIVISION cell gets its spec's own submenu ("layout in row/column ➜" — desired/max
    # size + cross-alignment). The layout CHROME (divider / adder / spacer) is a division
    # cell too, but its box is machinery working state, not a user knob — excluded by
    # capability, never a type test.
    else if @layoutSpec?.isDivisionElement?() and !@isLayoutChrome?()
      @layoutSpec.addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu
    # a DIVISION container — or a drop-slot-hosting CONTENT stack (a document's inner
    # stack) — gets the layout-scaffold toggle: "edit layout" shows the drop-slot adders
    # between the cells (fetching the lazy authoring part that carries them), "done
    # editing layout" removes them
    if @_divisionChildrenAxis()? or @hostsContentStackDropSlots?()
      @addLayoutEditingMenuEntries menu

  # The edit-layout toggle pair, on whatever widget OWNS the scaffold — called on self by
  # the gate above, and by a VIEWPORT on its contained stack (a document surfaces the
  # toggle on its own menu while the entries TARGET the inner stack, which is what the
  # user means by "the document's layout" — VerticalStackViewportWdgt).
  addLayoutEditingMenuEntries: (menu) ->
    menu.addLine()
    if @_showsAdders
      menu.addMenuItem "done editing layout", @, "removeAdders", toolTip: ""
    else
      menu.addMenuItem "edit layout", @, "editLayout", toolTip: "show drop-slots between the cells, to add or drop in new ones"

  buildWidgetContextMenu: (widgetOpeningThePopUp) ->
    menu = @buildBaseWidgetClassContextMenu widgetOpeningThePopUp
    @addWidgetSpecificMenuEntries widgetOpeningThePopUp, menu

    if @addShapeSpecificMenuItems?
      menu = @addShapeSpecificMenuItems menu
    menu

  # Widget menu actions
  calculateAlphaScaled: (alpha) ->
    if typeof alpha is "number"
      unscaled = alpha / 100
      return Math.min Math.max(unscaled, 0.1), 1
    else
      newAlpha = parseFloat alpha
      unless isNaN newAlpha
        unscaled = newAlpha / 100
        return Math.min Math.max(unscaled, 0.1), 1

  setPadding: (padding) ->
    if @paddingTop != padding or @paddingBottom != padding or @paddingLeft != padding or @paddingRight != padding
      @paddingTop = padding
      @paddingBottom = padding
      @paddingLeft = padding
      @paddingRight = padding
      @_changed()

    return padding

  setPaddingTop: (padding) ->
    if padding
      unless @paddingTop == padding
        @paddingTop = padding
        @_changed()

    return padding

  setPaddingBottom: (padding) ->
    if padding
      unless @paddingBottom == padding
        @paddingBottom = padding
        @_changed()

    return padding

  setPaddingLeft: (padding) ->
    if padding
      unless @paddingLeft == padding
        @paddingLeft = padding
        @_changed()

    return padding

  setPaddingRight: (padding) ->
    if padding
      unless @paddingRight == padding
        @paddingRight = padding
        @_changed()

    return padding

  setAlphaScaled: (alpha) ->
    if alpha
      alpha = @calculateAlphaScaled alpha
      unless @alpha == alpha
        @alpha = alpha
        @_changed()

    return alpha

  newParentChoice: (ignored, theWidgetToBeAttached) ->
    # this is what happens when "each" is
    # selected: we attach the selected widget
    # double-settle-sanctioned: deliberate SEQUENTIAL pair — @add self-settles the attach, then the
    # trailing settle flushes the Viewport re-fit once; one extra flush, idempotent with @add's
    # (see the long CONVERT comment below).
    @add theWidgetToBeAttached
    # I just attached the selected widget; if I am a viewport my contents changed, so re-fit my contents +
    # scrollbars. SELF-SETTLE it (CONVERT, end-of-cycle-flush-drawdown): this menu action is a DISCRETE public
    # mutation, so the re-fit must flush at the action, not ride the per-frame end-of-cycle flush. @add already
    # self-settled the attach; the _reFitContainer re-fit (NEEDED when the widget attaches directly, so @add took
    # the no-re-fit `super` path) now self-settles too -- one extra flush, idempotent with @add's. The
    # _reLayoutChildrenAndScrollbars? pre-guard keeps this Viewport-only -- only ViewportWdgt + subclasses
    # (incl. ListWdgt) define it; any other widget is a no-op (replacing `if @ instanceof ViewportWdgt`). NB it
    # is intentionally narrower than _reFitContainer's own _reLayoutChildren? gate (which also matches Window/Stack).
    @_settleLayoutsAfter(=> @_reFitContainer()) if @_reLayoutChildrenAndScrollbars?

  newParentChoiceWithHorizLayout: (ignored, theWidgetToBeAttached) ->
    # this is what happens when "each" is
    # selected: we attach the selected widget
    # double-settle-sanctioned: deliberate SEQUENTIAL pair, exactly as newParentChoice above.
    @add theWidgetToBeAttached, layoutSpec: theWidgetToBeAttached._ensureDivisionBox()
    # SELF-SETTLE my contents/scrollbar re-fit exactly as newParentChoice above (CONVERT, discrete menu action;
    # Viewport-only pre-guard; @add already self-settled the attach).
    @_settleLayoutsAfter(=> @_reFitContainer()) if @_reLayoutChildrenAndScrollbars?

  # Shared body of attach / attachWithHorizLayout: a menu of the plausible new parents (minus the current
  # parent); each item invokes `newParentActionName` on the chosen widget. The two entry points differ ONLY
  # in that action name. Ordinary widget behaviour, so a Widget method (not a global). attachWithHorizLayout
  # keeps its homepage-exclusion markers -- this shared helper is included (attach ships), the excluded caller
  # is stripped.
  _attachToChosenParent: (newParentActionName) ->
    choices = world.plausibleTargetAndDestinationWidgets @

    # my direct parent might be in the
    # options which is silly, leave that one out
    choicesExcludingParent = []
    choices.forEach (each) =>
      if each != @parent
        choicesExcludingParent.push each

    if choicesExcludingParent.length > 0
      menu = new MenuWdgt @, target: @, title: "choose new parent:"
      choicesExcludingParent.forEach (each) =>
        menu.addMenuItem each.toString().slice(0, 50), each, newParentActionName, representsAWidget: true
    else
      # the ideal would be to not show the
      # "attach" menu entry at all but for the
      # time being it's quite costly to
      # find the eligible widgets to attach
      # to, so for now let's just calculate
      # this list if the user invokes the
      # command, and if there are no good
      # widgets then show some kind of message.
      menu = new MenuWdgt @, target: @, title: "no widgets to attach to"
    menu.popUpAtHand()

  attach: ->
    @_attachToChosenParent "newParentChoice"

  attachWithHorizLayout: ->
    @_attachToChosenParent "newParentChoiceWithHorizLayout"
  
  toggleIsLockingToPanels: ->
    @isLockingToPanels = not @isLockingToPanels

  lockToPanels: ->
    @isLockingToPanels = true

  _unlockFromPanels: ->
    @isLockingToPanels = false

  # ---------------------------------------------------------------------
  # locking of contents

  # THE MENU ADAPTERS for the "enable editing" / "disable editing" lock entries — the shape of
  # createReferenceFromMenu above. ButtonWdgt dispatches a FIXED 4-slot convention
  # (`@target[@action].call @target, theButton, subject, arg1, arg2`), so an item carrying no arguments
  # of its own still arrives with WIDGETS in the leading slots. Here that matters because the four
  # container overrides of these verbs (FrameWdgt, ViewportWdgt, StretchablePanelWdgt,
  # StretchableWidgetContainerWdgt) read slot 1 as `triggeringWidget` — the widget whose own toggle
  # must not be echoed back at it (BubblesEditModeToCoordinatorMixin). A menu click has no such
  # widget, which is exactly what those cores' `if !triggeringWidget? then triggeringWidget = @`
  # fallback is for; taking NO parameter here is what lets the fallback fire.
  # ⚠ Point the lock menu items at THESE, never at the verbs: the verb has the real parameter, and
  # editButtonPressedFromFrameBar is a caller that genuinely supplies it.
  enableDragsDropsAndEditingFromMenu: ->
    @enableDragsDropsAndEditing()

  disableDragsDropsAndEditingFromMenu: ->
    @disableDragsDropsAndEditing()

  # SELF-SETTLE (single-mutation tier): unlock the contents settle-free, then flush ONCE (mirror of
  # disableDragsDropsAndEditing). Any entry point self-settles, so ordering vs world.add no longer matters;
  # the idempotency guard + per-child work live in the core.
  enableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_enableDragsDropsAndEditingNoSettle()

  _enableDragsDropsAndEditingNoSettle: ->

    if @dragsDropsAndEditingEnabled
      return
    @dragsDropsAndEditingEnabled = true

    if @contents?
      whereToAct = @contents
      if whereToAct.dragsDropsAndEditingEnabled
        return
      whereToAct.dragsDropsAndEditingEnabled = true
    else
      whereToAct = @


    @parent?.showEditModeInBar?()
    whereToAct.dragsDropsAndEditingEnabled = true

    whereToAct.enableDrops()

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets whereToAct

    if childrenNotHandlesNorCarets?
      for each in childrenNotHandlesNorCarets
        each._unlockFromPanels()
        each.contrastOutFromPanelColor?()
        if each.isEditable?
          each.isEditable = true


  # SELF-SETTLE (single-mutation tier): lock the contents settle-free, then flush ONCE. Any entry point (the edit
  # button, the "disable editing" menu, or a construction-time call) self-settles -- so calling this before or after
  # world.add is equally legal (an orphan defers in-flush, orphan-settledness). Idempotency guard + per-child work
  # live in the core; world.stopEditing routes to the NON-settling _stopEditingNoSettle (a caret teardown re-fits its
  # text, so the public stopEditing self-settles -- reaching it inside this flush would throw).
  disableDragsDropsAndEditing: ->
    @_settleLayoutsAfter => @_disableDragsDropsAndEditingNoSettle()

  _disableDragsDropsAndEditingNoSettle: ->
    if !@dragsDropsAndEditingEnabled
      return
    @dragsDropsAndEditingEnabled = false

    if @contents?
      whereToAct = @contents
      if !whereToAct.dragsDropsAndEditingEnabled
        return
      whereToAct.dragsDropsAndEditingEnabled = false
    else
      whereToAct = @


    @parent?.showViewModeInBar?()
    whereToAct.disableDrops()

    whereToAct.dragsDropsAndEditingEnabled = false

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets whereToAct

    if childrenNotHandlesNorCarets?
      for each in childrenNotHandlesNorCarets
        each.lockToPanels()
        each.blendInWithPanelColor?()
        if each.isEditable?
          each.isEditable = false
          if world.caret?.target == each
            world._stopEditingNoSettle()


  # ---------------------------------------------------------------------

  _beforeBeingGrabbed: ->
    @_unlockFromPanels()
    @_setLayoutSpec undefined

  # ── the PIN protocol ─────────────────────────────────────────────────────────────────────────
  # A PIN is a named property the dataflow can write, read, or both (PinSpec). `pins` is the whole
  # declaration: what I offer as a SINK. One list, whatever the kind -- so a pin that accepts any
  # value is declared once, and a pin that can be READ says so (both impossible to state while the
  # declaration was one write-only `[labels], [setterMethodNames]` table per kind).
  #
  # A subclass declares its own pins by concatenating onto `super`:
  #     pins: -> super().concat [ new PinSpec "value", "numerical", set: "setValue", get: "getValue" ]
  #
  # ⚠ Most of the pins below are WRITE-ONLY, and that is the honest state of the tree, not an
  # oversight: `@color` / `@alphaScaled` / the paddings are all readable FIELDS, but no reader
  # METHOD exists for them, and a pin's `get` is a promise the dataflow will dispatch by name.
  # Declaring a reader that isn't there would fabricate a contract (PinSpec's header).
  #
  # ⚠ `width` / `height` are write-only ON PURPOSE even though `width()` and `height()` are right
  # there. A readable pin is a licence to BIND, and nothing binds these: no consumer has ever wanted
  # to track a widget's width.
  #   ⭐ That is a positive choice, not a restriction. The one-way layout↔dataflow law permits a
  # readable geometry pin: connector §P8 measured and narrowed it to "layout may never markStale, but
  # it MAY markNonValueChange", and the feared one-frame shear does not occur on any path a gesture
  # drives (doOneCycle plays input BEFORE the dataflow station). ViewportWdgt's `scroll x` /
  # `scroll y` are readable on exactly that licence. So the bar for a readable geometry pin is a real
  # CONSUMER, not the law -- add the reader when something needs to track it.
  pins: ->
    declared = [
      new PinSpec "color",            "color",     set: "setColor"
      new PinSpec "background color", "color",     set: "setBackgroundColor"
      new PinSpec "width",            "numerical", set: "_applyWidth"
      new PinSpec "height",           "numerical", set: "_applyHeight"
      new PinSpec "alpha 0-100",      "numerical", set: "setAlphaScaled"
      new PinSpec "padding",          "numerical", set: "setPadding"
      new PinSpec "padding top",      "numerical", set: "setPaddingTop"
      new PinSpec "padding bottom",   "numerical", set: "setPaddingBottom"
      new PinSpec "padding left",     "numerical", set: "setPaddingLeft"
      new PinSpec "padding right",    "numerical", set: "setPaddingRight"
    ]
    # my appearance contributes its shape's own pins (BoxyAppearance's corner radius) -- the shape is
    # a collaborator, so its pins are declared where the shape is, not repeated on every widget that
    # can wear it.
    return declared.concat (@appearance?.pins?() ? [])

  # The pins a source of `kind` can actually DRIVE: read-only pins are dropped (nothing can drive
  # them), duplicates are resolved by SETTER NAME keeping the first (so an inherited declaration
  # wins over a subclass re-declaration of the same pin), and the result is sorted by label because
  # that is the order the "choose target property" menu presents.
  #   Passing no kind (or "any") asks for every drivable pin.
  # ⚠ Dedup is by setter name ON THE RECORD. The array version deduped its two arrays INDEPENDENTLY
  # with two separate Sets, so a label repeated against a different setter (or the reverse) shifted
  # one array and not the other and silently paired every later label with the wrong setter. That
  # whole failure mode is gone by construction: a pin is one object.
  pinsOfKind: (kind) ->
    seenSetterNames = new Set()
    matching = []
    for pin in @pins()
      continue if pin.isReadOnly()
      continue unless pin.acceptsKind kind
      continue if seenSetterNames.has pin.setterName
      seenSetterNames.add pin.setterName
      matching.push pin
    matching.sort (a, b) ->
      if a.label < b.label then -1 else if a.label == b.label then 0 else 1
    return matching

  # Find one of my pins by its LABEL -- the pin's identity. Every pin has one (a read-only pin has
  # no setter to be named by), it is unique within a widget's pin set, and it is what the menu
  # shows. This is how a class points at its own principal pin.
  pinLabelled: (label) ->
    for pin in @pins()
      return pin if pin.label is label
    return undefined

  # The OTHER lookup, by setter name: "a wire wrote this action; which pin did it write?" -- since a
  # wire stores its `@action` as the setter's name. It is what lets a control BOUND to me re-read the
  # very property it drives, with no second field naming that property: SliderWdgt.reflectTarget, the
  # reverse half of a scrollbar's wire (connector plan §P8).
  pinDrivenBy: (setterName) ->
    for pin in @pins()
      return pin if pin.setterName is setterName
    return undefined

  # The one pin whose value this widget offers when asked for its value with no pin named -- to a
  # spreadsheet reference, or to the dataflow drain. Declared per class as `principalPinLabel`;
  # a widget that declares none simply has no exported value.
  principalPin: ->
    return undefined unless @principalPinLabel?
    return @pinLabelled @principalPinLabel

  # The GRAPH EDGES I hold OUT of myself, as [{kind, to}] with kind one of 'flow' | 'command' |
  # 'reference' and `to` another WIDGET (docs/archive/graph-edges-and-lifecycle-plan.md §4.2, the
  # three-edge model). DERIVED on demand from the fields that already persist -- a controller's
  # wire list, a button's target, a shortcut's referent -- and deliberately backed by NO standing
  # edge index (decision G4 there: `@target` has no write funnel to hook one to, menu chrome would
  # churn it, and no reverse-query consumer exists). A contributor concatenates onto `super`
  # exactly as `pins` does. Containment is NOT enumerated here: the tree is its own, richer API
  # (children/parent), and every consumer of this protocol treats the subtree specially anyway.
  #   ⚠ Enumeration is honest; POLICY is not decided here. An ephemeral holder (a menu row is a
  # ButtonWdgt) truthfully reports its command edge -- which kinds confer liveness from which
  # holders is the consumers' question, not this protocol's. The two consumers agree on the
  # answer (decisions G5/G8 there): the storage classifier (StorageSorter._runClassifier) and
  # the close paths' park-vs-destroy query (WorldWdgt.anyReferenceOrWireIntoWdgt) both follow
  # flow + reference and let command confer nothing.
  graphEdgesOut: -> []

  # The shared body of every controller widget's openTargetPropertySelector: pop up the "choose
  # target property" menu, one item per drivable pin of the kind I produce. Each item wires
  # @action = that pin's setter onto theTarget via setTargetAndActionWithOnesPickedFromMenu (a
  # ControllerMixin method -- every caller @augmentWith's it).
  # Deliberately on Widget, NOT ControllerMixin: as an INHERITED member it is hidden from the
  # inspector's default own-props view, so the controllers' inspected member lists are unshifted --
  # a ControllerMixin method would be copied in as an OWN member of each and shift every one. (It
  # DOES surface in the rarer inherited-props inspector view.)
  _popUpTargetPropertyMenu: (theTarget, pins) ->
    menu = new MenuWdgt @, target: @, title: "choose target property:"
    for pin in pins
      menu.addMenuItem pin.label, @, "setTargetAndActionWithOnesPickedFromMenu", arg1: theTarget, arg2: pin.setterName
    if pins.length == 0
      menu = new MenuWdgt @, target: @, title: "no target properties available"
    menu.popUpAtHand()

  # Menu-dispatched, and now shared by every controller: the per-class stubs differed ONLY by which
  # of the four setter tables they passed, which `producesPinKind` now states as data instead.
  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    @_popUpTargetPropertyMenu theTarget, theTarget.pinsOfKind @producesPinKind

  # Widget entry field tabbing //////////////////////////////////////////////
  
  allEntryFields: ->
    # an entry field is any editable StringWdgt-family widget. isTextEntryField (on StringWdgt,
    # inherited by SimpleTextWdgt et al.) replaces the `instanceof StringWdgt or instanceof
    # SimpleTextWdgt` test -- whose second clause was already redundant, since
    # SimpleTextWdgt is-a StringWdgt. (type-test-elimination campaign)
    @collectAllChildrenBottomToTopSuchThat (each) ->
      each.isEditable and each.isTextEntryField?()
  
  
  nextEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf current
    if idx isnt -1
      if fields.length > (idx + 1)
        return fields[idx + 1]
    return fields[0]
  
  previousEntryField: (current) ->
    fields = @allEntryFields()
    idx = fields.indexOf current
    if idx isnt -1
      if idx > 0
        return fields[idx - 1]
      return fields[fields.length - 1]
    return fields[0]
  
  tab: (editField) ->
    #
    #	the <tab> key was pressed in one of my edit fields.
    #	invoke my "nextTab()" function if it exists, else
    #	propagate it up my owner chain.
    #
    if @nextTab
      @nextTab editField
    else @parent.tab editField  if @parent
  
  backTab: (editField) ->
    #
    #	the <back tab> key was pressed in one of my edit fields.
    #	invoke my "previousTab()" function if it exists, else
    #	propagate it up my owner chain.
    #
    if @previousTab
      @previousTab editField
    else @parent.backTab editField  if @parent
  
  
  
  # Widget events --------------------------------------------

  escalateEvent: (functionName, args...) ->
    handler = @parent
    if handler?
      handler = handler.parent  while not handler[functionName] and handler.parent?
      handler[functionName] args...  if handler[functionName]
  
  
  # Widget eval. Used by the Inspector and the text widget.
  # ⚠ The result is returned EXPLICITLY, and must stay that way. The relayout/repaint tail has to
  # run AFTER the eval, so without this line CoffeeScript returns `_changed()`'s value — `true` or
  # `undefined` — and the eval's own value is computed and dropped on the floor. Three callers read
  # what comes back: the evaluation menu's "show selection" and "inspect selection"
  # (`TextWdgt`) and `Deserializer.compileFunction`, which needs the live function it compiled.
  # None of them throws when handed the wrong thing, so `fg menusweep` cannot see a regression here
  # — this comment is the guard, together with `SystemTest_macroEvaluateStringReturnsItsValue`.
  evaluateString: (codeSource) ->
    JSCode = compileFGCode codeSource, true
    result = eval JSCode
    @_reLayoutSelf()
    @_changed()
    result
  
  


  # ------------------------------------------------------------------------------------
  # Layouts
  # ------------------------------------------------------------------------------------
  # So layouts in Fizzygum work the following way:
  #  1) Any Widget can contain a number of other widgets
  #     according to a number of layouts *simultaneously*
  #     e.g. you can have two widgets being horizontally stacked
  #     and two other widgets being inset for example
  #  2) There is no need for an explicit special container. Any
  #     Widget can be a container when needed.
  #  3) The default attaching of Widgets to a Widget puts them
  #     under the effect of the most basic layout: the FREEFLOATING
  #     layout.
  #  3) A user can only do a high-level resize or move to a FREEFLOATING
  #     Widget. All other Widgets are under the effect of more complex
  #     layout strategies so they can't be moved willy nilly
  #     directly by the user via some high-level "resize" or "move"
  #     Control of size and placement can be done, but indirectly via other
  #     means below.
  #  4) You CAN control the size and location of Widgets under the
  #     effect of complex layouts, but only indirectly: by programmatically
  #     changing their layout spec properties.
  #  5) You CAN also manually control the size and location of Widgets
  #     under the effect of complex layouts by using special Adjusting
  #     Widgets, which are provided by the container, and give handles
  #     to manually control the content. These manual controls
  #     under the courtains go and programmatically modify the layout
  #     spec properties of the content.


  # The division constraint box (min/desired/max, both axes) — a per-widget KNOB retained
  # for the widget's whole life (see DivisionStackLayoutSpec). Writers materialize a
  # private box; a widget without one reads through the shared immutable defaults.
  # The element back-ref binds HERE — the one place a private box is materialized — so the
  # spec's public setters can settle on their widget; the box never changes owner.
  _ensureDivisionBox: ->
    @_divisionBox ?= new DivisionStackLayoutSpec
    @_divisionBox.element ?= @
    @_divisionBox

  # PUBLIC face of the box (macros / demos / in-world scripting): the box doubles as the
  # ATTACHMENT value for adding a widget as a division element — `holder.add w, layoutSpec:
  # w.divisionBox()` for a horizontal row, `w.divisionBox('y')` for a vertical division
  # stack. Internal private callers use the _ensureDivisionBox core.
  divisionBox: (axis) ->
    box = @_ensureDivisionBox()
    box.axis = axis if axis?
    box

  _divisionBoxOrDefaults: ->
    @_divisionBox ? DivisionStackLayoutSpec.defaults()

  # The widget's content-stack spec (VerticalStackLayoutSpec / FrameContentLayoutSpec) as
  # currently relevant — SLOT-FIRST: the ACTIVE spec when it is content-stack-capable,
  # else the kept knob field. While armed the two are the same object, so this answers
  # byte-what a field read answers; the divergence is the sugar ISLAND, where the spec
  # rides ONLY the slot (the materialize's layoutSpec: add-arg — the kept field stays on
  # the wrapped content, one home per carrier). Slot-first is CORRECTNESS, not style: a
  # field read on an island answers undefined, the stack's init guard is skipped (the active
  # spec already matches), and _childWidthInStack falls back to raw available width
  # instead of proportional tracking — the historical failure the retired island
  # hand-carry (_moveKeptStackSpecTo) existed to paper over. Container-side reads go
  # through HERE; the field stays the home for the widget's OWN knob (initialisers and
  # class-default writers address it directly).
  contentStackSpec: ->
    if @layoutSpec?.isContentStackCapable?()
      @layoutSpec
    else
      @_contentStackSpec

  # The bare layout-enqueue ATOM: put me into the recalculateLayouts until-loop and mark my layout invalid, WITHOUT
  # climbing to ancestors and WITHOUT the flow-rule throw / careless-push audit that _invalidateLayout wraps around it
  # for the climbing content-widget case. This is the ONE primitive under all three enqueue paths: _invalidateLayout
  # (calls it, THEN climbs), _reFitContainer's in-pass arm (enqueue one directly-affected container, no climb --
  # up-propagation is restored by that container's own seam re-firing if its geometry moves), and the caret's
  # scroll-follow (an inert free-floating overlay, reached via _invalidateLayout's inert-receiver branch). NO CLIMB
  # (the ex-"NoClimb" suffix, dropped in the __ rename): this alone does NOT tell my container I changed -- a CONTENT widget must use
  # _invalidateLayout, which climbs. Only framework layout machinery calls this (the two methods above); feature code
  # schedules via _invalidateLayout. (docs/archive/unify-layout-enqueue-primitives-plan.md.)
  __markForRelayout: ->
    if @layoutIsValid then world.widgetsThatMaybeChangedLayout.push @
    @layoutIsValid = false

  # (ordered down-walk Stage B2) Flag me AND my ancestors as lying on a dirty path, stopping at the
  # first already-flagged node — above it the chain is already flagged, so a derivation batch over
  # the whole work-list costs O(total distinct chain nodes), the same order as the old drain's
  # climbs. Called ONLY by the settle engine's per-round derivation
  # (WorldWdgt._recalculateLayoutsBody), never at enqueue/attach time: the flags are FLUSH-LOCAL
  # scratch (parent pointers cannot change mid-flush, so a derived chain stays true for the whole
  # flush; outside a flush every flag is false). Every node flagged here is recorded on
  # world._widgetsFlaggedHasDirtyDescendant so recalculateLayouts' finally can clear exactly the flagged set.
  # Pure bookkeeping: never schedules layout.
  __flagHasDirtyDescendantUpwards: ->
    return unless world?
    ancestor = @
    while ancestor? and not ancestor.hasDirtyDescendant
      ancestor.hasDirtyDescendant = true
      world._widgetsFlaggedHasDirtyDescendant.push ancestor
      ancestor = ancestor.parent
    return

  _invalidateLayout: (triggeringChild) ->
    # FREEFLOATING-skip -- THE single home of the rule: a freefloating child's add/remove/resize
    # cannot change its parent's layout (it's positioned absolutely, not laid out by the parent).
    # The climb and every teardown/move site pass the child whose change triggered this invalidate;
    # an undefined triggeringChild is a direct self-invalidate from feature code. This return MUST stay
    # BEFORE the _recalculatingLayouts throw below: a freefloating teardown is a silent no-op today
    # (the inline `unless …isFreeFloating()` guard meant _invalidateLayout wasn't even called for it),
    # so it has to keep being a silent no-op even if it happens mid-pass -- it must never throw.
    if triggeringChild?.isFreeFloating()
      # (proper-layouts, PROPERTY sub-seam deletion 2026-07-01) A freefloating child normally can't change its
      # parent's layout (positioned absolutely), so its invalidate does NOT climb. EXCEPTION: if I (the parent) am
      # a size-TRACKING container (scroll / stack / window -- I define _reLayoutChildren) then the child's SIZE
      # genuinely IS tracked, so OFF-PASS let the invalidate CLIMB THROUGH (fall past this return) so I re-fit.
      # This is the uniform dirty-tree replacement for the deleted _announceLayoutPropertyChangeToContainer seam.
      # IN-PASS this stays skipped: in-pass container re-fits are handled by the settle loop's ORDERED settle-time
      # re-fit (_reFitMyTrackingContainerAfterSettle, §4.3), and climbing in-pass would hit the FLOWRULE throw below.
      return unless (@_reLayoutChildren? and not world?._recalculatingLayouts)
    # INERT-RECEIVER branch: a free-floating + inert overlay (caret / resize handle) has no parent layout to climb
    # into, and is excluded from every container's content-bounds (childrenNotHandlesNorCarets), so re-running its
    # _reLayout re-fits NOTHING above it. The climb, the flow-rule throw, and the careless-push audit below are
    # therefore all structurally INAPPLICABLE -- they PASS here, they are not silenced (the worry this resolves:
    # docs/archive/unify-layout-enqueue-primitives-plan.md §2). So enqueue just me, no climb. Gated on BOTH predicates so no
    # content widget can slip onto the no-climb path -- a content widget's container genuinely needs the climb. (This
    # is the single home of the caret's self-schedule, reached via CaretWdgt._requestScrollFollow -> here; today only
    # the caret exercises it -- handles are moved by drag machinery through immediate mutators, never self-invalidate.)
    if @isFreeFloating() and @isLayoutInert?()
      @__markForRelayout()
      return
    # FLOW-RULE INVARIANT (fail fast): the immediate geometry mutators (the _apply*/_commit* corners, __commit* leaves, _move*/_set*/_resize* convenience)
    # must not SCHEDULE layout -- they only mutate; scheduling a (re-)layout is the public
    # self-settling tier's job. If an invalidate reaches here while recalculateLayouts is running,
    # an immediate mutator is (re-)scheduling layout mid-pass -- the Phase 3b Slice 2 app-freeze (a
    # container resizing its children climbed an invalidate back into itself, so the until-loop
    # never converged). The immediate mutators were migrated to honour this and a build-time lint (rule
    # [E]) enforces it statically; this throw is the RUNTIME tripwire for anything that slips past
    # the lint (e.g. a dynamic/duck-typed call it can't see). The throw is safe to be hard now
    # (task #18): the recalculateLayouts catch is strictly non-flushing and defers recovery outside
    # the flush, so this throw is caught there, reported via the layout-error path (loud
    # console.error + in-world console), and the world keeps running -- never a freeze.
    if world?._recalculatingLayouts
      throw new Error "FLOWRULE_VIOLATION: _invalidateLayout() during a layout pass by " + (@constructor?.name) + " -- an immediate geometry mutator (an _apply*/_commit*/__commit* corner or _move*/_set* convenience) must not schedule layout (task #17)"
    # DEBUG (WorldWdgt.auditPaintTimeLayoutScheduling, default off): PAINT must be READ-ONLY. healingRectangles-
    # Phase is true only inside _repaintDamagedRects's paint pass; reaching here then means a widget SCHEDULED layout while
    # being painted -- crossing the render/layout boundary. Record its ctor for the per-frame paint-schedules log.
    # (The caret's paint-time scroll-follow, the original such offender, was moved to a post-flush pre-paint step.)
    if world?.healingRectanglesPhase and world.auditPaintTimeLayoutScheduling and not @isOrphan()
      (world._paintTimeLayoutSchedules ?= []).push @constructor?.name
    # DEBUG (WorldWdgt.auditUndeclaredEndOfCycle, default off): an OFF-SETTLE push (not @_inLayoutMutation) on
    # an ATTACHED widget made OUTSIDE a *DeferredSettle declaration (_deferredSettleDeclarationDepth == 0) is the
    # "careless" set the eventual declared-deferred-settling gate will reject -- record its ctor for the end-of-cycle
    # log. ORPHAN pushes are excluded: an off-world (under-construction) widget legitimately defers and settles
    # when attached (the _reactToChildRemoved lesson) -- it is not careless, and is the bulk of the macro-driver noise.
    # Recorded BEFORE __markForRelayout flips @layoutIsValid, and only on an ACTUAL push (@layoutIsValid still
    # true) -- an already-invalid widget is not re-pushed, so it must not be re-counted.
    if @layoutIsValid and world.auditUndeclaredEndOfCycle and world._deferredSettleDeclarationDepth == 0 and not world._inLayoutMutation and not @isOrphan()
      (world._undeclaredEndOfCyclePushes ?= []).push @constructor?.name
    # the bare enqueue (+ mark invalid): the shared primitive. The climb is this method's OWN extra responsibility,
    # added explicitly below -- __markForRelayout deliberately does not climb (see its comment).
    @__markForRelayout()
    # CLIMB: tell my parent that a child (me) changed. Pass @ so the parent short-circuits via the
    # return at the top iff I'm freefloating -- this replaces the old inline `unless @isFreeFloating()
    # and @parent?` climb-guard (the freefloating rule now lives in ONE place, the param check above).
    @parent?._invalidateLayout(@)

  setMinAndMaxBoundsAndSpreadability: (minBounds, desiredBounds, spreadability = DivisionStackLayoutSpec.SPREADABILITY_MEDIUM) ->
    box = @_ensureDivisionBox()
    box.minWidth = minBounds.x
    box.minHeight = minBounds.y

    box.desiredWidth = desiredBounds.x
    box.desiredHeight = desiredBounds.y

    box.maxWidth = desiredBounds.x + spreadability * desiredBounds.x/100
    box.maxHeight = desiredBounds.y + spreadability * desiredBounds.y/100

    # ELIMINATE (end-of-cycle-flush-drawdown): every caller is a CONSTRUCTOR, so @ is an ORPHAN here -- the
    # widget is just sized now and re-fit TOP-DOWN when it is later added to the world (a self-settling add
    # re-lays-out its subtree). So scheduling a re-layout DURING construction is WASTED work: it only rode the
    # per-frame end-of-cycle flush (~12 records -- the resize HandleWdgt sizing itself, plus the new-HandleWdgt
    # cell/button construction in the layout/resize tests). Skip it for the orphan. An ATTACHED caller (there is
    # none today, but the method is public) still schedules via _invalidateLayout, so the public contract holds.
    # The skip is SAFE specifically at THIS sizing-then-add seam -- NOT as a blanket _invalidateLayout
    # orphan-skip, which broke 63 tests because orphan invalidates are generally load-bearing (cf.
    # PanelWdgt._reactToChildRemoved). A disable-probe confirmed the orphan re-layout changes nothing (byte-identical).
    # (Writes the box's max pair inline rather than via _setMaxDimNoSettle, which would re-introduce the very
    # construction invalidate this skips; setMaxDim's own callers are unaffected.)
    @_invalidateLayout() unless @isOrphan()


  # CONVERT (end-of-cycle-flush-drawdown): setMaxDim is the public "set the max dimension" mutator, so it must
  # SELF-SETTLE (one flush per outermost public mutation) like every other public geometry setter. Its only
  # high-frequency caller -- the stack-divider drag (StackElementsSizeAdjustingWdgt.nonFloatDragging) -- and the
  # construction-time setMinAndMaxBoundsAndSpreadability call the NON-settling _setMaxDimNoSettle core instead, so
  # the drag-move STREAM still defers into the one end-of-cycle flush (a core rides the cycle by design; the
  # goal is deferred settling WITHOUT a PUBLIC method skipping its settle).
  setMaxDim: (overridingMaxDim) ->
    @_settleLayoutsAfter => @_setMaxDimNoSettle overridingMaxDim

  # PRIVATE DEFERRED-SETTLE entrypoint -- the first of the *DeferredSettle family. THIS is the family's canonical comment
  # -- the four geometry entrypoints (_setExtentDeferredSettle / _moveToDeferredSettle / _setWidthDeferredSettle /
  # _setHeightDeferredSettle) reference it. Same EFFECT as the private
  # _setMaxDimNoSettle core, but INTENTION-REVEALING: it DECLARES that this is an intentional per-event-stream
  # mutation (a drag / scroll / key burst) whose layout flush should ride the ONE end-of-cycle settle instead of
  # self-settling per call -- so a stream draining many mutations per frame collapses N flushes into 1. RESTRICTED
  # to those stream handlers, NOT for discrete/programmatic callers (which must use the self-settling setMaxDim so
  # their settled layout is available in-cycle); the restriction is enforced statically by check-layering rule [O]
  # (DEFERRED_SETTLE_CALLER_ALLOWLIST), which is also why the whole *DeferredSettle family is _-private. Because the deferred settling
  # is DECLARED here, the end-of-cycle audit can tell an intentional deferred-settle mutation from a public method that
  # carelessly forgot to self-settle. world.deferredSettlingEnabled is the A/B switch: ON (default) defers via the core;
  # OFF self-settles per call (like the plain setMaxDim), so we can MEASURE whether deferred settling is warranted for a
  # given stream (docs/tooling/coalescing-measurement.md -- e.g. key-repeat rarely bursts enough to matter). Default ON =>
  # byte-identical to calling the _NoSettle core directly. BOTH branches reach the _setMaxDimNoSettle core directly
  # -- a _-private entrypoint must not call the public setMaxDim (it would reach UP into the self-flushing layer;
  # rules [A]/[G]).
  _setMaxDimDeferredSettle: (overridingMaxDim) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setMaxDimNoSettle overridingMaxDim
    else
      @_settleLayoutsAfter => @_setMaxDimNoSettle overridingMaxDim

  # Run a deferred-settle-mutation core inside a DECLARATION window: while it runs, world._deferredSettleDeclarationDepth
  # is > 0, so the off-settle invalidates the core schedules are marked INTENTIONAL and the end-of-cycle debug
  # check (WorldWdgt.auditUndeclaredEndOfCycle) does NOT flag them as "careless". Every *DeferredSettle entrypoint
  # wraps its core through here. Nestable; returns the core's value. (Default-off audit => ~zero overhead.)
  _deferredSettleDeclare: (coreThunk) ->
    return coreThunk() unless world?
    world._deferredSettleDeclarationDepth += 1
    try
      return coreThunk()
    finally
      world._deferredSettleDeclarationDepth -= 1

  _setMaxDimNoSettle: (overridingMaxDim) ->
    # (a proportional rescale of the division-stack children was once sketched
    # here — see git history — but never enabled)
    box = @_ensureDivisionBox()
    box.maxWidth = overridingMaxDim.x
    box.maxHeight = overridingMaxDim.y

    @_invalidateLayout()

  # These bind the container's minimum to the sum of its contents' minimums. (A
  # discarded alternative — see git history — read the plain @desired*/@min* fields
  # instead, NOT binding a container's minimum to its contents, for maximum resize
  # flexibility.)
  getDesiredDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    @getRecursiveDesiredDim()
  getMinDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    @getRecursiveMinDim()
  getMaxDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    box = @_divisionBoxOrDefaults()
    maxDim = new Point box.maxWidth, box.maxHeight
    return maxDim.max @getDesiredDim()


  # ONE recursive walker for the three min/desired/max queries below. They differ only
  # in WHICH per-child query recurses and WHICH own-box pair backstops a widget with no
  # division children (plus the desired/min clamp, applied by the wrappers below).
  # The children's DIVISION AXIS is SUMMED and the cross axis takes the MAX — an 'x' row
  # sums widths / maxes heights, a 'y' division stack sums heights / maxes widths.
  _getRecursiveStackDim: (childQueryName, ownWidth, ownHeight) ->
    axis = @_divisionChildrenAxis() ? 'x'
    horizontal = axis == 'x'
    sumDim = 0
    maxDim = 0
    gotASum = false
    gotAMax = false
    for C in @children
      if C.layoutSpec?.isDivisionElement?()
        childSize = C[childQueryName]()
        gotASum = true
        sumDim += if horizontal then childSize.width() else childSize.height()
        childCross = if horizontal then childSize.height() else childSize.width()
        if maxDim < childCross
          gotAMax = true
          maxDim = childCross
    if horizontal
      width = if gotASum then sumDim else ownWidth
      height = if gotAMax then maxDim else ownHeight
    else
      height = if gotASum then sumDim else ownHeight
      width = if gotAMax then maxDim else ownWidth
    new Point width, height

  getRecursiveDesiredDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    box = @_divisionBoxOrDefaults()
    (@_getRecursiveStackDim "getDesiredDim", box.desiredWidth, box.desiredHeight).min @getRecursiveMaxDim()

  getRecursiveMinDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    # the user might have forced the "desired" to be smaller than the widget's standard minimum
    box = @_divisionBoxOrDefaults()
    (@_getRecursiveStackDim "getMinDim", box.minWidth, box.minHeight).min @getRecursiveMaxDim()

  getRecursiveMaxDim: ->
    if @isInCollapsedSubtree() then return new Point 0,0
    box = @_divisionBoxOrDefaults()
    @_getRecursiveStackDim "getMaxDim", box.maxWidth, box.maxHeight

  # WHICH axis my division children divide — undefined when I have none (the base _reLayout's
  # dispatch predicate). Mixed axes under one parent are a configuration error: the first
  # child's axis wins, loudly, and the layout stays deterministic.
  _divisionChildrenAxis: ->
    if @isInCollapsedSubtree() then return undefined
    axis = undefined
    for C in @children
      if C.layoutSpec?.isDivisionElement?() and
      !C.isInCollapsedSubtree()
        childAxis = C.layoutSpec.axis
        axis ?= childAxis
        if childAxis != axis
          console.error "mixed division axes under one container (" + @constructor?.name + ") — first child's axis '" + axis + "' wins"
    return axis

  # it's useful to know when a widget defers its layout
  # because it means that its current size is indicative
  # (particularly the children's sizes and position)
  implementsDeferredLayout: ->
    @_reLayout != Widget::_reLayout

  __calculateNewBoundsWhenDoingLayout: (newBoundsForThisLayout) ->
    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = undefined
      else
        newBoundsForThisLayout = @extent()

      # stuff that is being floatDragged ignores any @desiredPosition,
      # the relationship between the Active Pointer and its "dragged" widgets
      # is not quite a layout relationship
      if !@isBeingFloatDragged() and @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = undefined
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    return newBoundsForThisLayout

  _handleCollapsedStateShouldWeReturn: ->
    if @isInCollapsedSubtree()
      @_markLayoutAsFixed()
      return true
    return false

  _markLayoutAsFixed: ->
    @layoutIsValid = true

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # freefloating layouts never need
    # adjusting. We marked the @layoutIsValid
    # to false because it's an important breadcrumb
    # for finding the widgets that actually have a
    # layout to be recalculated but this Widget
    # now needs to do nothing.

    # the _applyMoveTo makes sure that all children
    # that are float-attached move together with the
    # widget.
    @_applyMoveTo newBoundsForThisLayout.origin
    
    # bad kludge here but I think there will be more
    # of these as we move over to the new layouts, we'll
    # probably have split Widgets for the new layouts mechanism.
    # FIT_BOX_TO_TEXT content re-sizes its OWN height to its text, so hand it the
    # full bounds (origin + extent) in one shot; everything else just takes the
    # new extent (its origin was already set by the _applyMoveTo above). ANY
    # contained TextWdgt qualifies (a non-text widget has no fittingSpec, so it
    # falls through to the else).
    if @fittingSpec == FittingSpecText.FIT_BOX_TO_TEXT
      @_applyGrantedBounds newBoundsForThisLayout
    else
      @_applyExtent newBoundsForThisLayout.extent()

    if @layoutSpec?.isCornerInternal?()
      if @parent
        spec = @layoutSpec
        if spec.proportionOfParent == 0 and spec.fixedSize == 0
          # a spec that declares NO size (both terms zero) does not size its carrier: the
          # anchor formulas place me by my OWN per-axis extent instead (the desktop
          # furniture -- bin opener / clock -- whose extent is their own business, and
          # need not be square).
          wDim = @width()
          hDim = @height()
        else
          xDim = @parent.width()
          yDim = @parent.height()
          # Integer placement (Layer A): minDim is a proportional (fractional) size used for BOTH this widget's
          # extent AND its right/bottom-anchored position below (parent.right() - minDim); round it once so both
          # commit integer @bounds. docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
          minDim = Math.round Math.min(xDim, yDim) * spec.proportionOfParent + spec.fixedSize
          @__commitExtent new Point minDim, minDim
          wDim = hDim = minDim

        inset = spec.inset

        if spec.anchor == 'topLeft'
          @_applyMoveTo new Point @parent.left() + inset.x, @parent.top() + inset.y
        else if spec.anchor == 'topRight'
          @_applyMoveTo new Point @parent.right() - wDim - inset.x, @parent.top() + inset.y
        else if spec.anchor == 'bottomRight'
          @_applyMoveTo new Point @parent.right() - wDim - inset.x, @parent.bottom() - hDim - inset.y
        else if spec.anchor == 'rightMiddle'
          @_applyMoveTo new Point @parent.right() - wDim - inset.x, Math.floor(@parent.top() + (@parent.extent().y - hDim)/2)
        else if spec.anchor == 'bottomMiddle'
          @_applyMoveTo new Point Math.floor(@parent.left() + (@parent.extent().x - wDim)/2), @parent.bottom() - hDim - inset.y

    else if (divisionAxis = @_divisionChildrenAxis())?
      # my division children jointly divide my main axis — the three-regime solve + the
      # placement loop live in StackLayoutEngine ('x' = a row dividing my width, 'y' = a
      # vertical division stack dividing my height)
      StackLayoutEngine.arrange @, newBoundsForThisLayout, divisionAxis

    @_markLayoutAsFixed()

    # if I just did my layout, also do the layout
    # of all children that have position/size depending on mine
    @_reLayoutCornerInternalChildren()

  # The house shape for a widget that lays out its OWN CONTENTS -- a fixed internal arrangement it
  # builds and places itself (a prompt's field + buttons, an icon's art, a plot's axes) -- as opposed
  # to a CONTAINER, which lays out whatever children it is given and instead overrides
  # _reLayoutChildren and keeps the `super` + `@_reLayoutChildren()` shape.
  #
  # Override _layOutOwnContents, never this. The ORDER here is the whole point and is why the shape
  # is worth having in one place at all:
  #   - the granted frame is applied FIRST, so the contents pass reads @width()/@height()/@topLeft()
  #     at the NEW frame rather than the previous pass's (children lagging one layout cadence on a
  #     resize was a real dpr2 flake -- buildSystem/check-relayout-bounds-first.js is the gate);
  #   - the contents pass runs as ONE damage unit, so N child rects collapse to my one box;
  #   - the base pass runs AFTER the contents, because its trailing corner-internal placement and its
  #     own _applyMoveTo/_applyExtent must see the finished arrangement. Moving the hook one line
  #     either way changes the frame the children see.
  # Widget::_reLayout is reached explicitly rather than through `super` because this method IS on
  # Widget: `@_reLayout` would dispatch straight back to the caller's own override. (The same
  # explicit form LabelButtonWdgt already uses to skip its parent's override.)
  #
  # NOTE the overriders keep a two-line `_reLayout` that delegates here rather than dropping the
  # override: `implementsDeferredLayout` is literally `@_reLayout != Widget::_reLayout`, and four
  # call sites read it to decide whether a widget settles itself.
  #
  # There is deliberately NO trailing @_markLayoutAsFixed() -- the base pass above already marks, and
  # its own tail (_reLayoutCornerInternalChildren) does not re-invalidate the widget it was called on.
  # All sixteen copies of this shape carried that extra mark; it was measured redundant when they were
  # folded together (suite green AND the settle re-visit profile still empty -- no added iterations).
  _reLayoutWithOwnContents: (newBoundsForThisLayout) ->
    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
    if @_handleCollapsedStateShouldWeReturn() then return
    @_applyGrantedBounds newBoundsForThisLayout
    @_repaintAsOneUnit => @_layOutOwnContents()
    Widget::_reLayout.call @, newBoundsForThisLayout

  # Place my own contents against my CURRENT frame (already committed by the caller above, so
  # @width()/@height()/@topLeft() read the frame this layout grants me). A widget with no contents
  # of its own places nothing.
  _layOutOwnContents: ->

  # Re-place my corner/edge-internal children (the handle overlays) against my CURRENT frame --
  # they live-read my bounds. Base _reLayout's tail (above) runs this after the main placement;
  # an arrange that re-commits its OWN frame AFTER that tail (the vertical stack's tight-hug,
  # which runs in the stack's _reLayout tail after super) must run it AGAIN at the final frame,
  # else the overlays sit placed for the pre-hug frame (schedule-valve arc V3, 2026-07-16: the
  # retired synchronous hook masked exactly this by running the arrange inside super's own
  # self-extent-apply, so the hug landed BEFORE this loop). Idempotent when the frame is stable.
  _reLayoutCornerInternalChildren: ->
    allCornerLayoutedChildren = @children.filter (m) -> m.layoutSpec?.isCornerInternal?()
    for w in allCornerLayoutedChildren
      w._reLayout()
    return


  # The layout-editing chrome (the spacers and the adder/droplet placeholders the three methods
  # below insert) lives in the LAZY 'authoring' part: a profile may omit it entirely (lean),
  # and even a shipping profile has not necessarily LOADED it when a division arrange runs.
  # Each method that NAMES the class therefore carries its own existence guard, so absent --
  # or not yet arrived -- is a no-op rather than a ReferenceError; the one USER entry point
  # (editLayout below) instead awaits ensureLoaded, because a guard there would swallow the
  # click. Deliberately not relying on "my callers are all part-side": a caller's guard is not
  # a property of the callee, and the next caller will not know to repeat it.
  # buildSystem/check-part-edges.js is what insists, and it has no allowlist on purpose.
  # canonical public wrapper / _NoSettle-core split (rule [H]: all logic in the core)
  removeAdders: ->
    @_settleLayoutsAfter => @_removeAddersNoSettle()

  _removeAddersNoSettle: ->
    @_showsAdders = false
    @_invalidateLayout()

  # PRODUCT entry for the layout scaffold ("edit layout" in a division container's context
  # menu): fetch the LAZY authoring part that carries the adder/droplet chrome, THEN show
  # the drop-slots. An existence guard here would silently swallow the click — inclusion
  # guards are for the arranges, ensureLoaded is for user entry points.
  # ⚠ The destroyed-check is the door-callback law (PartsRegistry's header): the wait is
  # exactly when I can die (close/destroy while the part is in flight), and showAdders on a
  # corpse silently BUILDS chrome on it — an escaped widget no destroy cascade can reach,
  # pinning the corpse (measured: docs/archive/world-vm-truth-riders-plan.md §5 S3).
  editLayout: ->
    world.parts.ensureLoaded('authoring').then =>
      return if @destroyed
      @showAdders(@_divisionChildrenAxis() ? 'x')

  # canonical public wrapper / _NoSettle-core split (rule [H]: all logic in the core) —
  # like removeAdders below; a menu-driven discrete mutation must self-settle, not ride
  # the end-of-cycle flush (the capstone gate holds the careless set at zero)
  showAdders: (axis = 'x') ->
    @_settleLayoutsAfter => @_showAddersNoSettle axis

  _showAddersNoSettle: (axis = 'x') ->
    return unless LayoutElementAdderOrDropletWdgt?
    @_showsAdders = true
    # the seed adder of an EMPTY container joins the DIVISION layout it starts; a content
    # stack instead seeds through its own reconciler (the arrange runs it regardless of
    # division children, so the empty case needs no help here)
    if @children.length == 0 and !@hostsContentStackDropSlots?()
      newAdder = new LayoutElementAdderOrDropletWdgt
      newAdder._divisionBox.axis = axis
      @_addNoSettle newAdder, layoutSpec: newAdder._divisionBox
    @_invalidateLayout()

  _addOrRemoveAdders: (axis = 'x') ->
    return unless LayoutElementAdderOrDropletWdgt?

    if !@_showsAdders
      # DIRECT children only: an adder is always a direct child of the container whose
      # layout it edits, and a nested container's adders are its OWN toggle's business —
      # a deep sweep here would destroy a nested content stack's slots on every
      # not-showing division arrange.
      allAddersToBeDestroyed = @children.filter (m) -> m.isLayoutAdderOrDroplet?()
      for C in allAddersToBeDestroyed
        # non-settling core: this runs from inside the arrange (a layout pass) — the public
        # self-settling fullDestroy would re-enter the flush (rule [G]). Detach the spec
        # FIRST (non-scheduling): the teardown's parent-invalidate is the sanctioned silent
        # no-op for a free-floating child, but would be a mid-pass FLOWRULE throw for a
        # spec-carrying one — the mirror of the spec-less insert in _insertAddersSuchThat.
        C._setLayoutSpec undefined
        C._fullDestroyNoSettle()
      return

    if @children.length == 0
      @_addNoSettle new LayoutElementAdderOrDropletWdgt

    @_insertAddersSuchThat "lastSiblingBeforeMeSuchThat", "addAsSiblingBeforeMe", axis: axis
    # the second call scans the OTHER direction -- only needed to add the LAST adder/droplet.
    @_insertAddersSuchThat "firstSiblingAfterMeSuchThat", "addAsSiblingAfterMe", axis: axis

  # ONE direction-parameterized scan for the two reconciler passes (was two ~20-line while-loops
  # identical bar the scan/insert verbs): repeatedly find the first stack child still needing an adder on
  # the given side (skipping adders/droplets themselves) and insert one there, until none remain.
  # TWO flavours share it, and they want DISJOINT tails — which is why the knobs ride an options
  # bag (R3) rather than two positional slots: the DIVISION reconciler (_addOrRemoveAdders — member
  # = division element, adders join the division on the given `axis`, default membership) and the
  # content-stack reconciler (VerticalStackPanelWdgt._reconcileContentDropSlots — its own
  # `isMember` predicate, and no axis at all, so the adder stays spec-less for the stack's arrange
  # to adopt). ⚠ NO default for the axis: its ABSENCE is meaningful (content mode).
  #
  # BOTH flavours run MID-PASS (from inside the container's own arrange), so the insert must not
  # schedule layout: the adder is added SPEC-LESS — a free-floating child's add-invalidate is the
  # sanctioned silent no-op — and the division attachment is then ACTIVATED via the non-scheduling
  # _setLayoutSpec, exactly the stack-adoption idiom. (Passing the box as the add's layoutSpec made
  # Widget._addNoSettle's new-container invalidate reach a NON-freefloating child mid-pass ⇒ the
  # FLOWRULE throw — latent in the division flavour until the first edit-layout-driving test.)
  _insertAddersSuchThat: (scanVerbName, insertVerbName, opts = {}) ->
    return unless LayoutElementAdderOrDropletWdgt?
    axis = opts.axis
    isMember = opts.isMember
    isMember ?= (m) -> m.layoutSpec?.isDivisionElement?()
    while true
      leftToDo = @firstChildSuchThat (m) ->
          if !isMember m
            return false
          if m.isLayoutAdderOrDroplet?()
            return false
          kkk = m[scanVerbName](
              (mm) ->
                isMember mm
            )
          if !kkk?
            return true
          if kkk.isLayoutAdderOrDroplet?()
            return false
          return true
      if !leftToDo?
        break
      newAdder = new LayoutElementAdderOrDropletWdgt
      leftToDo[insertVerbName] newAdder
      if axis?
        newAdder._divisionBox.axis = axis
        newAdder._setLayoutSpec newAdder._divisionBox
