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

  @augmentWith HighlightableMixin, @name

  color_hover: Color.create 90, 90, 90
  color_pressed: Color.GRAY
  color_normal: Color.BLACK

  _reactToChildDropped: (droppedWidget) ->

  constructor: (@target, @title, @icon) ->
    if !@title?
      @title = @target.colloquialName()

    super @title, @icon
    world.widgetsReferencingOtherWidgets.add @

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

  destroy: ->
    super
    world.widgetsReferencingOtherWidgets.delete @

  alignCopiedWidgetToReferenceTracker: (cloneOfMe) ->
    world.widgetsReferencingOtherWidgets.add cloneOfMe

  # The shared "bring the referenced target up onto the desktop" ritual, used verbatim by
  # the Document/Folder click handlers and the Script "edit script" action: guard against a
  # dead / already-containing target, un-hide it, find its grabbable root (or the target
  # itself when it sits directly in the basement), and spawn that next to this shortcut.
  # Public, not _-tier: it drives other widgets' public settling API. [call-separation A]
  bringUpTarget: ->
    if @target.destroyed
      @inform "The referenced item\nis dead!"
      return

    if @target.isAncestorOf @
      @inform "The referenced item is\nalready open and containing\nwhat you just clicked on!"
      return

    # the target could be hidden if it's been hidden in the
    # basement view "only show lost items"
    @target.show()

    whatToBringUp = @target.findRootForGrab()
    # things like draggable graphs have no root for grab,
    # however since they are in the basement "directly" on their own
    # it's OK to bring those up (as opposed to things
    # that are part of other widgets that are in the basement,
    # in that case you'd tear it off an existing widget and it
    # would probably be a bad thing)
    if !whatToBringUp? and @target.isDirectlyInBasement()
      whatToBringUp = @target
    if !whatToBringUp?
      @inform "The referenced item does exist\nhowever it's part of something\nthat can't be grabbed!"
    else
      # let's make SURE what we are bringing up is
      # visible
      whatToBringUp.show()
      whatToBringUp.spawnNextTo @, world
      whatToBringUp._rememberFractionalSituationInHoldingPanel()
      whatToBringUp.setTitle? @label.text

