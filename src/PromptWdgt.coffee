# A prompt is the FRAMED CITIZEN of the prompt kind: it asks for one value and reports it
# back via a callback. Like a menu (it is NOT a MenuWdgt) it wraps a rows payload — a
# MenuRowsPanelWdgt inside a PopUpRowsViewportWdgt, holding the value editor, a divider and
# the "Ok"/"Close" rows — and, like a menu, it is born TRANSIENT: it closes on a click
# outside it, and pinning it makes it furniture. The frame draws the box, the title strip
# (from @msg) and the shadow.
#
# Per-value-type subclasses fill in only the editor row:
#   TextPromptWdgt   — a StringFieldWdgt.
#   NumberPromptWdgt — a numeric StringFieldWdgt + a SliderWdgt.
#   ColorPromptWdgt  — a ColorPickerWdgt (the folded Widget.pickColor).
# SaveShortcutPromptWdgt re-bases here too, swapping the button row.

class PromptWdgt extends FrameWdgt

  # pattern: children declared here so a duplicate has the handles to remap
  # (whether they are set in the constructor or lazily).
  target: undefined
  msg: undefined
  callback: undefined
  # the value my editor OPENS with (the `defaultContents` option every prompt door takes).
  defaultValue: undefined
  intendedWidth: undefined
  # the MenuRowsPanelWdgt my rows live in, and the viewport that holds it — my @contents.
  rowsPanel: undefined
  rowsViewport: undefined
  # the value editor for the text-bearing prompts (Text / Number / SaveShortcut);
  # kept under this conventional name because Widget.prompt and the macro tests
  # reach it as `<prompt>.tempPromptEntryField`.
  tempPromptEntryField: undefined

  # A prompt is a menu-family pop-up: it answers isMenu? like a MenuWdgt does. The one isMenu?()
  # consumer is the hand's click-outside dismissal (ActivePointerWdgt.processMouseDown), so a
  # mouse-down landing inside a prompt counts as a click inside menu chrome and does NOT fire the
  # sweep that dismisses every menu, freshly created ones included.
  isMenu: ->
    true

  # I am a prompt only while I am mid-gesture UI. Pinned I am furniture, and I am named for what I
  # then am -- a window (program ruling C4). My MESSAGE is my title and it crosses that change of
  # kind: titled, I answer "<msg>" window, the symmetric twin of my transient "<msg>" prompt, in
  # both parentages (the window/card difference is what I LOOK like, never what I am called).
  # Untitled I have no name of my own to offer, so my frame's plain window / internal window stands.
  colloquialName: ->
    unless @isTransientPopUp()
      return super() unless @msg
      return "\"" + @msg + "\" window"
    if @msg then "\"" + @msg + "\" prompt" else "prompt"

  # the KIND names me: my message is my title, not my payload's colloquial name
  _titleForContents: (unused_aWdgt) ->
    @msg

  # Only widgetOpeningThePopUp and target are OPERANDS: they are the two every
  # member supplies. msg and callback ride opts because SaveShortcutPromptWdgt
  # supplies neither (its msg is the class-level constant above its head, and it
  # has no callback at all) — as positionals they would force it to punch two
  # `undefined`s through to reach opts, which is exactly the hole R3 forbids
  # (docs/architecture/constructor-and-parameter-conventions.md).
  #   The rows payload is built BEFORE super: it IS my frame's content operand, and the
  # message my strip titles itself from is mine to know first.
  constructor: (@widgetOpeningThePopUp, target, opts = {}) ->
    # msg is read GUARDED: absence must leave a subclass's class-level default
    # standing (SaveShortcutPromptWdgt's " save as... "), which a bare assignment
    # would overwrite with undefined. The rest have no prototype default to keep.
    @msg = opts.msg if opts.msg?
    @target = target
    @callback = opts.callback
    @defaultValue = opts.defaultContents
    @intendedWidth = opts.intendedWidth
    # a prompt is born mid-gesture UI, like a menu: the lifetime entry enrols me in the open set
    # and arms the click-outside dismissal that ends me.
    @_setLifetimeNoSettle 'transient'
    super @_buildRowsPayload()
    @rowsViewport = @contents
    @rowsPanel = @rowsViewport.contents
    @isLockingToPanels = false
    # freshlyCreatedPopUps is a fact about CONSTRUCTION: the hand skips a pop-up born under the
    # very click that is still being processed, and clears the set at mouse-up.
    world.freshlyCreatedPopUps.add @
    # NOTE: subclasses call @_buildPromptRows() from their OWN constructor,
    # so that a subclass's extra options (e.g. NumberPromptWdgt's ceiling) are read
    # before the editor hook runs — building here would dispatch into the subclass
    # hook while those fields are still unset (same reason MenuRowsPanelWdgt keeps
    # its label build out of a virtual _buildAndConnectChildren).

  # My payload: the empty rows panel inside the rows viewport, which is what bounds a prompt
  # to the world and scrolls whatever does not fit. The ROWS go in through _buildPromptRows.
  _buildRowsPayload: ->
    panel = new MenuRowsPanelWdgt target: @target
    # dragging a prompt by its title must move the PROMPT, and a child of a panel detaches
    # instead unless it locks to panels.
    panel.isLockingToPanels = true
    # the panel is TRANSPARENT chrome: my own box is the prompt box (FrameWdgt
    # ._deriveAndSetBodyAppearance paints it), and a second box inside it would double the
    # stroke. Its shape still takes its own clicks — alpha is about painting, never hit-testing.
    panel.alpha = 0
    new PopUpRowsViewportWdgt panel

  # Compose my rows via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()`
  # returns settled). Distinct from the frame's own chrome build (_buildAndConnectChildren), which
  # my constructor has already run: these are my PAYLOAD's rows, and only a concrete subclass
  # knows what the editor row is.
  _buildPromptRows: ->
    @_settleLayoutsAfter => @_buildPromptRowsNoSettle()

  _buildPromptRowsNoSettle: ->
    @_buildAndAddValueEditorInto @rowsPanel
    @_addButtonsInto @rowsPanel
    # take my size from the rows I have just composed: the viewport's absorb lays the panel out,
    # re-fits the viewport to its capped measure and re-takes my own extent from it. A prompt is
    # composed at BUILD time (a menu is composed by its opener, and hugs at popUp instead), so
    # this is where a prompt reaches its size.
    @rowsViewport._reLayOutAfterContainedPanelChange()

  # Subclass hook: build the type-specific editor and add it to the panel.
  _buildAndAddValueEditorInto: (panel) ->

  # The shared core of the text-bearing editors (Text / Number): build the
  # StringFieldWdgt entry field, surface it under the conventional
  # @tempPromptEntryField name (see its declaration above), and add it to the
  # panel. isNumericField flips the field's numeric mode — NumberPromptWdgt
  # passes whether a ceiling exists.
  _buildAndAddEntryFieldInto: (panel, isNumericField) ->
    @tempPromptEntryField = new StringFieldWdgt (@defaultValue or ""),
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
  # whole job: closing belongs to the pop-up teardown (a transient prompt dies on
  # the click; a pinned one stays and can deliver again).
  deliverValue: ->
    @target[@callback].call @target, @_promptValue()

  # What my editor currently holds. The text-bearing prompts deliver the field's
  # string (value-consuming setters parse/clamp their own property's type);
  # ColorPromptWdgt overrides to deliver the picker's Color.
  _promptValue: ->
    @tempPromptEntryField.getValue()
