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

  addOnOffSwitchLink: (theText, onShortcut, offShortcut, onAction, offAction) ->
    #aLittleDiv = document.createElement("div")
    
    aLittleSpan = document.createElement("span")
    aLittleSpan.innerHTML = theText + " "

    aLittleSpacerSpan = document.createElement("span")
    aLittleSpacerSpan.innerHTML = " "

    onLinkElement = document.createElement("a")
    onLinkElement.setAttribute "href", "#"
    onLinkElement.innerHTML = "on:"+onShortcut
    onLinkElement.onclick = onAction

    offLinkElement = document.createElement("a")
    offLinkElement.setAttribute "href", "#"
    offLinkElement.innerHTML = "off:"+offShortcut
    offLinkElement.onclick = offAction

    @SystemTestsControlPanelDiv.appendChild aLittleSpan
    @SystemTestsControlPanelDiv.appendChild onLinkElement
    @SystemTestsControlPanelDiv.appendChild aLittleSpacerSpan
    @SystemTestsControlPanelDiv.appendChild offLinkElement

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

    # The spirit of these links is that it would
    # be really inconvenient to trigger
    # these commands using menus during the test.
    # For example it would be inconvenient to stop
    # the tests recording by selecting the command
    # via e menu: a bunch of mouse actions would be
    # recorded, exposing as well to the risk of the
    # menu items changing.
    @addLink "alt+d: reset world", (-> window.world.systemTestsRecorderAndPlayer.resetWorld())
    @addOnOffSwitchLink "tie animations to test step", "alt+e", "alt+u", (-> window.world.systemTestsRecorderAndPlayer.turnOnAnimationsPacingControl()), (-> window.world.systemTestsRecorderAndPlayer.turnOffAnimationsPacingControl())
    @addOnOffSwitchLink "periodically align Morph IDs", "-", "-", (-> window.world.systemTestsRecorderAndPlayer.turnOnAlignmentOfMorphIDsMechanism()), (-> window.world.systemTestsRecorderAndPlayer.turnOffAlignmentOfMorphIDsMechanism())
    @addOnOffSwitchLink "hide Morph geometry in labels", "-", "-", (-> window.world.systemTestsRecorderAndPlayer.turnOnHidingOfMorphsGeometryInfoInLabels()), (-> window.world.systemTestsRecorderAndPlayer.turnOffHidingOfMorphsGeometryInfoInLabels())

    @addOnOffSwitchLink "hide Morph content extract in labels", "-", "-", (-> window.world.systemTestsRecorderAndPlayer.turnOnHidingOfMorphsContentExtractInLabels()), (-> window.world.systemTestsRecorderAndPlayer.turnOffHidingOfMorphsContentExtractInLabels())

    @addOnOffSwitchLink "hide Morph number ID in labels", "-", "-", (-> window.world.systemTestsRecorderAndPlayer.turnOnHidingOfMorphsNumberIDInLabels()), (-> window.world.systemTestsRecorderAndPlayer.turnOffHidingOfMorphsNumberIDInLabels())

    @addLink "alt+c: take screenshot", (-> window.world.systemTestsRecorderAndPlayer.takeScreenshot())
    @addLink "alt+k: check number of items in menu", (-> window.world.systemTestsRecorderAndPlayer.checkNumberOfItemsInMenu())
    @addLink "alt+m: add test comment", (-> window.world.systemTestsRecorderAndPlayer.addTestComment())
    @addLink "alt+t: stop test recording", (-> window.world.systemTestsRecorderAndPlayer.stopTestRecording())
    



    
