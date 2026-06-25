# this file is excluded from the fizzygum homepage build

class FizzytilesCodeWdgt extends TextWdgt

  fridgeMagnetsCanvas: nil


  # compileTiles (my only caller, via FridgeWdgt's drop/grab gesture hooks) runs inside the gesture's
  # settle, so set the text through the NON-settling core. Mirrors the old self-settling path
  # (setText superCall:true, skipCompilation:true = a fresh connection token + _setTextNoSettle) minus
  # the now-redundant settle.
  showCompiledCode: (theTextContent) ->
    @connectionsCalculationToken = world.makeNewConnectionsCalculationToken()
    @_setTextNoSettle theTextContent

  setText: (theTextContent, stringFieldWidget, connectionsCalculationToken, superCall, skipCompilation) ->
    super theTextContent, stringFieldWidget, connectionsCalculationToken, true
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

