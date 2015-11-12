# CanvasMorph //////////////////////////////////////////////////////////
# REQUIRES BackingStoreMixin
# 
# I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
# and event handling. 
# Also I always use a canvas to retain my graphical representation and respond
# to the HTML5 commands.
# 
# "container"/"contained" scenario going on.

class CanvasMorph extends FrameMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype
  @augmentWith BackingStoreMixin


  # Morph pen trails:
  penTrails: ->
    # answer my pen trails canvas. default is to answer my image
    # The implication is that by default every Morph in the system
    # (including the World) is able to act as turtle canvas and can
    # display pen trails.
    # BUT also this means that pen trails will be lost whenever
    # the trail's morph (the pen's parent) performs a "drawNew()"
    # operation. If you want to create your own pen trails canvas,
    # you may wish to modify its **penTrails()** property, so that
    # it keeps a separate offscreen canvas for pen trails
    # (and doesn't lose these on redraw).
    @image
  
  
  imBeingAddedTo: (newParentMorph) ->
