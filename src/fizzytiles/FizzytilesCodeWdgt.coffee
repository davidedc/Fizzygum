# this file is excluded from the fizzygum homepage build

class FizzytilesCodeWdgt extends TextWdgt

  fridgeMagnetsCanvas: nil


  showCompiledCode: (theTextContent) ->
    @setText theTextContent, nil, nil, nil, true

  setText: (theTextContent, stringFieldWidget, connectionsCalculationToken, superCall, skipCompilation) ->
    super theTextContent, stringFieldWidget, connectionsCalculationToken, true
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

