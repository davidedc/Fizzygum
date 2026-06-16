# this file is excluded from the fizzygum homepage build

class FizzytilesCodeWdgt extends TextWdgt

  fridgeMagnetsCanvas: nil


  showCompiledCode: (theTextContent) ->
    @setText theTextContent, nil, nil, nil, true

  setText: (theTextContent, stringFieldMorph, connectionsCalculationToken, superCall, skipCompilation) ->
    super theTextContent, stringFieldMorph, connectionsCalculationToken, true
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

