# this file is excluded from the fizzygum homepage build

class EventCommand
  dateJSON: nil
  date: nil

  execute: ->

  constructor: ->
    @date = new Date
    @dateJSON = @date.toJSON()
