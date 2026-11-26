# User — the PERSON at the machine, and the modal state they carry from one widget to the next:
# what they are HOLDING, not what any widget owns. A plain delegated collaborator (the
# UntitledNamingService / DataflowEngine pattern), NOT a Widget: the world HAS-A list of them,
# `world.users`, with `world.user` naming the one who is acting.
#
# WHY THE STATE LIVES HERE. A paint tool is held by one of two HOLDERS. A window wearing a palette in
# one of its edge slots holds its own (FrameWdgt.armedDrawingTool): a palette docked there sets it, and
# the drawings inside that window paint with it. Everything else is held by the person, here: a
# FLOATING palette sets my tool, and every drawing that stands in no window wearing a palette paints
# with it. Both holders answer the same pair (armedDrawingTool, armDrawingTool), so a palette's tool
# and a paint surface each find their nearest holder without asking which kind it is. A palette is a
# VIEW of its holder's fact and a CONTROLLER that writes it; the fact itself has one home per holder.
#   The person also holds the ONE table of edited tools (drawingToolOverrides): an edit of a tool,
# made through any palette's cell, docked or floating, means that tool everywhere, since holders hold
# only a KEY and a key means the same members for every holder. And the person holds the TOOL OBJECTS
# those edits are made on (drawingTools), one per key, which the authoring part builds and keeps here.
#
# ── THE ANNOUNCE SEAM ────────────────────────────────────────────────────────────────────────
# I am a dataflow NODE (DataflowEngine's duck-typed node protocol: any object the engine holds by
# identity -- the SecondsSource / FrameSource precedent for a non-widget source). A change here
# ANNOUNCES with markNonValueChange, the weaker of the two verbs, because a person has no single
# VALUE for a wire to carry: my watchers RE-READ me. They subscribe with `firesOnAnyChange`, which
# is exactly the seam a reflecting menu row uses (MenuItemWdgt._subscribeToWhatIShow), one
# level up: a row reflects a widget's property, a palette reflects a person's hand.
#
# ── WHAT IS AND IS NOT MINE ──────────────────────────────────────────────────────────────────
# `world.editorFocusWdgt` (which widget the person is editing) and `world.caret` (where their
# typing goes) are the same KIND of fact and are future kin here -- they stay on the world, not
# here.
#   Multi-user INPUT ATTRIBUTION is out of scope: `world.users` is a list because the concept is
# per-person, and it holds ONE member today. Nothing here decides which person an incoming event
# belongs to: what reads me at a pointer event -- a palette tool's press, a paint surface finding its
# holder (CanvasGlassTopWdgt._toolHolder) -- reads `world.user`, the one acting.
class User

  # THE TOOL IN HAND: a tool KEY ('pencil' | 'brush' | 'toothpaste' | 'eraser'), or undefined for
  # an empty hand. A KEY and never a widget: the person holds a pencil, not one particular
  # palette's pencil button, and a key survives the death of every palette that ever showed it.
  #   Born holding a pencil, so a drawing born under the hand is born ready to draw.
  armedDrawingTool: 'pencil'

  # THE PERSON'S EDITS OF THE TOOLS: tool key -> its MEMBER RECORD, a plain record of member name ->
  # source text, in the tool's member order, as the person's tool for that key last wrote itself
  # (DrawingToolBase.sourceChanged, after an inspector's edit of it) -- the WHOLE tool's members once
  # edited, never a change over the stock ones, so a Remove of a stock member is kept too. A tool the
  # person never edited has no entry and means its stock members (PaintToolbarWdgt.stockToolMembers).
  # TEXT, never a function: the person types text, and the CoffeeScript must stay around to be opened
  # and edited again. undefined until the first edit builds my own object -- never an object on the
  # prototype, which every person would share.
  drawingToolOverrides: undefined

  # THE TOOLS I HOLD: tool key -> the person's tool for it (a DrawingTool), built and kept by
  # DrawingTool.of, which re-makes one from my table whenever its key means another record. A part's
  # objects, held here as the person's (the authoring part builds them; I name no class of it), and
  # never saved (my record names its fields: Serializer._userRecord) nor copied (I am in no tree).
  # undefined until the first ask builds my own object.
  drawingTools: undefined

  # THE KEYBOARD FAMILY I type on: "mac" (Cmd and Option) or "pc" (Ctrl), whose conventions every caret follows
  # for line and document ends, word jumps, word and line deletes, select-all, undo and redo
  # (CaretWdgt.chordVerbs), and whether Ctrl+Alt types (a PC's AltGr, CaretWdgt.keystrokeMayType). The page's
  # (keyboardFamilyOfThisPage), never saved with a world -- my record is an explicit one (Serializer._userRecord)
  # -- so a world saved on a Mac imposes no Cmd on a PC.
  keyboardFamily: undefined

  constructor: ->
    @keyboardFamily = User.keyboardFamilyOfThisPage()

  # the family the page's ?keys= names (stashed at boot: window.FIZZYGUM_KEYS), else the platform's own: a Mac's,
  # an iPhone's or an iPad's keyboard is a Mac's (Cmd and Option), every other a PC's (Ctrl)
  @keyboardFamilyOfThisPage: ->
    return window.FIZZYGUM_KEYS if window.FIZZYGUM_KEYS in ["mac", "pc"]
    if /^(Mac|iPhone|iPad|iPod)/.test navigator.platform then "mac" else "pc"

  # THE ONE WRITE, and it only STATES the fact: this tool is now in hand (undefined = an empty
  # hand, which paints nothing). IDEMPOTENT -- arming what is already held changes nothing and
  # announces nothing -- so re-stating a recorded hand, as a restored snapshot does, is as safe as
  # changing it. That a SECOND TAP on the tool in hand means "put it down" is the meaning of a
  # gesture, not of this fact, so it is decided where the gesture is
  # (CodeInjectingSimpleRectangularButtonWdgt.activated).
  armDrawingTool: (toolKey) ->
    return if toolKey is @armedDrawingTool
    @armedDrawingTool = toolKey
    # markNonValueChange, not markStale: see the announce seam above. DARK when nobody watches.
    world.dataflow?.markNonValueChange @
    return

  # My edit of the tool `toolKey`, or undefined while I have none (an own entry only: a key is
  # data, never a member of the table's prototype).
  drawingToolOverrideFor: (toolKey) ->
    return undefined unless @drawingToolOverrides?
    return undefined unless Object::hasOwnProperty.call @drawingToolOverrides, toolKey
    @drawingToolOverrides[toolKey]

  # The person's tool `toolKey` wrote `members` (a member record, as my table keeps it) as their edit of
  # it (DrawingToolBase.sourceChanged, which hands me a fresh record each time). I keep the record I am
  # handed, the one the tool remembers making itself from. Every surface using that key takes it up at
  # its next use; announced like the hand, so what reflects the person re-reads it.
  overrideDrawingTool: (toolKey, members) ->
    @drawingToolOverrides ?= {}
    @drawingToolOverrides[toolKey] = members
    world.dataflow?.markNonValueChange @
    return

  # My edits of the tools BECOME `table`'s own entries (tool key -> member record): an edit `table` lacks
  # is gone, and an undefined or empty `table` means no edits. A loaded world states its file's table
  # this way (WorldWdgt.loadWorldSnapshot): the load keeps its users, so an edit made before it must not
  # outlive it. "Unchanged" is read per member: the same keys, and per key the same member names in the
  # same order with the same sources (_sameMembers). The entries go into objects of my own, never
  # `table`'s, each one by Object.fromEntries, an own entry whatever its key or member name spells (read
  # out of a file, both are data) -- fresh records, so each tool I hold, which compares its key's
  # record by identity, re-makes itself at its next ask (DrawingTool.of). The tools themselves stay
  # mine: an inspector open on one goes on editing my tool. Announced like the hand, and only when my
  # edits changed.
  replaceDrawingToolOverrides: (table) ->
    entries = Object.entries table ? {}
    current = @drawingToolOverrides ? {}
    unchanged = entries.length is Object.keys(current).length and
      entries.every ([toolKey, members]) -> Object::hasOwnProperty.call(current, toolKey) and User._sameMembers current[toolKey], members
    return if unchanged
    @drawingToolOverrides = if entries.length > 0 then Object.fromEntries ([toolKey, Object.fromEntries Object.entries members] for [toolKey, members] in entries) else undefined
    world.dataflow?.markNonValueChange @
    return

  # Do two member records hold the same members: the same names, in the same order, each with the same
  # source?
  @_sameMembers: (one, other) ->
    oneEntries = Object.entries one
    otherEntries = Object.entries other
    oneEntries.length is otherEntries.length and
      oneEntries.every ([name, source], i) -> otherEntries[i][0] is name and otherEntries[i][1] is source
