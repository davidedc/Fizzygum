# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

# this wraps the functionality of the
# SimpleVerticalStackScrollPanelWdgt into something that has
# a more human name. Also provides additional document-oriented
# features such as "increase/decrease size" etc.

class SimpleDocumentScrollPanelWdgt extends SimpleVerticalStackScrollPanelWdgt

  colloquialName: ->
    "document"
