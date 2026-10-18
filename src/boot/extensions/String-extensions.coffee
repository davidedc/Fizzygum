# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

if typeof String::isLetter == 'undefined'
  String::isLetter = ->
    @length == 1 && @match /[a-z]/i

if typeof String::getNthPositionInStringBeforeOrAfter == 'undefined'
  String::getNthPositionInStringBeforeOrAfter = (subString, occurrenceNumber = 1, after = true) ->
    position = @split(subString, occurrenceNumber).join(subString).length
    if after
      position += subString.length
    return position
