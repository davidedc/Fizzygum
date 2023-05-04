# sends a message to a target object when pressed.
# takes a rounded box shape, and can host
# a raster image

class SimpleRasterImageButtonWdgt extends SimpleButtonMorph

  imagePath: nil

  constructor: (
      @imagePath,
      target,
      action
      ) ->

    # additional properties:

    rasterImageWdgt = new RasterImageWdgt @imagePath
    # TODO this is needed because RasterImageWdgt extends CanvasMorph which extends PanelWdgt
    # which actually implements the mouseClickLeft handler and doesn'e escalate it.
    # We hence hack this override to make it so the click is indeed escalated to the
    # parent i.e. the SimpleButtonMorph.
    rasterImageWdgt.mouseClickLeft = (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
      @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

    super true, target, action, rasterImageWdgt
    # TODO is there a setPadding method?
    @padding = 2
