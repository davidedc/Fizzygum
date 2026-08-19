# THE window-with-panel product — ONE button, not a crop-vs-scroll fork at creation time
# (scroll-frame role plan P2): the body is a scroll frame at policy 'auto', which LOOKS like a
# plain cropping panel until content overflows, and whose menu can flip it to 'never' (a
# permanent crop) or back at any time. A separate cropping-panel product would be the same
# widget minus the ability to change your mind.

class WindowWithPanelCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "panel"

  createAppearance: -> new WindowWithScrollingPanelIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new ViewportWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm
