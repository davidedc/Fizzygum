# The TITLE role of naked text (Frame-model plan §5.B, owner decision D7): a
# SimpleTextWdgt whose construction bakes in the document-title style the
# templates window's "Title" building block carried inline -- centered, georgia
# stack, font size 48, editable + selecting. The class IS the role: hierarchy
# label "a Title", serialization/drop identity, and the one home for the style.

class TitleWdgt extends SimpleTextWdgt

  constructor: (text = "Title") ->
    super text, undefined, undefined, undefined, undefined, undefined, WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1
    @alignCenter()
    @setFontName undefined, undefined, @georgiaFontStack
    @setFontSize 48
    @isEditable = true
    @enableSelecting()
