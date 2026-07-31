class CFDegreesConverterIconAppearance extends DegreesConverterIconAppearance

  # Byte-for-byte the DegreesConverter icon except the little "degrees F" ring, which
  # this "°C <-> °F" variant tints a fixed grey. Sizes and the whole paintFunction
  # are inherited -- this used to be a ~230-line copy that differed by one fillStyle.
  _degreesSymbolFillStyle: ->
    'rgb(170, 170, 170)'
