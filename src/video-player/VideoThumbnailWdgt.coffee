# just a minor cosmetic class: you construct this one keeping
# the image and video paths next to each other for clarity

class VideoThumbnailWdgt extends SimpleRasterImageButtonWdgt

  videoPath: undefined

  # the two paths are my operands; the button family's opts (`target:`, `action:`) ride behind,
  # and the video path is what a press hands the action (`arg1:`)
  constructor: (imagePath, @videoPath, opts = {}) ->

    super imagePath, Object.assign {}, opts, arg1: @videoPath
  
  setThumbnailAndVideoPath: (thumbnailPath, videoPath) ->
    @imageWdgt.loadImage thumbnailPath
    @argumentToAction1 = videoPath
