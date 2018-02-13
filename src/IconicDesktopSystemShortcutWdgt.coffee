# REQUIRES HighlightableMixin

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
# separate Fizzypaint instances that have different lifes and can be
# shown both at the same time on the screen.

class IconicDesktopSystemShortcutWdgt extends IconicDesktopSystemLinkWdgt

  @augmentWith HighlightableMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 0, 0, 0

  reactToDropOf: (droppedWidget) ->

  constructor: (@target, @title, @icon) ->
    if !@title?
      @title = @target.colloquialName()

    super @title, @icon
    world.widgetsReferencingOtherWidgets.push @

  destroy: ->
    super
    world.widgetsReferencingOtherWidgets.remove @

  alignCopiedMorphToReferenceTracker: (cloneOfMe) ->
    if world.widgetsReferencingOtherWidgets.indexOf(@) != -1
      world.widgetsReferencingOtherWidgets.push cloneOfMe

