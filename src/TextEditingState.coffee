# IMMUTABLE — an undo-history snapshot: fields are set at construction and never
# written again (see docs/architecture/immutable-value-classes.md).

class TextEditingState

  selectionStart: nil
  selectionEnd: nil
  cursorPos: nil
  textContent: nil
  isJustFirstClickToPositionCursor: nil

  constructor: (@selectionStart, @selectionEnd, @cursorPos, @textContent, @isJustFirstClickToPositionCursor) ->
  
