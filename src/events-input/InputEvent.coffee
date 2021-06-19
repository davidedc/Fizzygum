class InputEvent
  _isSynthetic: false

  markAsSynthetic: ->
    @_isSynthetic = true
    @
