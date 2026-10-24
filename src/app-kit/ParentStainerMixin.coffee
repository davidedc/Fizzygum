# A tool whose pointer state shows on the CELL it stands in, never on itself: a toolbar's text tools
# (EditorContentPropertyChangerButtonWdgt), its creator buttons (CreatorButtonWdgt), its paint tools
# (CodeInjectingSimpleRectangularButtonWdgt) and the lid over a drag-out thumbnail (GlassBoxTopWdgt).
# It re-answers one of HighlightableMixin's hooks, so it is augmented AFTER that mixin (or onto a
# class that inherits it):
#   _updateColor   the hook every state transition calls once it has set @state: I write no colour
#                  of my own -- my glyph keeps its one ink -- and tell my parent cell my state moved;
#                  the cell re-derives its look from my state (GlassBoxBottomWdgt.noteItemStateChanged)
#                  and repaints itself, over me. A parent that is no cell answers nothing.
# It stores no colour, so a pointer visit always round-trips the cell to the pixels it had.

ParentStainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      _updateColor: ->
        @parent?.noteItemStateChanged?()
