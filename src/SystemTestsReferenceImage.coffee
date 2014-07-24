# Holds image data and metadata.
# These images are saved as javascript files
# and are used to test the actual rendering
# on screen (or parts of it)

# REQUIRES HashCalculator

class SystemTestsReferenceImage
  imageName: ''
  imageData: ''
  systemInfo: null
  hashOfData: 0
  hashOfSystemInfo: 0
  fileName = ''

  constructor: (@imageName, @imageData, @systemInfo) ->
    @hashOfData = HashCalculator.calculateHash(@imageData)
    @hashOfSystemInfo = HashCalculator.calculateHash(JSON.stringify(@systemInfo))

    # no extension added, cause we are going to
    # generate both png and js files
    @fileName = @imageName + "-systemInfoHash" + @hashOfSystemInfo + "-dataHash" + @hashOfData

