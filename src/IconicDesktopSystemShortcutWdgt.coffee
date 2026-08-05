# a "shortcut" (for friends) is a reference to something else.
# What does it mean? That if you duplicate the shortcut you just
# duplicate a reference, and opening either one will open the
# SAME referenced widget. Note that you can't show TWO
# "SAME widget"s at the same time, so opening a shortcut is likely
# to move the referenced widget from a location to another.
#
# If you want to duplicate the referencED widget instead, just
# duplicate that one, and create a reference FOR THE COPY.
#
# So, for example, is the Fizzypaint launcher icon a reference?
# NO, because if you duplicate the launcher, and open both of the
# launchers, you don't get to the SAME widget, you get to two entirely
# separate Fizzypaint instances that have different lives and can be
# shown both at the same time on the screen.

class IconicDesktopSystemShortcutWdgt extends IconicDesktopSystemLinkWdgt

  _reactToChildDropped: (droppedWidget) ->

  constructor: (@target, @title, @icon) ->
    if !@title?
      @title = @target.colloquialName()

    super @title, @icon
    world.widgetsReferencingOtherWidgets.add @
    # NB at this instant I am still an orphan (my attach follows in the same
    # gesture) -- which is exactly why the mark below is mark-only and the sort
    # drains at end-of-cycle, never per-event.
    world.noteStorageMembershipMayHaveChanged()

  # Capability query (replaces `w instanceof IconicDesktopSystemShortcutWdgt and w.target == X` in
  # Widget.createReference): "am I a shortcut pointing at `widget`?" -- folds the target check in.
  # Defined here (inherited by all shortcut subclasses), dispatched via ?() (nothing on Widget).
  # (type-test-elimination campaign)
  isShortcutTo: (widget) ->
    @target == widget

  # I am a desktop shortcut (a reference), not a real widget being dropped in. A folder's drop
  # handling positions/references me accordingly, asking this instead of testing
  # `instanceof IconicDesktopSystemShortcutWdgt`; inherited by all shortcut subclasses.
  # (type-test-elimination campaign)
  isDesktopShortcut: ->
    true

  # Bookkeeping lives in the CORE, not the public destroy() wrapper: bulk paths
  # (fullDestroy / fullDestroyChildren / teardown) recurse core-to-core and
  # never touch the public wrapper -- an override there leaked every
  # bulk-destroyed shortcut into the tracker (latent for years; the Tier A
  # storage audit made it loud, 2026-07-23).
  _destroyNoSettle: ->
    super
    world.widgetsReferencingOtherWidgets.delete @
    # my death may orphan my target (its document falls to the bin) -- mark for
    # the end-of-cycle sort; O(1), so bulk teardown storms stay cheap.
    world.noteStorageMembershipMayHaveChanged()

  alignCopiedWidgetToReferenceTracker: (cloneOfMe) ->
    world.widgetsReferencingOtherWidgets.add cloneOfMe
    world.noteStorageMembershipMayHaveChanged()

  # The shared "bring the referenced target up onto the desktop" ritual, used verbatim by
  # the Document/Folder click handlers and the Script "edit script" action: guard against a
  # dead / already-containing target, un-hide it, find its grabbable root (or the target
  # itself when it sits directly in the bin), and spawn that next to this shortcut.
  # Public, not _-tier: it drives other widgets' public settling API. [call-separation A]
  bringUpTarget: ->
    if @target.destroyed
      @inform "The referenced item\nis dead!"
      return

    if @target.isAncestorOf @
      @inform "The referenced item is\nalready open and containing\nwhat you just clicked on!"
      return

    # A target may owe itself some CONTENT before it can be shown — the desktop's Examples folder
    # builds its five openers here rather than at boot, because a folder is the door that makes them
    # lazy at all (ExamplesFolderWindowWdgt). Widget's default runs the callback inline, so every
    # other shortcut in the system pays nothing and stays in this same cycle.
    # ⚠ THIS IS NOT THE ONLY WAY A TARGET REACHES THE TREE, and it never was — so a target that owes
    # itself content cannot rely on this ritual alone. Delete a folder's desktop shortcut and the
    # folder becomes unreachable, the storage sorter drains it to the BIN, and opening the bin paints
    # it with NO shortcut left to ever click: "shows empty once" would in fact be empty for good.
    # ⛔ The SHELF is not the route to worry about, however tempting it looks as the other resting
    # place: it has no view at all — ShelfWdgt is never added to a parent and never painted — so
    # nothing can be dragged out of it by hand. The bin is the one that is a real view.
    # ⇒ ExamplesFolderWindowWdgt ALSO fills itself from a `step`, which is the settle-safe seam for
    # building content; _reactToBeingAdded is not, since it fires INSIDE the add's own settle.
    @target.whenReadyToBeBroughtUp => @_bringUpTargetNow()

  # nosettle-exempt: not a _NoSettle twin — this is the second half of bringUpTarget, split out so
  # the content-readiness seam above has something to call back into. It settles exactly as the
  # undivided method did, through spawnNextTo.
  _bringUpTargetNow: ->
    whatToBringUp = @target.findRootForGrab()
    # things like draggable graphs have no root for grab,
    # however since they rest in storage (the shelf, or the bin)
    # "directly" on their own it's OK to bring those up (as opposed
    # to things that are part of other widgets resting in storage,
    # in that case you'd tear it off an existing widget and it
    # would probably be a bad thing)
    if !whatToBringUp? and (@target.isDirectlyInBin() or @target.isDirectlyInShelf())
      whatToBringUp = @target
    if !whatToBringUp?
      @inform "The referenced item does exist\nhowever it's part of something\nthat can't be grabbed!"
    else
      whatToBringUp.spawnNextTo @, world
      # RE-RECORD (the F6 family, auto-bookkeeping arc): the brought-up widget may carry
      # fractional bookkeeping from an earlier desktop/storage life, which the fill-only
      # seed respects -- re-derive at the spawned position explicitly.
      whatToBringUp._rememberFractionalSituationInHoldingPanel()
      whatToBringUp.setTitle? @label.text

