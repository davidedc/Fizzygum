# Holds image data and metadata.
# These images are saved as javascript files
# and are used to test the actual rendering
# on screen (or parts of it)

# REQUIRES HashCalculator

class SystemTestsReferenceImage
  imageName: ''
  # the image data as string, like
  # e.g. "data:image/png;base64,iVBORw0KGgoAA..."
  imageData: ''
  systemInfo: null
  hashOfData: 0
  hashOfSystemInfo: 0
  fileName = ''

  constructor: (@imageName, @imageData, @systemInfo) ->
    @hashOfData = HashCalculator.calculateHash(@imageData)
    @hashOfSystemInfo = HashCalculator.calculateHash(JSON.stringify(@systemInfo))

    # The filenames contain the test name and the image "number"
    # AND hashes of data and metadata. This is because the same
    # test/step might have different images for different
    # OSs/browsers, so they all must be different files.
    # The js files contain directly the code to load the image.
    # There can be multiple files for the same image, since
    # the images vary according to OS and Browser, so for
    # each image of each test there is an array of files.
    # No extension added, cause we are going to
    # generate both png and js files.
    @fileName = @imageName + "-systemInfoHash" + @hashOfSystemInfo + "-dataHash" + @hashOfData

  createJSContent: ->
  	  return "if (!AutomatorRecorderAndPlayer.loadedImages.hasOwnProperty('" + @imageName + "')) { " + "AutomatorRecorderAndPlayer.loadedImages." + @imageName + ' = []; } ' + "AutomatorRecorderAndPlayer.loadedImages." + @imageName + '.push(' + JSON.stringify(@) + ');'

  addToZipAsJS: (zip) ->
  	zip.file(
  	  @fileName + ".js",
  	  @createJSContent()
  	)

  # This method does the same of the one above
  # but it eliminates the "obtained-" text everywhere
  # in the content. In this way, the file can just
  # be renamed and can be added to the tests together
  # with all the other "good screenshots"
  # right away withouth having to open it and doing
  # the change manually.
  addToZipAsJSIgnoringItsAnObtained: (zip) ->
  	zip.file(
  	  @fileName + ".js",
  	  @createJSContent().replace(/obtained-/g,"")
  	)

  addToZipAsPNG: (zip) ->
    # the imageData string contains a little bit of string
    # that we need to strip out before the base64-encoded png data
    zip.file(
      @fileName + ".png",
      @imageData.replace(/^data:image\/png;base64,/, ""), {base64: true}
    )
