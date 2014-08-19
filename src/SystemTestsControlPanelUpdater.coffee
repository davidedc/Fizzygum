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

  @addMessageToSystemTestsConsole: (theText) ->
    SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.innerHTML = SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.innerHTML + theText + "</br>";

  @addMessageToTestCommentsConsole: (theText) ->
    SystemTestsControlPanelUpdater.SystemTestsControlPanelTestCommentsOutputConsoleDiv.innerHTML = SystemTestsControlPanelUpdater.SystemTestsControlPanelTestCommentsOutputConsoleDiv.innerHTML + theText + "</br>";

  addLink: (theText, theFunction) ->
    aTag = document.createElement("a")
    aTag.setAttribute "href", "#"
    aTag.innerHTML = theText
    aTag.onclick = theFunction
    @SystemTestsControlPanelDiv.appendChild aTag
    br = document.createElement('br')
    @SystemTestsControlPanelDiv.appendChild(br);

  addOutputPanel: (nameOfPanel) ->
    SystemTestsControlPanelUpdater[nameOfPanel] = document.createElement('div')
    SystemTestsControlPanelUpdater[nameOfPanel].id = nameOfPanel
    SystemTestsControlPanelUpdater[nameOfPanel].style.cssText = 'height: 150px; border: 1px solid red; overflow: hidden; overflow-y: scroll;'
    document.body.appendChild(SystemTestsControlPanelUpdater[nameOfPanel])

  constructor: ->
    @SystemTestsControlPanelDiv = document.createElement('div')
    @SystemTestsControlPanelDiv.id = "SystemTestsControlPanel"
    @SystemTestsControlPanelDiv.style.cssText = 'border: 1px solid green; overflow: hidden;'
    document.body.appendChild(@SystemTestsControlPanelDiv)

    @addOutputPanel "SystemTestsControlPanelOutputConsoleDiv"
    @addOutputPanel "SystemTestsControlPanelTestCommentsOutputConsoleDiv"

    theCanvasDiv = document.getElementById('world')
    # one of these is for IE and the other one
    # for everybody else
    theCanvasDiv.style.styleFloat = 'left';
    theCanvasDiv.style.cssFloat = 'left';

    @addLink "alt+n: start test recording", (-> window.world.systemTestsRecorderAndPlayer.startTestRecording())
    @addLink "alt+d: delete all morphs", (-> window.world.systemTestsRecorderAndPlayer.deleteAllMorphs())
    @addLink "alt+e: tie animations to test step", (-> window.world.systemTestsRecorderAndPlayer.tieAnimationsToTestCommandNumber())
    @addLink "alt+u: untie animation to test step", (-> window.world.systemTestsRecorderAndPlayer.untieAnimationsFromTestCommandNumber())
    @addLink "alt+c: take screenshot", (-> window.world.systemTestsRecorderAndPlayer.takeScreenshot())
    @addLink "alt+k: check number of items in menu", (-> window.world.systemTestsRecorderAndPlayer.checkNumberOfItemsInMenu())
    @addLink "alt+m: add test comment", (-> window.world.systemTestsRecorderAndPlayer.addTestComment())
    @addLink "alt+t: stop test recording", (-> window.world.systemTestsRecorderAndPlayer.stopTestRecording())
    @addLink "alt+p: replay recorded test", (-> window.world.systemTestsRecorderAndPlayer.startTestPlaying())
    @addLink "alt+s: save recorded test", (-> window.world.systemTestsRecorderAndPlayer.saveTest())
    @addLink "alt+f: save failed screenshots test", (-> window.world.systemTestsRecorderAndPlayer.saveFailedScreenshots())
    



    
