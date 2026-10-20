# A tool whose pointer state shows on the CELL it stands in, never on itself: a toolbar's text tools
# (EditorContentPropertyChangerButtonWdgt), its creator buttons (CreatorButtonWdgt), its paint tools
# (CodeInjectingSimpleRectangularButtonWdgt) and the lid over a drag-out thumbnail (GlassBoxTopWdgt).
# It re-answers two of HighlightableMixin's hooks, so it is augmented AFTER that mixin (or onto a
# class that inherits it):
#   _updateColor   the hook every state transition calls once it has set @state: I write no colour
#                  of my own -- my glyph keeps its one ink -- and tell my parent cell my state moved;
#                  the cell re-derives its look from my state (GlassBoxBottomWdgt.noteItemStateChanged)
#                  and repaints itself, over me. A parent that is no cell answers nothing.
#   pressEnded     a release reaches me only when it ends the press that began on me with the
#                  pointer still over me (ActivePointerWdgt.processPointerUp), so I am hovered, not at
#                  rest: the pointer leaving me (hoverExited) is what brings the rest look back.
# Neither stores a colour, so a pointer visit always round-trips the cell to the pixels it had.

ParentStainerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

      _updateColor: ->
        @parent?.noteItemStateChanged?()

      pressEnded: ->
        @state = @STATE_HIGHLIGHTED
        @_updateColor()
