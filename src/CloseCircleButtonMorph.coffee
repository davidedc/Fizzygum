# CloseCircleButtonMorph //////////////////////////////////////////////////////

# This is basically a circle with an x inside, it's for
# the little icon on the top left of a window, to close
# the window.
# TODO: this little widget doesn't scale well into
# touch mode.

class CloseCircleButtonMorph extends CircleBoxMorph

  constructor: (@orientation = "vertical") ->
    super()
  
  updateRendering: ->
    super()

    # TODO: this context has already been created
    # and used in the superclass, there is no
    # reason why we have to re-create another
    # one here. Ideally we wanto to save the
    # first one into an instance variable, and
    # just reuse it here.
    context = @image.getContext("2d")

    # Now stroke the "x" inside the circle button
    # that closes the window.
    context.beginPath()
    context.moveTo 3,3
    context.lineTo 7,7
    context.moveTo 7,3
    context.lineTo 3,7
    context.strokeStyle = '#000'
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
  