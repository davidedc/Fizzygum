# sends a message to a target object when pressed.
# takes a rounded box shape, and can host
# a raster image

class SimpleRasterImageButtonWdgt extends SimpleButtonWdgt

  imagePath: undefined
  imageWdgt: undefined

  # The image is my one operand; everything else is the button family's opts (`target:`,
  # `action:`, `arg1:`, …), to which I add my own face and padding.
  constructor: (@imagePath, opts = {}) ->

    # additional properties:

    @imageWdgt = new SimpleImageWdgt @imagePath
    # TODO this is needed because SimpleImageWdgt extends CanvasWdgt which extends PanelWdgt
    # which actually implements the activated handler and doesn'e escalate it.
    # We hence hack this override to make it so the click is indeed escalated to the
    # parent i.e. the SimpleButtonWdgt.
    @imageWdgt.activated = (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
      @escalateEvent "activated", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

    super Object.assign {}, opts, face: @imageWdgt, padding: 2
