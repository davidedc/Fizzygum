# sends a message to a target object when pressed.
# takes a rounded box shape, and can host
# a raster image

class SimpleRasterImageButtonWdgt extends SimpleButtonWdgt

  imagePath: nil
  imageWdgt: nil

  constructor: (
      @imagePath,
      target,
      action,
      argumentToAction1
      ) ->

    # additional properties:

    @imageWdgt = new SimpleImageWdgt @imagePath
    # TODO this is needed because SimpleImageWdgt extends CanvasWdgt which extends PanelWdgt
    # which actually implements the mouseClickLeft handler and doesn'e escalate it.
    # We hence hack this override to make it so the click is indeed escalated to the
    # parent i.e. the SimpleButtonWdgt.
    @imageWdgt.mouseClickLeft = (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
      @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

    super true, target, action, @imageWdgt, nil, nil, nil, nil, argumentToAction1,nil,nil,2
