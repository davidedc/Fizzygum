# EqualSizeGridLayout

# this comment below is needed to figure our dependencies between classes
# REQUIRES Color
# REQUIRES Point
# REQUIRES Rectangle

# A Layout that simply makes a bunch of components equal in size and
# displays them in the requested number of rows and columns.
# This is somewhat similar to:
# https://docs.oracle.com/javase/tutorial/uiswing/layout/grid.html

class EqualSizeGridLayout extends LayoutMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  instanceVariableNames: 'rows columns hgap vgap'
  classVariableNames: ''
  poolDictionaries: ''

  rows: 0
  columns: 0
  hgap: 0
  vgap: 0

  constructor: ->
    super()
  
  defaultColor: ->
    return Color.transparent()

  # Compute a new layout based on the given layout bounds
  layoutSubmorphs: ->
    # ...
    @layoutNeeded = false


  addMorphs: (morphs) ->

  # unclear how to translate this one for the time being
  is: (aSymbol) ->
    return aSymbol == "#EqualSizeGridLayout" # or [ super is: aSymbol ]


