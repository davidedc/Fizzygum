# Holds image data and metadata.
# These images are saved as javascript files
# and are used to test the actual rendering
# on screen (or parts of it)

class SystemTestsReferenceImage
  imageName: ''
  imageData: ''

  constructor: (@imageName,@imageData) ->

