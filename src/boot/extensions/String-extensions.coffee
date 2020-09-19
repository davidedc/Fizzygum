# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

tick = "✓ "
untick = "    "

if typeof String::isTicked == 'undefined'
  String::isTicked = ->
    @startsWith tick

if typeof String::tick == 'undefined'
  String::tick = ->
    if @isTicked()
      return @
    else if @isUnticked()
      return @toggleTick()
    else
      return tick + @

if typeof String::untick == 'undefined'
  String::untick = ->
    if @startsWith untick
      return @
    else if @isTicked()
      return @toggleTick()
    else
      return untick + @

if typeof String::isUnticked == 'undefined'
  String::isUnticked = ->
    return !@isTicked()

if typeof String::toggleTick == 'undefined'
  String::toggleTick = ->
    if @isTicked()
      return @replace tick, untick
    else if @startsWith untick
      return @replace untick, tick
    else
      return tick + @

if typeof String::isLetter == 'undefined'
  String::isLetter = ->
    @length == 1 && @match /[a-z]/i
