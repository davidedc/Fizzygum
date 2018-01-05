# FizzytilesCodeMorph ///////////////////////////////////////////////////////////


class FizzytilesCodeMorph extends TextMorph2

  fridgeMagnetsCanvas: nil


  showCompiledCode: (theTextContent) ->
    @setText theTextContent, nil, true

  setText: (theTextContent, stringFieldMorph, skipCompilation) ->
    super
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

