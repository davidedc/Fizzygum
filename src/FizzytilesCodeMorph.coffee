# FizzytilesCodeMorph ///////////////////////////////////////////////////////////


class FizzytilesCodeMorph extends TextMorph2
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  fridgeMagnetsCanvas: null


  showCompiledCode: (theTextContent) ->
    @setText theTextContent, null, true

  setText: (theTextContent, stringFieldMorph, skipCompilation) ->
    super
    if !skipCompilation?
      @fridgeMagnetsCanvas?.newGraphicsCode @text

