# The pre-made-windows palette (floating home: WindowsToolbarCreatorButtonWdgt).

class WindowsToolbarWdgt extends ToolbarWdgt

  _toolbarItems: -> [
    new EmptyWindowCreatorButtonWdgt
    new WindowWithPanelCreatorButtonWdgt
    new WindowWithScrollPanelCreatorButtonWdgt
    new ElasticWindowCreatorButtonWdgt
  ]
