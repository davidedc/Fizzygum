class HhmmssLabelWdgt extends StringWdgt

  colloquialName: ->
    "HH:MM:SS label"

  # A clock label is a StringWdgt subclass, so (like any non-bare StringWdgt) Enter does
  # not 'accept' it -- it inserts a newline. Override of StringWdgt.enterKeyAccepts that
  # preserves the caret's old exact-class-name behaviour. (type-test-elimination campaign)
  enterKeyAccepts: ->
    false

  _formatTime: (time) ->
    hours = Math.floor(time / 3600)
    minutes = Math.floor((time - (hours * 3600)) / 60)
    seconds = Math.floor(time - (hours * 3600) - (minutes * 60))

    # return string in hh:mm:ss format. If hours are 0, omit them
    if hours > 0
      "#{hours.toString().padStart(2, '0')}:#{minutes.toString().padStart(2, '0')}:#{seconds.toString().padStart(2, '0')}"
    else
      "#{minutes.toString().padStart(2, '0')}:#{seconds.toString().padStart(2, '0')}"
