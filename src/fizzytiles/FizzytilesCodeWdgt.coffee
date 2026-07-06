# this file is excluded from the fizzygum homepage build

class FizzytilesCodeWdgt extends TextWdgt

  fridgeMagnetsCanvas: nil


  # compileTiles (my only caller, via FridgeWdgt's drop/grab gesture hooks) runs inside the gesture's
  # settle, so set the text through the NON-settling core (minus the now-redundant settle).
  showCompiledCode: (theTextContent) ->
    @_setTextNoSettle theTextContent

  setText: (theTextContent, stringFieldWidget, skipCompilation) ->
    super theTextContent, stringFieldWidget
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

