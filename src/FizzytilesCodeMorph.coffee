# FizzytilesCodeMorph ///////////////////////////////////////////////////////////


class FizzytilesCodeMorph extends TextMorph2
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  fridgeMagnetsCanvas: nil


  showCompiledCode: (theTextContent) ->
    @setText theTextContent, nil, true

  setText: (theTextContent, stringFieldMorph, skipCompilation) ->
    super
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

