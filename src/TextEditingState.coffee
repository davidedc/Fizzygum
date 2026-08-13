# IMMUTABLE — an undo-history snapshot: fields are set at construction and never
# written again (see docs/architecture/immutable-value-classes.md).

class TextEditingState

  selectionStart: undefined
  selectionEnd: undefined
  cursorPos: undefined
  textContent: undefined
  isJustFirstClickToPositionCursor: undefined

  constructor: (@selectionStart, @selectionEnd, @cursorPos, @textContent, @isJustFirstClickToPositionCursor) ->
  
