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

# my label without its tick decoration -- what a menu row IS, independently of what it currently
# SHOWS. A reflected row's prefix follows the value it displays, so anything that matches rows BY
# NAME (MenuRowsPanelWdgt.removeMenuItem) must compare undecorated or it matches only the spelling
# that happened to be on screen when it was written.
if typeof String::withoutTickDecoration == 'undefined'
  String::withoutTickDecoration = ->
    if @isTicked()
      return @slice tick.length
    else if @startsWith untick
      return @slice untick.length
    else
      return @toString()

if typeof String::isLetter == 'undefined'
  String::isLetter = ->
    @length == 1 && @match /[a-z]/i

if typeof String::getNthPositionInStringBeforeOrAfter == 'undefined'
  String::getNthPositionInStringBeforeOrAfter = (subString, occurrenceNumber = 1, after = true) ->
    position = @split(subString, occurrenceNumber).join(subString).length
    if after
      position += subString.length
    return position
