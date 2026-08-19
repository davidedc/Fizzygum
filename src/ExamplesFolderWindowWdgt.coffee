# ExamplesFolderWindowWdgt — the desktop's "Examples" folder, which FILLS ITSELF THE FIRST TIME IT
# IS OPENED rather than at boot.
#
# ⚠⚠ THREE TIERS, THREE MOMENTS, and keeping them apart is the whole design:
#   boot            the folder exists and is EMPTY. No icon of its contents, no app class.
#   open the folder fetches 'examples-icons' — the art ONLY this folder draws — and builds the five
#                   openers. Still no app: an opener carries its app's class NAME, not the class.
#   click an opener fetches THAT app's own one-class part, compiles it, runs it. One click, one app.
# So a visitor who never opens the folder downloads none of it, and one who opens it to click a
# single icon downloads that icon's app and not its four neighbours'.
#
# ⚠ WHY THIS CAN BE LAZY AT ALL, when a desktop icon's app cannot be deferred the same way: a FOLDER
# IS A DOOR. WorldWdgt.createDesktop constructs every desktop icon at boot, but nothing here is
# reached until the folder's shortcut is clicked, and
# ShortcutWdgt.bringUpReferencedWidget is fire-and-forget (ButtonWdgt discards a click
# action's return value), so it CAN await. ⇒ boot-time REACHABILITY is what forces eagerness.
#
# ⚠ ONLY THE C-F ART MOVED, and that is not an oversight. The folder's other four icons — the
# typewriter, the slide, the dashboards glyph and the generic shortcut frame — are drawn by DESKTOP
# icons and by FolderWindowWdgt/BinOpenerWdgt at boot, so they are core whatever this folder does.
# The C-F glyph is 9.5 KB of vector art that nothing else names, which is exactly what made it worth
# a part of its own.
#
# ⚠ TWO ENTRY POINTS FILL ME, because being SHOWN is what owes me content — not the ritual that
# showed me. `whenReadyToBeBroughtUp` is awaited by the shortcut click (which is why that path never
# flashes an empty folder), and `step` catches every other way I reach the tree — in practice the
# bin, once my shortcut has been deleted. Both funnel into the one awaited scope below.
#
# ⚠ THE POPULATOR IS A METHOD ON A SUBCLASS, NOT A FUNCTION STORED ON THE INSTANCE. Assigning a
# closure to a widget field is BANNED — the serializer cannot encode one, and doing it crashed the
# save path once already (the StringWdgt selection-handler arc). A subclass carries its behaviour in
# its prototype, where serialization never has to look, and this adds one boolean to a saved world.
class ExamplesFolderWindowWdgt extends FolderWindowWdgt

  # false until the contents have been built. SERIALIZED, deliberately: a world saved before the
  # folder was ever opened must still fill it in when it is opened in the restored world, and a
  # world saved after must NOT build a second set of icons over the ones it already carries.
  # ⚠ Not derived from "is the folder empty?" — a user who empties the folder means it.
  populated: false

  # The one-shot bringUpReferencedWidget asks about before showing me. Runs the callback INLINE once populated,
  # which after the first open is every time — deferring by even a microtask would move the open a
  # whole world cycle later, and the SystemTest suite measures cycles
  # (../Fizzygum-tests/DETERMINISM.md). Same fast-path rule as PartsRegistry.whenAllLoaded.
  #
  # ⚠ THE FIVE BUILDS LIVE INSIDE THE AWAITED SCOPE, and factoring them into a `_populate` helper is
  # not a tidy-up available here: check-part-edges.js reads ONE LINE AT A TIME, so a reference three
  # methods away from the await it depends on is indistinguishable from an unguarded one — and the
  # gate is right, because a reader cannot see the await either and nothing would stop a later edit
  # from calling the helper directly.
  whenReadyToBeBroughtUp: (callback) ->
    return callback() if @populated
    # ⚠ TWO DIFFERENT QUESTIONS, and only isAvailable answers this one: an artifact that ships no
    # 'examples-icons' (the `lean` appliance) has nothing to fetch and never will, so whenAllLoaded
    # would REJECT and the folder would never open at all — turning a working empty folder into a
    # dead icon. (isAvailable = "did this build ship it"; whenAllLoaded = "get it here".)
    return callback() unless world.parts.isAvailable "examples-icons"
    world.parts.whenAllLoaded ["examples-icons"], =>
      # a second click while the first fetch was still in flight must not build the contents twice
      unless @populated
        @populated = true
        # ⚠ ORDER IS THE LAYOUT: the folder panel places icons in call order on a grid, so this
        # sequence is what the user sees. Each opener names its app as a STRING and resolves it on
        # click — see AppLauncherWdgt's lazy mode.
        L = AppLauncherWdgt
        # ⚠ THE ONE ICON OVERRIDE IN THE SYSTEM, and it is forced rather than preferred: this art is
        # the LAZY `examples-icons` part, and only a line inside this awaited scope may legally name
        # it — check-part-edges.js reads one line at a time, so the same thunk written in AppCatalog
        # (a CORE file) would be an unguarded core->lazy reference and fail the build. Every other
        # door takes both its caption and its art from the catalog.
        L.addToFolder @, "DegreesConverterApp", -> new DegreesConverterIconWdgt
        L.addToFolder @, "SampleSlideApp"
        L.addToFolder @, "SampleDashboardApp"
        L.addToFolder @, "SampleDocApp"
        L.addToFolder @, "SpreadsheetApp"
      callback()

  # ⚠⚠ POPULATION MUST NOT DEPEND ON WHICH RITUAL SHOWED ME — hence the step below, and this
  # registration to feed it. bringUpReferencedWidget awaits the protocol above BEFORE showing me, which is why
  # the shortcut click never flashes an empty folder; but it is not the only way I reach the tree.
  # DELETE my desktop shortcut and I become unreachable, the storage sorter drains me to the BIN, and
  # opening the bin PAINTS me — empty, with no shortcut left to ever fill me. That route is driven
  # end to end by scripts/parts-lazy-icons-headless.js, which is where its evidence lives.
  # ⚠ I step only while I still OWE myself content: the step unregisters the first time it fires, so
  # the per-cycle cost ends at the first open and a folder saved after being populated is never
  # registered at all — the Serializer records stepping membership, so the restore is automatic.
  # DataflowSource is the same register-only-while-needed precedent.
  constructor: ->
    super
    world.steppingWdgts.add @

  # ⚠ THE ONLY SEAM AVAILABLE, and it is available for a precise reason: _runChildrensStepFunction
  # runs early in doOneCycle — after the queued events, BEFORE the dataflow and layout drains and
  # outside any settle — so a step may legally create children. _reactToBeingAdded, the obvious
  # lifecycle hook, fires INSIDE the add's own settle, where building five children would re-enter
  # the settle tier. ⭐ Because the events that drop me on the tree are played EARLIER IN THE SAME
  # CYCLE, an already-fetched `examples-icons` fills me before that cycle's paint: no empty flash at
  # all. Only the first-ever open (which must fetch) can show one, and that beats the alternative of
  # showing empty for ever.
  # ⚠ `root() == world`, not `parent?`: while the hand drags me my root is the HAND, and contents are
  # better built on the drop than in flight. root() is cached per WorldWdgt.structureVersion, so this
  # is a field compare per cycle until it fires.
  step: ->
    return unless @root() == world
    # ONE SHOT, whatever the outcome. On an artifact that ships no `examples-icons` (the `lean`
    # appliance) the protocol calls back WITHOUT populating and never could — retrying every cycle
    # for the life of the world would buy nothing. A second entry cannot build twice anyway (the
    # `unless @populated` guard above), so this is economy rather than correctness.
    world.steppingWdgts.delete @
    @whenReadyToBeBroughtUp noOperation
