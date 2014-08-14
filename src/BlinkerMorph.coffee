# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text caret

class BlinkerMorph extends Morph
  constructor: (@fps = 2) ->
    super()
    @color = new Color(0, 0, 0)
    @updateRendering()
  
  # BlinkerMorph stepping:
  step: ->
    # if we are recording or playing a test
    # then there is a flag we need to check that allows
    # the world to control all the animations.
    # This is so there is a consistent check
    # when taking/comparing
    # screenshots.
    # So we check here that flag, and make the
    # caret to appear/disappear based on the
    # test step number, so user can control
    # exactly whether the caret is going to be
    # visible or invisible when recording/playing
    # the tests.
    if window.world.systemTestsRecorderAndPlayer.animationsTiedToTestCommandNumber
      if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.RECORDING
        if window.world.systemTestsRecorderAndPlayer.eventQueue.length % 2 == 0
          @minimise()
          return
        else
          @unminimise()
          return
      if SystemTestsRecorderAndPlayer.state == SystemTestsRecorderAndPlayer.PLAYING
        if window.world.systemTestsRecorderAndPlayer.indexOfQueuedEventBeingPlayed % 2 == 0
          @minimise()
          return
        else
          @unminimise()
          return
 
    # in all other cases just
    # do like usual, i.e. toggle
    # visibility at the fps
    # specified in the constructor.
    @toggleVisibility()
