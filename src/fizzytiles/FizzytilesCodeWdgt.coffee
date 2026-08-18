class FizzytilesCodeWdgt extends TextWdgt

  fridgeMagnetsCanvas: undefined


  # compileTiles (my only caller, via FridgeWdgt's drop/grab gesture hooks) runs inside the gesture's
  # settle, so set the text through the NON-settling core (minus the now-redundant settle).
  showCompiledCode: (theTextContent) ->
    @_setTextNoSettle theTextContent

  setText: (theTextContent) ->
    super theTextContent
    @fridgeMagnetsCanvas?.newGraphicsCode @text

