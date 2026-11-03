# The pre-made-windows toolbar (floating home: WindowsToolbarCreatorButtonWdgt).

class WindowsToolbarWdgt extends ToolbarWdgt

  _toolbarItems: -> [
    new EmptyWindowCreatorButtonWdgt
    new WindowWithPanelCreatorButtonWdgt
    new ElasticWindowCreatorButtonWdgt
  ]
