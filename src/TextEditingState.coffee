class TextEditingState

  @augmentWith DeepCopierMixin

  selectionStart: nil
  selectionEnd: nil
  cursorPos: nil
  textContent: nil
  isJustFirstClickToPositionCursor: nil

  constructor: (@selectionStart, @selectionEnd, @cursorPos, @textContent, @isJustFirstClickToPositionCursor) ->
  
