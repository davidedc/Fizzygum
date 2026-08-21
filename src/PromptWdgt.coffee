# A prompt is a pop-up that asks for one value and reports it back via a callback.
# It shares the MENU BEHAVIOUR (transient, closes on click-outside, pinnable,
# shadowed) through PopUpWdgt — it is NOT a MenuWdgt — and it borrows the menu
# LOOK/LAYOUT by composing a titled MenuRowsPanelWdgt (the message as its title,
# then the value editor, a divider, and the "Ok"/"Close" rows). The pop-up wraps
# that single panel and hugs its size.
#
# Per-value-type subclasses fill in only the editor row:
#   TextPromptWdgt   — a StringFieldWdgt.
#   NumberPromptWdgt — a numeric StringFieldWdgt + a SliderWdgt.
#   ColorPromptWdgt  — a ColorPickerWdgt (the folded Widget.pickColor).
# SaveShortcutPromptWdgt re-bases here too, swapping the button row.

class PromptWdgt extends PopUpWdgt

  # pattern: children declared here so a duplicate has the handles to remap
  # (whether they are set in the constructor or lazily).
  target: undefined
  msg: undefined
  callback: undefined
  defaultContents: undefined
  intendedWidth: undefined
  # (the rowsPanel field — my whole visible body — is declared on PopUpWdgt,
  # shared with MenuWdgt, along with the lay-and-hug + membership absorber.)
  # this pop-up's title bar: the MenuHeader the rows-panel builds from @msg,
  # surfaced here so `prompt.label` reaches it the same way `menu.label` reaches a
  # menu's header (the drag/pin-by-header idiom the menu tests share). Storage
  # lives on the panel; this is the same instance, so `.center()` tracks it live.
  label: undefined
  # the value editor for the text-bearing prompts (Text / Number / SaveShortcut);
  # kept under this conventional name because Widget.prompt and the macro tests
  # reach it as `<prompt>.tempPromptEntryField`.
  tempPromptEntryField: undefined

  # A prompt is a menu-family pop-up: it answers isMenu? like a MenuWdgt does, so
  # the three isMenu? sites (ActivePointerWdgt's click-outside menu dismissal,
  # Wallpaper / StringWdgt tick refresh) treat it exactly as the old
  # `PromptWdgt extends MenuWdgt` did.
  isMenu: ->
    true

  # Like MenuWdgt, I present NO SURFACE OF MY OWN -- my rowsPanel draws the box -- so the pointer
  # falls THROUGH me to my panel (and, at my empty rounded corners / padding, on through to
  # whatever is behind me). Without this the base claims my whole box (the appearance-less
  # default -- most appearance-less widgets ARE hit targets, see Widget.catchesPointerAt). This
  # stays a per-class statement, with the owner-accepted consequence that a resting pointer over
  # a prompt corner hover-highlights the widget behind (e.g. macroSaveAsPromptAboveTiltedWindow's
  # close button). Why the base DEFAULT was not flipped instead:
  # docs/archive/container-regularization-plan.md §5.6.
  catchesPointerAt: (aPoint) ->
    false

  colloquialName: ->
    if @msg then "\"" + @msg + "\" prompt" else "prompt"

  # Only widgetOpeningThePopUp and target are OPERANDS: they are the two every
  # member supplies. msg and callback ride opts because SaveShortcutPromptWdgt
  # supplies neither (its msg is the class-level constant above its head, and it
  # has no callback at all) — as positionals they would force it to punch two
  # `undefined`s through to reach opts, which is exactly the hole R3 forbids
  # (docs/architecture/constructor-and-parameter-conventions.md).
  constructor: (widgetOpeningThePopUp, target, opts = {}) ->
    # msg is read GUARDED: absence must leave a subclass's class-level default
    # standing (SaveShortcutPromptWdgt's " save as... "), which a bare assignment
    # would overwrite with undefined. The rest have no prototype default to keep.
    @msg = opts.msg if opts.msg?
    @target = target
    @callback = opts.callback
    @defaultContents = opts.defaultContents
    @intendedWidth = opts.intendedWidth
    super widgetOpeningThePopUp
    @onClickOutsideMeOrAnyOfMyChildren "close"
    # NOTE: subclasses call @_buildAndConnectChildren() from their OWN constructor,
    # so that a subclass's extra options (e.g. NumberPromptWdgt's ceiling) are read
    # before the editor hook runs — building here would dispatch into the subclass
    # hook while those fields are still unset (same reason MenuRowsPanelWdgt keeps
    # its label build out of a virtual _buildAndConnectChildren).

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @rowsPanel = new MenuRowsPanelWdgt target: @target, title: (@msg or "")
    @_buildAndAddValueEditorInto @rowsPanel
    @_addButtonsInto @rowsPanel
    # lay the panel out at my origin, then hug it — the down-walk settles parent
    # before child, so I size to the panel's freshly-laid-out extent HERE (as
    # ListWdgt lays out its listContents at build) rather than reading it mid-pass.
    # The rows go into the shared rows viewport, ALWAYS (PopUpWdgt
    # ._buildRowsViewportNoSettle), so a prompt too tall for the world scrolls
    # rather than running off the bottom edge, exactly like a menu.
    @_buildRowsViewportNoSettle()
    @rowsPanel._reLayoutChildren()   # §5.2e: the rows-panel is now a stack; its re-fit chokepoint lays the rows out + self-sizes
    @_refitRowsViewportNoSettle()
    @_applyExtent @rowsViewport.extent()
    # surface the panel's title header as my own .label (the drag/pin-by-header handle).
    @label = @rowsPanel.label

  # Subclass hook: build the type-specific editor and add it to the panel.
  _buildAndAddValueEditorInto: (panel) ->

  # The shared core of the text-bearing editors (Text / Number): build the
  # StringFieldWdgt entry field, surface it under the conventional
  # @tempPromptEntryField name (see its declaration above), and add it to the
  # panel. isNumericField flips the field's numeric mode — NumberPromptWdgt
  # passes whether a ceiling exists.
  _buildAndAddEntryFieldInto: (panel, isNumericField) ->
    @tempPromptEntryField = new StringFieldWdgt (@defaultContents or ""),
      minTextWidth: @intendedWidth or 100
      fontSize: WorldWdgt.preferencesAndSettings.prompterFontSize
      fontStyle: WorldWdgt.preferencesAndSettings.prompterFontName
      isNumeric: isNumericField
    panel._addNoSettle @tempPromptEntryField
    # _addNoSettle skips the child's calculateAndUpdateExtent (which measures the
    # text and applies width >= minTextWidth, feeding the panel's width via
    # menuEntryPreferredWidth); run it explicitly.
    @tempPromptEntryField.calculateAndUpdateExtent()

  # The everyday button row: a divider then "Ok" (delivers the composed value to
  # the caller's callback, via deliverValue below) and "Close" (dismisses this
  # prompt). SaveShortcutPromptWdgt overrides with its own three buttons and no
  # leading divider.
  _addButtonsInto: (panel) ->
    panel.addLine 2
    panel.addMenuItem "Ok", @, "deliverValue"
    # we name the button "Close" instead of "Cancel" because we are not undoing
    # any change we made -- that would be difficult with multiple prompts pinned
    # down and changing the property concurrently.
    panel.addMenuItem "Close", @, "close"

  # The Ok adapter: a prompt delivers ONE argument — the value composed in its
  # editor — to the caller's callback verb on the target, the same one-value
  # convention a wire delivers by (`consumer[action] value`). Delivery is the
  # whole job: closing belongs to the pop-up teardown (an unpinned prompt dies on
  # the click; a pinned one stays and can deliver again).
  deliverValue: ->
    @target[@callback].call @target, @_promptValue()

  # What my editor currently holds. The text-bearing prompts deliver the field's
  # string (value-consuming setters parse/clamp their own property's type);
  # ColorPromptWdgt overrides to deliver the picker's Color.
  _promptValue: ->
    @tempPromptEntryField.getValue()

  # Deliberately EMPTY: suppresses the base Widget._reactToBeingAdded -> @_reLayoutSelf
  # add-time self-heal. A prompt's body is laid ONCE at build
  # (_buildAndConnectChildrenNoSettle lays the panel and hugs it BEFORE popUp adds me),
  # and the panel is free-floating so it co-moves on any later re-parenting (a pinned
  # prompt dropped into a panel) -- nothing needs re-laying at add time. Contrast
  # MenuWdgt, whose FIRST layout is deliberately driven from its _reactToBeingAdded.
  _reactToBeingAdded: (whereTo, beingDropped) ->
