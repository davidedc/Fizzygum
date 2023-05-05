# just a minor cosmetic class: you construct this one keeping
# the image and video paths next to each other for clarity

class VideoThumbnailWdgt extends SimpleRasterImageButtonWdgt

  videoPath: nil

  constructor: (
      imagePath,
      @videoPath,
      target,
      action
      ) ->

    super imagePath, target, action, @videoPath

