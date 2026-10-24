# A flat, label-bearing button: a box in its rest fill with a single text label drawn on top,
# which shows its STATE -- hovered, pressed -- in a state fill of its own: over the whole box,
# square, or, when it carries a plateRadius, as a rounded PLATE on its rest fill
# (LabelButtonAppearance). Every one of those is its builder's to give: MenuItemWdgt gives the
# menu-row or the list-row look its context asks for, and MemberRowWdgt its own. A label button
# whose look is its own instead gives none, and answers its appearance (createAppearance) and its
# label's font and ink (_labelTextOptions) itself: MagnetWdgt, a Fizzytiles word tile in the
# button's look. It extends the modern button family (ButtonWdgt), inheriting the
# target/action/trigger machinery and the HighlightableMixin state constants, but supplies its OWN
# flat paint -- the button family draws no flat fill (ButtonWdgt is transparent, SimpleButtonWdgt
# is a rounded box).
#
# This is the shared base of MenuItemWdgt (menu and list rows) and MagnetWdgt
# (fizzytiles word tiles).

class LabelButtonWdgt extends ButtonWdgt

  # label fields (the button family carries a faceWidget instead; a label button
  # draws its own @label)
  label: undefined
  labelString: undefined
  labelColor: undefined
  labelBold: undefined
  labelItalic: undefined
  fontSize: undefined
  fontStyle: undefined

  # the state fills: while I am hovered, and while I am pressed (a selected list row wears the
  # hovered one -- its list's selection is its highlighted state). My rest fill is my @color.
  highlightColor: undefined
  pressColor: undefined
  # how my state fill is shaped: undefined fills my whole box, square; a radius paints it as a
  # PLATE of that rounding over my box, on my rest fill (a menu row's hover and press) -- as tall as
  # my box, or plateHeight tall from my top when I carry one (a member row's selection plate, my rest
  # fill showing under it).
  plateRadius: undefined
  plateHeight: undefined
  centered: false

  # Same head as ButtonWdgt — target/action — and the same opts object, extended with the
  # label knobs this class adds. It forwards `opts` untouched rather than transcribing it,
  # which is what makes the two vocabularies ONE vocabulary: an option added to ButtonWdgt is
  # available here with no edit.
  #
  # It passes no `face`: a label button draws its own @label. An absent `face` and an
  # explicitly-undefined one are the same thing to ButtonWdgt, so there is nothing to say.
  #
  # ⚠ ONE field, ONE name: ButtonWdgt's `subjectOfAction` rides the `subject` option here too.
  # A second alias for it is exactly what an options vocabulary cannot afford (R4), because a
  # forwarded bag would then carry a key the receiver never reads.
  #
  # My label's font is a ROLE, as StringWdgt's is: `fontRole` gives its family, size and weight,
  # and an explicit fontStyle / fontSize / bold overrides that member. The role is resolved into my
  # three label fields here and not kept.
  #   My LOOK rides the same opts: `color` is my label's ink, `fill` my rest fill, `highlightFill`
  # and `pressFill` my two state fills, `plateRadius` the rounding of the plate they are painted as
  # (absent: they cover my whole box, square) and `plateHeight` how tall that plate is from my top
  # (absent: my whole height).
  # Every value given lands in a field of mine, so I keep the look I was built with wherever I go.
  # One not given stays unset, so I hold no colour or font of my own for it: a label button whose
  # look is its own reads it from the theme as it paints and as it builds its label (MagnetWdgt),
  # and a bare one has no fill and its label the default text role (StringWdgt's).
  constructor: (target, action, opts = {}) ->
    super target, action, opts

    @labelString = opts.labelString
    fontRole = opts.fontRole
    @fontSize = opts.fontSize ? fontRole?.size
    @fontStyle = opts.fontStyle ? fontRole?.family
    @centered = opts.centered ? false
    @labelColor = opts.color
    @labelBold = opts.bold ? fontRole?.bold
    @labelItalic = opts.italic ? false

    # the flat rest fill (in place of ButtonWdgt's white) and the state fills
    @color = opts.fill
    @highlightColor = opts.highlightFill
    @pressColor = opts.pressFill
    @plateRadius = opts.plateRadius if opts.plateRadius?
    @plateHeight = opts.plateHeight if opts.plateHeight?
    @appearance = @createAppearance()

    if @labelString?
      @_reLayoutSelf()

  # a method, not a class field, so the dependency finder sees the `new` edge; a label button with
  # a look of its own paints through its own (MagnetWdgt)
  createAppearance: -> new LabelButtonAppearance @

  # the default label: a self-sized single-line StringWdgt that does NOT resize
  # the button's box. Subclasses that size the box from the label (MenuItemWdgt, its height)
  # override this.
  #   Built at my TOP-LEFT, which is where a label that is not centred sits: a label built with me
  # at construction is born there (I am at the origin), and one built later -- a relabel, with me
  # anywhere -- must land on the same spot, since nothing else places it. A centred label is moved to
  # my centre by _reLayoutSelf. Placed BEFORE it is adopted, so the add damages the spot it will be
  # painted at.
  _createLabel: ->
    @label = new StringWdgt (@labelString or ""), @_labelTextOptions()
    @label.__commitMoveTo @position()
    # _addNoSettle (NOT add): _createLabel runs inside my arrange (_reLayoutSelf) or inside a relabel's
    # settle (_setLabelNoSettle), where a self-settle would re-enter the flush guard and throw.
    @_addNoSettle @label
    # the modern family does not self-size; make the label hug its text so
    # _reLayoutSelf's centring math (which reads @label.extent()) works. The hug ALONE
    # (StringWdgt._sizeToTextAndDisableFittingInMyParentsArrangeNoSettle), because my arrange is already
    # under way or already owed: run from my _reLayoutSelf, the core would schedule the very arrange that
    # is running, and from inside my _reLayout re-queue me for a second visit in this flush; run from a
    # relabel, _setLabelNoSettle schedules my arrange itself.
    @label._sizeToTextAndDisableFittingInMyParentsArrangeNoSettle()

  # The StringWdgt options my default label is built with: my font and my ink, as my fields hold
  # them. A label button whose look is its own answers its own, read from the theme each time its
  # label is built (MagnetWdgt).
  _labelTextOptions: ->
    fontSize: @fontSize
    fontName: @fontStyle
    bold: @labelBold
    italic: @labelItalic
    color: @labelColor

  _reLayoutSelf: ->
    if not @label?
      @_createLabel()
    if @centered
      # Integer placement (Layer A): @center() is fractional when my extent is odd, so round the centred
      # label position to commit an integer @bounds. docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
      @label._applyMoveTo (@center().subtract @label.extent().floorDivideBy 2).round()

  # a label button has no faceWidget; use the base Widget layout rather than
  # ButtonWdgt's faceWidget-centric override. Then re-run _reLayoutSelf so a
  # CENTERED button keeps its label centred through ANY layout/resize: the base
  # pass applies the new bounds, then _reLayoutSelf re-centres the label against
  # them (a no-op when not centered). This is why a caller resizing a centered
  # label button no longer needs an explicit re-centre.
  _reLayout: (newBoundsForThisLayout) ->
    Widget::_reLayout.call @, newBoundsForThisLayout
    @_reLayoutSelf()

  # THIN public wrapper over the non-settling core (canonical self-settling form): relabel, then
  # SELF-SETTLE (public tier, like setExtent/add) so my re-layout -- and my container's, when the new
  # label changes what it takes from me -- runs synchronously and the world is consistent on return. The
  # public label-setter API: a runtime label change settles. No product code calls it;
  # SystemTest_macroRelabelledLabelButtonsStayPlaced does, which is what check-dead-methods.js counts, and
  # without it the gate's settle-twin pairing rule would keep it (the _setLabelNoSettle core is live).
  setLabel: (labelString) ->
    @_settleLayoutsAfter => @_setLabelNoSettle labelString

  # NON-settling core of a RELABEL: my label is REBUILT AT ONCE -- the old one torn down
  # (_fullDestroyNoSettle) and the new one built and sized (_createLabel) -- so I am never label-less
  # while somebody reads me: a menu's rows panel measures every row's label as it lays itself out
  # (CommandPanelWdgt.maxWidthOfMenuEntries), and the walk lays the panel BEFORE the row. PLACING the label
  # stays my arrange's, which the climbing invalidate schedules -- it re-centres a centred label and places
  # a row's parts (MenuItemWdgt._placeMyParts); a label that is not centred is built in place
  # (_createLabel). Then I tell my container I was relabelled, for the one that sizes itself from its rows'
  # labels (CommandPanelWdgt._reactToChildRelabelled: a pop-up re-takes its size). The public wrapper -- or
  # the enclosing construction settle, for a button labelling its ORPHAN member before attach
  # (FridgeMagnetsWdgt's magnets) -- does the one flush.
  _setLabelNoSettle: (@labelString) ->
    @label = @label._fullDestroyNoSettle()  if @label?
    @_createLabel()
    @_invalidateLayout()
    @parent?._reactToChildRelabelled? @

  alignCenter: ->
    if !@centered
      @centered = true
      @_reLayoutSelf()

  alignLeft: ->
    if @centered
      @centered = false
      @_reLayoutSelf()

  # a copied label button usually wants to un-highlight itself (e.g. when you
  # duplicate by clicking a "duplicate" button INSIDE it). Running an input-protocol verb on
  # the MID-ASSEMBLY clone (an orphan — the hook fires before any attach) is deliberate and
  # safe: hoverExited is the ONE home of the un-hover behaviour (state reset + tooltip
  # teardown; a hand-copied body here would be a drift-prone twin), and its _changed()
  # no-ops honestly on an orphan — the Duplicator drops the copied cache pairs, so the clone
  # derives its own orphan root rather than answering the ORIGINAL's world.
  _reactToBeingCopied: ->
    # public-call-sanctioned: hoverExited is the public pointer-event PROTOCOL verb (dispatched by
    # ActivePointerWdgt); reused to reset the copy's hover state — renaming it is not an option.
    @hoverExited()

  hoverEntered: ->
    @state = @STATE_HIGHLIGHTED
    @_changed()
    @startCountdownForBubbleHelp @toolTipMessage  if @toolTipMessage

  hoverExited: ->
    @state = @STATE_NORMAL
    @_changed()
    world.destroyToolTips()  if @toolTipMessage

  # A press shows PRESSED, raises me, and goes on up: Widget.pressBegan's body inline rather than
  # through super, because ButtonWdgt's HighlightableMixin pressBegan would run _updateColor,
  # clobbering @color (our normal fill).
  pressBegan: (ignored_pos) ->
    @state = @STATE_PRESSED
    @_changed()
    @bringToForeground()
    true

  # MY TWO ENDINGS (ActivePointerWdgt, the press's AUDIENCE). The release leaves my state as the press
  # left it: a release that clicks me goes on to set it (activated -- HIGHLIGHTED, which is also how a
  # list row shows its list's selection), and HighlightableMixin's ending would write a state, and
  # repaint me through _updateColor (clobbering my normal fill), right under that click.
  pressEnded: ->

  # A cancelled press is followed by no click, so it is mine to undo: hovered if the pointer rests on
  # me, at rest otherwise.
  pressCancelled: ->
    @state = if world.hand.restsOn @ then @STATE_HIGHLIGHTED else @STATE_NORMAL
    @_changed()

  activated: ->
    @bringToForeground()
    @state = @STATE_HIGHLIGHTED
    @_changed()
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @trigger()
