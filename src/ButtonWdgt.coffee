# sends a message to a target object when pressed.
# Doesn't have any particular shape, but can host
# a widget to be used as "face"

# TODO it's unclear to me why we pass a number of targets
# and actions in the constructor when what we could simply
# do is to extend this button and override the mouse events?

class ButtonWdgt extends Widget

  target: undefined
  action: undefined
  # the widget my @action is ABOUT — trigger's slot 2. A menu row's panel fills it with its own
  # target (the widget the whole menu is about), which is how a row wired at a DIFFERENT receiver
  # (an attach candidate, a choose-target entry) still knows its subject. undefined on a button
  # whose action has no subject.
  subjectOfAction: undefined
 
 
  doubleClickAction: undefined
  argumentToAction1: undefined
  argumentToAction2: undefined
 
  toolTipMessage: undefined

  # what the button SHOWS, from opts.face. A string is coerced to a centred StringWdgt
  # and added as a child in the constructor, so by then this always holds a widget.
  faceWidget: undefined

  ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked: true
  
  # tells if the button represents a widget, in which
  # case we are going to highlight the Widget on hover
  representsAWidget: false

  padding: 0


  # overrides to superclass: no colour of my own -- my look is asked of the pointer as I am painted
  # (_fillForMyState, below) -- so a button never wears a new shape's content default. A subclass
  # whose look reads a colour of its own sets it after my constructor (LabelButtonWdgt).
  color: undefined

  # ALL options, no operand — `target:` and `action:` included. They say WHO to tell and WHAT to
  # say, but not every caller has them when it builds me: a face-only button wired later, the two
  # faces a ToggleButtonWdgt switches between (the toggle does the telling). As a positional
  # head they made those callers write `undefined, undefined` to reach the options — and R3 of
  # docs/architecture/constructor-and-parameter-conventions.md is that once there is a tail, every
  # OPTIONAL operand is a hole. So the whole family speaks one vocabulary of keys, and a caller
  # names only what it has.
  #
  # `closesUnpinnedPopUps` in particular is an OPTION rather than the leading positional: a bare
  # `true` opening nearly every call site is precisely the smell R1 names, and since it defaults
  # to true, the sites that only wanted the default simply do not say it.
  #
  # `face` (not `faceWidget`) because the value is as often a STRING as a widget — the body
  # below wraps a string into a centred StringWdgt — and an option is named for what the
  # CALLER means (R4).
  #
  # NOTHING here is a `@param`: a `@param` assigns unconditionally, so a subclass's prototype
  # value for any of these fields would be clobbered with `undefined` on every construction.
  # `toolTipMessage` in particular is read GUARDED, which is what lets a subclass declare
  # `toolTipMessage:` on its prototype and have it survive — the IconButtonWdgt family states
  # its hover text that way. target and action are read unconditionally, first — the place and
  # the order a `@param` head assigns in (R6) — and no subclass declares either on its prototype.
  constructor: (opts = {}) ->
    @target = opts.target
    @action = opts.action
    @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = opts.closesUnpinnedPopUps ? true
    @faceWidget = opts.face
    @subjectOfAction = opts.subject
    @toolTipMessage = opts.toolTip if opts.toolTip?
    @doubleClickAction = opts.doubleClickAction
    @argumentToAction1 = opts.arg1
    @argumentToAction2 = opts.arg2
    @representsAWidget = opts.representsAWidget ? false
    @padding = opts.padding ? 0

    # additional properties:

    super()
    @defaultRejectDrags = true

    @_buildAndConnectChildren()

  # THE POINTER STATE MY LOOK SHOWS, asked of the hand as I am painted -- no button keeps one, so none
  # is saved, copied or left behind by a gesture: "pressed" while the hand presses me
  # (ActivePointerWdgt.pressesOn: a press that slid off me shows none, and shows again when it slides
  # back), "highlighted" while the pointer rests on me (restsOn: never under a finger), "atRest"
  # otherwise. Every look of the button family reads it (my plain fill below, a label button's
  # appearance, a simple button's box, an icon button's glyph); a list row answers its own
  # (MenuItemWdgt).
  _shownState: ->
    if world.hand.pressesOn @
      "pressed"
    else if world.hand.restsOn @
      "highlighted"
    else
      "atRest"

  # THE PLAIN BUTTON's fill for the state I show, read as I am painted by an appearance that asks it
  # (RectangularAppearance: a bare ButtonWdgt given one, a SimpleRectangularButtonWdgt): the plain
  # button's roles at rest, hovered and pressed. A subclass with a look of its own answers its own
  # (SimpleButtonWdgt's box, IconButtonWdgt's glyph ink).
  _fillForMyState: ->
    theme = WorldWdgt.theme
    switch @_shownState()
      when "pressed" then theme.plainButtonPressFill
      when "highlighted" then theme.plainButtonHoverFill
      else theme.plainButtonFill

  # THE HAND'S ANSWERS ABOUT ME MAY HAVE MOVED (ActivePointerWdgt._tellPointerStateChanged): my look is
  # read from them as I am painted, so I repaint. A toolbar tool whose look is its cell's says so
  # instead (CodeInjectingSimpleRectangularButtonWdgt).
  notePointerStateChanged: ->
    @_changed()

  # Build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  # This REPLACES the old "defer the face's layout until attach" hack. The old fear -- "a settle in a
  # constructor leaks into ANY callback that builds a button (e.g. FrameWdgt._reactToChildDropped's chrome
  # rebuild via new *IconButtonWdgt, which must stay settle-neutral)" -- no longer bites: a button built
  # INSIDE such a callback runs in-flush, where the settle-tier's in-flush+orphan AUTO-DEFER
  # (Widget._settleLayoutsAfter: `return coreThunk() if @isOrphan()`) defers automatically. So no settle
  # leaks into the settle-neutral callback, while a top-level `new ButtonWdgt` settles its own orphan layout.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if @faceWidget?
      if (typeof @faceWidget) == "string"
        @faceWidget = (new StringWdgt @faceWidget, fontRole: WorldWdgt.theme.fonts.buttonLabel).alignCenter()
      @_addNoSettle @faceWidget
      @_invalidateLayout()
  

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout

    # My face gets the room my padding leaves in my box -- all of it, unless my class places the
    # face inside that room itself (a soft hook: SimpleButtonWdgt sets a line of text in a box one
    # line tall, centred in the room).
    if @faceWidget?.parent == @
      faceRoom = newBoundsForThisLayout.insetBy @padding
      @faceWidget._applyGrantedBounds (@_faceBoundsIn?(faceRoom) ? faceRoom)

    super
    @_markLayoutAsFixed()

  # trigger button action. The four slots have FIXED meanings at every dispatch:
  #   slot 1 = the button that fired (myself — the pop-up openers read it to build their
  #            parent chain), slot 2 = @subjectOfAction, slots 3-4 = the per-row payload.
  trigger: ->
    if @action? and @action != ""
      # dev-build type tripwire (2026-07-06 incident: an @action passed as a function CLOSURE fails
      # obscurely here — @target[<function>] coerces to an undefined key; SliderWdgt carried the same
      # latent misuse). @action must be a STRING method name on @target. `if Automator?` ⇒ the check
      # cannot run without the harness part (the Automator is the harness part), like all test-only code.
      if Automator? and typeof @action isnt 'string'
        throw new Error "ButtonWdgt action must be a STRING method name on the target (dispatched as @target[@action]) — got #{typeof @action}"
      @target[@action].call @target, @, @subjectOfAction, @argumentToAction1, @argumentToAction2
    return

  # trigger()'s twin for a double-click: the same four slots, dispatched by the NAME in my
  # doubleClickAction instead of my action (a list row's names its list's openRow). Specifying a
  # doubleClickAction is optional.
  triggerDoubleClick: ->
    return  unless @doubleClickAction
    @target[@doubleClickAction].call @target, @, @subjectOfAction, @argumentToAction1, @argumentToAction2

  # My COMMAND edge (Widget.graphEdgesOut -- the three-edge model,
  # docs/archive/graph-edges-and-lifecycle-plan.md §4.2): the widget my @action is dispatched at.
  # ONE edge however many verbs share the receiver (@doubleClickAction dispatches at the same
  # @target). The gate is a CAPABILITY probe, and the capability is the protocol itself: a
  # dispatch receiver may be any object (a layout spec's menu popout, a helper), and exactly the
  # receivers that answer graphEdgesOut are graph citizens my edge can point into -- everything
  # else is outside the widget graph by definition, no type test needed.
  graphEdgesOut: ->
    if @target?.graphEdgesOut? then super().concat [{kind: 'command', to: @target}] else super()

  
  # MY CLICK: any unpinned pop-up I sit in closed, my click's act (_actOnClick: my action, or, with Cmd
  # held, what I name opened apart), and the click escalated -- unless my act opened a thing apart: that
  # click is CONSUMED and goes no further, for a holder it climbs to may raise itself
  # (PanelWdgt.activated), and would raise the original over the window the click just opened. The hand
  # hands me the release's facts (pos, button, buttons, ctrlKey, shiftKey, altKey, metaKey) and whether
  # this click continues a double or a triple click.
  activated: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
    if @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked
      @propagateKillPopUps()
    @escalateEvent "activated", arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9  if @_actOnClick arg7, arg8, arg9

  # MY DOUBLE CLICK: my doubleClickAction (triggerDoubleClick), with Cmd held or not. A double click
  # reaches me only in a gesture whose FIRST click was plain -- the hand consumes every later click of a
  # gesture whose first click opened a thing apart (ActivePointerWdgt.noteClickActsForItsGesture) -- and a
  # plain gesture stays plain: a Cmd second click on it does the plain double (_opensApartOnClick).
  doubleActivated: ->
    @triggerDoubleClick()

  # MY CLICK'S ACT, after what every click of my family does first (a pop-up I sit in closed; a label
  # button raised), answering whether the click GOES ON up, as a press's receiver states whether its
  # press goes on (Widget.pressBegan): my action (trigger), and the click goes on -- or, when my click
  # opens apart (_opensApartOnClick), what I name opened in a window of its own INSTEAD
  # (openInANewInspector), before any action of mine runs: a list's select writes its selection before
  # it dispatches, a class button's action drops its view's choice first, a trail button's scrolls the
  # set, so nothing is chosen, selected or scrolled in the original. That click is CONSUMED: it goes no
  # further, and the hand is told it acted for its whole gesture
  # (ActivePointerWdgt.noteClickActsForItsGesture), so the gesture's later clicks do nothing at all,
  # wherever they land -- on the window it opened too -- and whatever keys they carry: one gesture, one
  # window (as one double click on a creator makes one widget: CreatorWdgt.activated). The ONE seat of
  # that rule, for both clicks of my family: mine and LabelButtonWdgt's.
  _actOnClick: (metaKey, partOfDoubleClick, partOfTripleClick) ->
    if @_opensApartOnClick metaKey, partOfDoubleClick, partOfTripleClick
      @openInANewInspector()
      world.hand.noteClickActsForItsGesture @
      false
    else
      @trigger()
      true

  # DOES THIS CLICK OF MINE OPEN APART? With Cmd held (metaKey: a mouse's click or a finger's tap, the
  # modifier being the keyboard's, whatever the pointer), on the FIRST click of a gesture, while I name a
  # thing to open in a new inspector (toOpenInANewInspector). A click that continues a double or a triple
  # click reaches me only in a gesture whose first click was plain (the hand consumes the rest of a
  # gesture whose first click opened apart), and a plain gesture stays plain: Cmd held on its second
  # click does the plain double -- my action, then my double action (doubleActivated) -- as it does with
  # no key held. The one statement of when, read by my click's act (_actOnClick); the facts the hand
  # handed me first, what I name asked last.
  _opensApartOnClick: (metaKey, partOfDoubleClick, partOfTripleClick) ->
    metaKey and not (partOfDoubleClick or partOfTripleClick) and @toOpenInANewInspector()?

  # WHAT I OPEN IN A NEW INSPECTOR, asked of my TARGET, the widget that built me and knows what I mean
  # (toOpenInANewInspectorBy, handed me): {subject, member, name} -- the door's two operands
  # (Widget.spawnInspector: the subject, and the member chosen in it, or none) and the words I show,
  # which title the menu that offers it -- or undefined. Only a target that answers names anything: an
  # inspector's list for its row (ListWdgt, through its view), an inspector for its class button
  # (InspectorWdgt), a browser for a step of its trail (InspectorBrowserWdgt); every other button names
  # nothing and keeps its plain click. Asked by the menus that offer it (Widget.buildContextMenu,
  # buildHierarchyMenu, each where it finds my addOpenInANewInspectorMenuEntry, the method they send)
  # and by my click, and asked again at the press of what it offers, so I hold nothing of it. A
  # QUERY that runs nothing of a person's while a menu is built: where deriving an answer again would
  # label a person's widgets, its answerer reads what it holds or shows instead (an object list the
  # objects it holds, a trail the words its button shows).
  toOpenInANewInspector: ->
    @target?.toOpenInANewInspectorBy? @

  # WHAT I NAME, OPENED IN A NEW INSPECTOR, through the one door (Widget.spawnInspector): a browser of its
  # own on the thing, in a window that lands BESIDE the one I stand in (opts.beside: me), the member
  # chosen in it when I name one. The original is left as it was. The action of my "Open in a new
  # inspector" row (addOpenInANewInspectorMenuEntry) and of my click with Cmd held (_actOnClick). I
  # name nothing: nothing opens.
  openInANewInspector: ->
    thing = @toOpenInANewInspector()
    @spawnInspector thing.subject, member: thing.member, beside: @  if thing?

  # MY "Open in a new inspector" ROW: its one statement, in the two menus that offer it -- the one-row
  # menu user mode builds over me (Widget.buildContextMenu) and the developer's hierarchy menu over what
  # I hold, which it leads (Widget.buildHierarchyMenu). Each of them has just asked whether I name a
  # thing to open in a new inspector (toOpenInANewInspector), and sends this only when I do, so nothing
  # is asked again here. No "…": opening a window asks nothing more. It opens no submenu and stands for
  # no widget.
  addOpenInANewInspectorMenuEntry: (menu) ->
    menu.addMenuItem "Open in a new inspector", @, "openInANewInspector", toolTip: "open it in a window\nof its own"

  # you shouldn't be able to drag a compound
  # widgets containing a button by dragging the button
  # (because you expect buttons attached to anything but the
  # world to be "slippery", i.e.
  # you can "skid" your drag over it in case you change
  # your mind on pressing it)
  # and you shouldn't be able to drag the button away either
  # so the drag is entirely rejected
  #   UNLESS MY PARENT SAYS I AM A PAYLOAD RATHER THAN A PART. Slipperiness protects a
  # COMPOUND — it assumes the button is a piece of the thing containing it — so a container
  # that declares the opposite about me is answering the very question slipperiness assumes.
  # `wantsDetachOfChild` is the existing parent-side opt-in, and reusing it is the point:
  # Widget.grabsToParentWhenDragged consults the same declaration, so the two questions a grab
  # asks — "is this drag cancelled" and "does it lift my parent instead" — now read ONE fact
  # and cannot disagree. Resting on the desktop is the same statement, made by the one parent
  # with no reason to spell it out.
  #   Clients: a CommandPanelWdgt whose pop-up is PINNED (dragging a command onto your own
  # control panel), and a spreadsheet CellWdgt's hosted payload.
  rejectDrags: ->
    return false if @parent == world
    return false if @isDetachablePayloadOfMyParent()
    # ... and a CHROME STRIP owns the drags that start on its pieces (program ruling: a bar piece
    # acts on tap, never on drag). A press that turns into a drag on a close/collapse/edit piece
    # is the user taking hold of the BAR -- moving the window, pulling a docked band out of its
    # slot -- so I must not cancel it here: I yield, and the climb reaches the strip. Same
    # parent-side shape as wantsDetachOfChild above; the strip declares it, no piece has to know
    # which strip it is on, and the hand needs no case for any of it.
    return false if @parent?.ownsDragsOfMyChildren?()
    return @defaultRejectDrags

  # Does my container hand me out — am I a payload it holds, rather than a part of it? ONE
  # statement of that fact, because more than one thing turns on it: the drag above, and the
  # GRIP that LabelButtonAppearance draws so a liftable row says so before you try
  # (design-principles: an affordance the user has to be told about is not one).
  #   Deliberately narrower than rejectDrags. Resting on the desktop also makes me draggable,
  # but it does not make me a payload of anything, and it needs no grip: everything loose on a
  # desktop is draggable, so marking it would say nothing.
  #   In content in view mode nothing is handed out, whatever my container declares: the grab
  # door (Widget.grabsToParentWhenDragged) asks the holder I would leave that question before
  # wantsDetachOfChild, and so do I, so the drag, its cancellation and the grip read one answer.
  isDetachablePayloadOfMyParent: ->
    return false if @parent?.sitsInViewModeContent()
    (@parent?.wantsDetachOfChild? @) ? false

