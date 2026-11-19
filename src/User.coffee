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
#   The person also holds the ONE table of edited tool code (drawingToolOverrides): an edit of a tool,
# made from any palette's cell, docked or floating, means that tool everywhere, since holders hold
# only a KEY and a key means the same code for every holder.
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

  # THE PERSON'S EDITS OF THE TOOLS: tool key -> the source text the person saved for it, through
  # any palette cell's edit mark. A tool the person never edited has no entry and means its stock
  # source (PaintToolbarWdgt.sourceForToolKey). TEXT, never a function: the person types text, and
  # the CoffeeScript must stay around to be opened and edited again. undefined until the first edit
  # builds my own object -- never an object on the prototype, which every person would share.
  drawingToolOverrides: undefined

  # THE KEYBOARD FAMILY I type on: "mac" (Cmd and Option) or "pc" (Ctrl), whose conventions every caret follows
  # for line and document ends, word jumps, word and line deletes, select-all, undo and redo (CaretWdgt.chordVerbs). The page's
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

  # The person saved `source` as the tool `toolKey` (the code prompt of a palette cell's edit mark
  # checked it first). Every surface using that key takes it up at its next use; announced like the
  # hand, so what reflects the person re-reads it.
  overrideDrawingTool: (toolKey, source) ->
    @drawingToolOverrides ?= {}
    @drawingToolOverrides[toolKey] = source
    world.dataflow?.markNonValueChange @
    return

  # My edits of the tools BECOME `table`'s own entries (tool key -> source text): an edit `table` lacks
  # is gone, and an undefined or empty `table` means no edits. A loaded world states its file's table
  # this way (WorldWdgt.loadWorldSnapshot): the load keeps its users, so an edit made before it must not
  # outlive it. The entries go into an object of my own, never `table` itself, and each one by
  # Object.fromEntries, an own entry whatever its key spells (a key read out of a file is data).
  # Announced like the hand, and only when my edits changed.
  replaceDrawingToolOverrides: (table) ->
    entries = Object.entries table ? {}
    current = @drawingToolOverrides ? {}
    unchanged = entries.length is Object.keys(current).length and
      entries.every ([toolKey, source]) -> Object::hasOwnProperty.call(current, toolKey) and current[toolKey] is source
    return if unchanged
    @drawingToolOverrides = if entries.length > 0 then Object.fromEntries entries else undefined
    world.dataflow?.markNonValueChange @
    return
