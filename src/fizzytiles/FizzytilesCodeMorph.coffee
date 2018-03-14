# this file is excluded from the fizzygum homepage build

class FizzytilesCodeMorph extends TextMorph2

  fridgeMagnetsCanvas: nil


  showCompiledCode: (theTextContent) ->
    @setText theTextContent, nil, nil, nil, true

  setText: (theTextContent, stringFieldMorph, connectionsCalculationToken, superCall, skipCompilation) ->
    super theTextContent, stringFieldMorph, connectionsCalculationToken, true
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

