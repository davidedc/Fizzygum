# Manages the controls of the System Tests
# e.g. all the links/buttons to trigger commands
# when recording tests such as
#  - start recording tests
#  - stop recording tests
#  - take screenshot
#  - save test files
#  - place the mouse over a morph with particular ID...


class SystemTestsControlPanelUpdater

  # Create the div where the controls will go
  # and make it float to the right of the canvas.
  # This requires tweaking the css of the canvas
  # as well.

  SystemTestsControlPanelDiv: null
  @SystemTestsControlPanelOutputConsoleDiv: null

  @addMessageToConsole: (theText) ->
    SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.innerHTML = SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.innerHTML + theText + "</br>";

  addLink: (theText, theFunction) ->
    aTag = document.createElement("a")
    aTag.setAttribute "href", "#"
    aTag.innerHTML = theText
    aTag.onclick = theFunction
    @SystemTestsControlPanelDiv.appendChild aTag
    br = document.createElement('br')
    @SystemTestsControlPanelDiv.appendChild(br);

  constructor: ->
    @SystemTestsControlPanelDiv = document.createElement('div')
    @SystemTestsControlPanelDiv.id = "SystemTestsControlPanel"
    @SystemTestsControlPanelDiv.style.cssText = 'border: 1px solid green; overflow: hidden;'
    document.body.appendChild(@SystemTestsControlPanelDiv)

    SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv = document.createElement('div')
    SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.id = "SystemTestsControlPanelOutputConsole"
    SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.style.cssText = 'height: 300px; border: 1px solid red; overflow: hidden;'
    document.body.appendChild(SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv)

    theCanvasDiv = document.getElementById('world')
    # one of these is for IE and the other one
    # for everybody else
    theCanvasDiv.style.styleFloat = 'left';
    theCanvasDiv.style.cssFloat = 'left';

    @addLink "command+n, ctrl+n: start test recording", (-> window.world.systemTestsRecorderAndPlayer.startTestRecording())
    @addLink "command+d, ctrl+d: delete all morphs", (-> window.world.systemTestsRecorderAndPlayer.deleteAllMorphs())
    @addLink "command+c, ctrl+c: take screenshot", (-> window.world.systemTestsRecorderAndPlayer.takeScreenshot())
    @addLink "command+t, ctrl+t: stop test recording", (-> window.world.systemTestsRecorderAndPlayer.stopTestRecording())
    @addLink "command+p, ctrl+p: replay recorded test", (-> window.world.systemTestsRecorderAndPlayer.startTestPlaying())
    @addLink "command+s, ctrl+s: save recorded test", (-> window.world.systemTestsRecorderAndPlayer.saveTest())
    @addLink "command+f, ctrl+f: save failed screenshots test", (-> window.world.systemTestsRecorderAndPlayer.saveFailedScreenshots())



    
