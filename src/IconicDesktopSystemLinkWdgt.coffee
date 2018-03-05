# This is an icon, with a caption below, AND it has some logic
# to be shown "in its own layer" together with the
# other desktop system links. I.e. you never see a desktop system link
# on top of a window (unless during a drag), so in that sense
# the desktop system links live in their own "layer"

class IconicDesktopSystemLinkWdgt extends WidgetHolderWithCaptionWdgt

  moveOnTopOfTopReference: ->
    topMostReference = @parent.topmostChildSuchThat (c) =>
      c != @ and (c instanceof WidgetHolderWithCaptionWdgt)
    if topMostReference?
      @parent.children.remove @
      index = @parent.children.indexOf topMostReference
      @parent.children.splice (index + 1), 0, @
    else
      @parent.children.remove @
      @parent.children.unshift @

