class HhmmssLabelWdgt extends StringMorph2

  colloquialName: ->
    "HH:MM:SS"

  _formatTime: (time) ->
    hours = Math.floor(time / 3600)
    minutes = Math.floor((time - (hours * 3600)) / 60)
    seconds = Math.floor(time - (hours * 3600) - (minutes * 60))

    # return string in hh:mm:ss format. If hours are 0, omit them
    if hours > 0
      "#{hours.toString().padStart(2, '0')}:#{minutes.toString().padStart(2, '0')}:#{seconds.toString().padStart(2, '0')}"
    else
      "#{minutes.toString().padStart(2, '0')}:#{seconds.toString().padStart(2, '0')}"
