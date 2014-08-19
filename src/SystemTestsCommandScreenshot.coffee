#


class SystemTestsCommandScreenshot extends SystemTestsCommand
  screenShotImageName: null
  # The screenshot can be of the entire
  # world or of a particular morph (through
  # the "pic..." menu entry.
  # The screenshotTakenOfAParticularMorph flag
  # remembers which case we are in.
  # In the case that the screenshot is
  # of a particular morph, the comparison
  # will have to wait for the world
  # to provide the image data (the pic... command
  # will do it)
  screenshotTakenOfAParticularMorph: false
  @replayFunction: (systemTestsRecorderAndPlayer, commandBeingPlayed) ->
    systemTestsRecorderAndPlayer.compareScreenshots(commandBeingPlayed.screenShotImageName, commandBeingPlayed.screenshotTakenOfAParticularMorph)


  constructor: (@screenShotImageName, systemTestsRecorderAndPlayer, @screenshotTakenOfAParticularMorph = false ) ->
    super(systemTestsRecorderAndPlayer)
    # it's important that this is the same name of
    # the class cause we need to use the static method
    # replayFunction to replay the command
    @testCommandName = "SystemTestsCommandScreenshot"
