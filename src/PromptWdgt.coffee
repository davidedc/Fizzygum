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
  #feedback: nil
  #choice: nil
  #colorPalette: nil
  #grayPalette: nil

  target: nil
  msg: nil
  callback: nil
  defaultContents: nil
  intendedWidth: nil
  # (the rowsPanel field — my whole visible body — is declared on PopUpWdgt,
  # shared with MenuWdgt, along with the lay-and-hug + membership absorber.)
  # this pop-up's title bar: the MenuHeader the rows-panel builds from @msg,
  # surfaced here so `prompt.label` reaches it the same way `menu.label` reaches a
  # menu's header (the drag/pin-by-header idiom the menu tests share). Storage
  # lives on the panel; this is the same instance, so `.center()` tracks it live.
  label: nil
  # the value editor for the text-bearing prompts (Text / Number / SaveShortcut);
  # kept under this conventional name because Widget.prompt and the macro tests
  # reach it as `<prompt>.tempPromptEntryField`.
  tempPromptEntryField: nil

  # A prompt is a menu-family pop-up: it answers isMenu? like a MenuWdgt does, so
  # the three isMenu? sites (ActivePointerWdgt's click-outside menu dismissal,
  # Wallpaper / StringWdgt tick refresh) treat it exactly as the old
  # `PromptWdgt extends MenuWdgt` did.
  isMenu: ->
    true

  # Like MenuWdgt, I draw NOTHING myself -- my rowsPanel draws the box -- so I am
  # transparent EVERYWHERE and hit-testing must fall THROUGH me to my panel (and, at my
  # transparent rounded corners / padding, on through to whatever is behind me). Without
  # this the base answers OPAQUE (the explicit appearance-less default -- most
  # appearance-less widgets are hit-targets, see Widget.isTransparentAt; container-
  # regularization §5.6 proved flipping the DEFAULT instead regresses ~70 tests, so
  # transparency stays a per-class override). Owner-accepted the one visible consequence
  # (a resting pointer over a prompt corner now hover-highlights the widget behind,
  # e.g. macroSaveAsPromptAboveTiltedWindow's close button -- consciously recaptured
  # 2026-07-19).
  isTransparentAt: (aPoint) ->
    true

  colloquialName: ->
    if @msg then "\"" + @msg + "\" prompt" else "prompt"

  constructor: (widgetOpeningThePopUp, @msg, @target, @callback, @defaultContents, @intendedWidth) ->
    super widgetOpeningThePopUp
    @onClickOutsideMeOrAnyOfMyChildren "close"
    # NOTE: subclasses call @_buildAndConnectChildren() from their OWN constructor,
    # after super() has bound their extra params (e.g. NumberPromptWdgt's ceiling):
    # CoffeeScript binds a subclass's ctor params only AFTER super(), so building
    # here would dispatch into the subclass editor hook too early (same reason
    # MenuWdgt keeps its label build out of a virtual _buildAndConnectChildren).

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
    @rowsPanel.__commitMoveTo @position()
    @rowsPanel._reLayoutChildren()   # §5.2e: the rows-panel is now a stack; its re-fit chokepoint lays the rows out + self-sizes
    @_addNoSettle @rowsPanel
    @_applyExtent @rowsPanel.extent()
    # surface the panel's title header as my own .label (the drag/pin-by-header handle).
    @label = @rowsPanel.label

  # Subclass hook: build the type-specific editor and add it to the panel. The
  # editor also becomes the panel's `environment` (the button rows resolve their
  # widgetEnv from it, mirroring the old MenuWdgt environment-slot arg).
  _buildAndAddValueEditorInto: (panel) ->

  # The everyday button row: a divider then "Ok" (fires the caller's callback on
  # the target) and "Close" (dismisses this prompt). SaveShortcutPromptWdgt
  # overrides with its own three buttons and no leading divider.
  _addButtonsInto: (panel) ->
    panel.addLine 2
    panel.addMenuItem "Ok", @target, @callback
    # we name the button "Close" instead of "Cancel" because we are not undoing
    # any change we made -- that would be difficult with multiple prompts pinned
    # down and changing the property concurrently.
    panel.addMenuItem "Close", @, "close"

  # Deliberately EMPTY: suppresses the base Widget._reactToBeingAdded -> @_reLayoutSelf
  # add-time self-heal. A prompt's body is laid ONCE at build
  # (_buildAndConnectChildrenNoSettle lays the panel and hugs it BEFORE popUp adds me),
  # and the panel is free-floating so it co-moves on any later re-parenting (a pinned
  # prompt dropped into a panel) -- nothing needs re-laying at add time. Contrast
  # MenuWdgt, whose FIRST layout is deliberately driven from its _reactToBeingAdded.
  _reactToBeingAdded: (whereTo, beingDropped) ->
