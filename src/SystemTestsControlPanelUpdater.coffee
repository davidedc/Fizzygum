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

  @resetWorldLink: null
  @tieAnimations: null
  @alignMorphIDs: null
  @hideGeometry: null
  @hideMorphContentExtracts: null
  @hideMorphIDs: null
  @takeScreenshot: null
  @checkNumnberOfItems: null
  @checkMenuEntriesInOrder: null
  @checkMenuEntriesNotInOrder: null
  @addTestComment: null
  @runCommand: null
  @stopTestRec: null

  @highlightOnLink: (theElementName) ->
    theElement = document.getElementById(theElementName + "On")
    if theElement?
      theElement.style.backgroundColor = 'red'
    theElement = document.getElementById(theElementName + "Off")
    if theElement?
      theElement.style.backgroundColor = 'white'

  @highlightOffLink: (theElementName) ->
    theElement = document.getElementById(theElementName + "On")
    if theElement?
      theElement.style.backgroundColor = 'white'
    theElement = document.getElementById(theElementName + "Off")
    if theElement?
      theElement.style.backgroundColor = 'red'


  @addMessageToSystemTestsConsole: (theText) ->
    SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.innerHTML =
        SystemTestsControlPanelUpdater.SystemTestsControlPanelOutputConsoleDiv.innerHTML +
        theText + "</br>"

  @addMessageToTestCommentsConsole: (theText) ->
    SystemTestsControlPanelUpdater.SystemTestsControlPanelTestCommentsOutputConsoleDiv.innerHTML =
        SystemTestsControlPanelUpdater.SystemTestsControlPanelTestCommentsOutputConsoleDiv.innerHTML + theText + "</br>"

  @blinkLink: (theId) ->
    theElement = document.getElementById theId

    if theElement?
        theElement.style.backgroundColor = 'red'
        setTimeout \
          ->
            theElement.style.backgroundColor = 'white'
          , 100
        setTimeout \
          ->
            theElement.style.backgroundColor = 'red'
          , 200
        setTimeout \
          ->
            theElement.style.backgroundColor = 'white'
          , 300


  addLink: (theText, theFunction) ->
    aTag = document.createElement "a"
    linkID = theText.replace(/[^a-zA-Z0-9]/g, "")
    aTag.id = linkID
    aTag.setAttribute "href", "#"
    aTag.innerHTML = theText
    aTag.onclick = theFunction
    @SystemTestsControlPanelDiv.appendChild aTag
    br = document.createElement "br"
    @SystemTestsControlPanelDiv.appendChild br
    return linkID

  addOnOffSwitchLink: (theText, onShortcut, offShortcut, onAction, offAction) ->
    #aLittleDiv = document.createElement("div")
    
    linkID = theText.replace(/[^a-zA-Z0-9]/g, "")
    aLittleSpan = document.createElement "span"
    aLittleSpan.innerHTML = theText + " "

    aLittleSpacerSpan = document.createElement "span"
    aLittleSpacerSpan.innerHTML = " "

    onLinkElement = document.createElement "a"
    onLinkElement.setAttribute "href", "#"
    onLinkElement.innerHTML = "on:" + onShortcut
    onLinkElement.id = linkID + "On"
    onLinkElement.onclick = onAction

    offLinkElement = document.createElement "a"
    offLinkElement.setAttribute "href", "#"
    offLinkElement.innerHTML = "off:" + offShortcut
    offLinkElement.id = linkID + "Off"
    offLinkElement.onclick = offAction

    @SystemTestsControlPanelDiv.appendChild aLittleSpan
    @SystemTestsControlPanelDiv.appendChild onLinkElement
    @SystemTestsControlPanelDiv.appendChild aLittleSpacerSpan
    @SystemTestsControlPanelDiv.appendChild offLinkElement

    br = document.createElement "br"
    @SystemTestsControlPanelDiv.appendChild br
    return linkID

  addOutputPanel: (nameOfPanel, css) ->
    SystemTestsControlPanelUpdater[nameOfPanel] = document.createElement "div"
    SystemTestsControlPanelUpdater[nameOfPanel].id = nameOfPanel
    SystemTestsControlPanelUpdater[nameOfPanel].style.cssText = css
    document.body.appendChild(SystemTestsControlPanelUpdater[nameOfPanel])

  constructor: ->
    
    document.getElementById("world").style.top = "25px"

    @SystemTestsControlPanelDiv = document.createElement "div"
    @SystemTestsControlPanelDiv.id = "SystemTestsControlPanel"
    @SystemTestsControlPanelDiv.style.cssText =
        'border: 1px solid green; overflow: hidden; font-size: xx-small; top: 464px; left: 200px; position: absolute;'
    document.body.appendChild @SystemTestsControlPanelDiv

    @addOutputPanel "SystemTestsControlPanelOutputConsoleDiv",
        "height: 127px; width: 571px; border: 1px solid red; overflow-y: scroll; overflow-x: hidden; position: absolute; top: 464px; left: 386px;"
    @addOutputPanel "SystemTestsControlPanelTestCommentsOutputConsoleDiv",
        "height: 128px; border: 1px solid red; overflow-y: scroll; overflow-x: hidden;position: absolute;top: 592px;width: 757px;left: 200px;"

    theCanvasDiv = document.getElementById "world"
    # one of these is for IE and the other one
    # for everybody else
    theCanvasDiv.style.styleFloat = 'left'
    theCanvasDiv.style.cssFloat = 'left'

    # The spirit of these links is that it would
    # be really inconvenient to trigger
    # these commands using menus during the test.
    # For example it would be inconvenient to stop
    # the tests recording by selecting the command
    # via e menu: a bunch of mouse actions would be
    # recorded, exposing as well to the risk of the
    # menu items changing.
    SystemTestsControlPanelUpdater.resetWorldLink =
            @addLink "alt+d: reset world",
                (-> window.world.automatorRecorderAndPlayer.resetWorld())
    SystemTestsControlPanelUpdater.tieAnimations =
        @addOnOffSwitchLink "tie animations to test step",
            "alt+e",
            "alt+u",
            (-> window.world.automatorRecorderAndPlayer.turnOnAnimationsPacingControl()),
            (-> window.world.automatorRecorderAndPlayer.turnOffAnimationsPacingControl())
    SystemTestsControlPanelUpdater.alignMorphIDs =
        @addOnOffSwitchLink "periodically align Morph IDs",
            "-",
            "-",
            (-> window.world.automatorRecorderAndPlayer.turnOnAlignmentOfMorphIDsMechanism()),
            (-> window.world.automatorRecorderAndPlayer.turnOffAlignmentOfMorphIDsMechanism())
    SystemTestsControlPanelUpdater.hideGeometry =
        @addOnOffSwitchLink "hide Morph geometry in labels",
            "-",
            "-",
            (-> window.world.automatorRecorderAndPlayer.turnOnHidingOfMorphsGeometryInfoInLabels()), (-> window.world.automatorRecorderAndPlayer.turnOffHidingOfMorphsGeometryInfoInLabels())

    SystemTestsControlPanelUpdater.hideMorphContentExtracts =
        @addOnOffSwitchLink "hide Morph content extract in labels",
            "-",
            "-",
            (-> window.world.automatorRecorderAndPlayer.turnOnHidingOfMorphsContentExtractInLabels()), (-> window.world.automatorRecorderAndPlayer.turnOffHidingOfMorphsContentExtractInLabels())

    SystemTestsControlPanelUpdater.hideMorphIDs =
        @addOnOffSwitchLink "hide Morph number ID in labels",
            "-",
            "-",
            (-> window.world.automatorRecorderAndPlayer.turnOnHidingOfMorphsNumberIDInLabels()), (-> window.world.automatorRecorderAndPlayer.turnOffHidingOfMorphsNumberIDInLabels())

    SystemTestsControlPanelUpdater.takeScreenshot =
        @addLink "alt+c: take screenshot",
            (-> window.world.automatorRecorderAndPlayer.takeScreenshot())
    SystemTestsControlPanelUpdater.checkNumnberOfItems =
        @addLink "alt+k: check number of items in menu",
            (-> window.world.automatorRecorderAndPlayer.checkNumberOfItemsInMenu())
    SystemTestsControlPanelUpdater.checkMenuEntriesInOrder =
        @addLink "alt+a: check menu entries (in order)",
            (-> window.world.automatorRecorderAndPlayer.checkStringsOfItemsInMenuOrderImportant())
    SystemTestsControlPanelUpdater.checkMenuEntriesNotInOrder =
        @addLink "alt+z: check menu entries (any order)",
            (-> window.world.automatorRecorderAndPlayer.checkStringsOfItemsInMenuOrderUnimportant())
    SystemTestsControlPanelUpdater.addTestComment =
        @addLink "alt+m: add test comment",
            (-> window.world.automatorRecorderAndPlayer.addTestComment())
    SystemTestsControlPanelUpdater.runCommand =
        @addLink "run command",
            (-> window.world.automatorRecorderAndPlayer.runCommand())
    SystemTestsControlPanelUpdater.stopTestRec =
        @addLink "alt+t: stop test recording",
            (-> window.world.automatorRecorderAndPlayer.stopTestRecording())


    # add the div with the fake mouse pointer
    mousePointerIndicator = document.createElement "div"
    mousePointerIndicator.id = "mousePointerIndicator"
    mousePointerIndicator.style.cssText = 'position: absolute; display:none;'
    document.body.appendChild mousePointerIndicator
    elem = document.createElement "img"
    elem.setAttribute "src", "icons/xPointerImage.png"
    # this image is actually 160x160
    # to make sure it looks crisp on
    # higher-ppi displays
    elem.setAttribute "width", "40px"
    elem.setAttribute "height", "40px"
    document.getElementById("mousePointerIndicator").appendChild elem

    # add the div highlighting the state of the
    # left mouse button
    leftMouseButtonIndicator = document.createElement "div"
    leftMouseButtonIndicator.id = "leftMouseButtonIndicator"
    leftMouseButtonIndicator.style.cssText = 'position: absolute; left: 10px; top: 477px;'
    document.body.appendChild leftMouseButtonIndicator
    elem = document.createElement "img"
    elem.setAttribute "src", "icons/leftButtonPressed.png"
    document.getElementById("leftMouseButtonIndicator").appendChild elem
    fade 'leftMouseButtonIndicator', 1, 0, 10, new Date().getTime()

    # add the div highlighting the state of the
    # right mouse button
    rightMouseButtonIndicator = document.createElement "div"
    rightMouseButtonIndicator.id = "rightMouseButtonIndicator"
    rightMouseButtonIndicator.style.cssText = 'position: absolute; left: 10px; top: 477px;'
    document.body.appendChild rightMouseButtonIndicator
    elem = document.createElement "img"
    elem.setAttribute "src", "icons/rightButtonPressed.png"
    document.getElementById("rightMouseButtonIndicator").appendChild elem
    fade 'rightMouseButtonIndicator', 1, 0, 10, new Date().getTime()


    # ------------------------------------------------------
    # add the progress bar, which is made of two nested divs
    singleTestProgressBar = document.createElement "div"
    singleTestProgressBar.id = "singleTestProgressBar"
    singleTestProgressBar.style.cssText =
        'position: absolute; left: 20%; top: 0px; font-size: xx-large; font-family: sans-serif; width: 100%; height: 50px; background: rgb(173, 173, 173);'

    singleTestProgressBarWrap = document.createElement "div"
    singleTestProgressBarWrap.id = "singleTestProgressBarWrap"
    singleTestProgressBarWrap.style.cssText =
        'position: absolute; left: 5px; top: 5px; font-size: xx-large; font-family: sans-serif; width: 100px; height: 14px; overflow: hidden; background: rgb(0, 0, 0);'
    singleTestProgressBarWrap.appendChild(singleTestProgressBar)
    document.body.appendChild(singleTestProgressBarWrap)
    fade 'singleTestProgressBarWrap', 1, 0, 10, new Date().getTime()

    # add the div highlighting the percentage progress of the test
    singleTestProgressIndicator = document.createElement "div"
    singleTestProgressIndicator.id = "singleTestProgressIndicator"
    singleTestProgressIndicator.style.cssText =
        'position: absolute; left: 10px; top: 5px; font-size: 0.8em; font-family: sans-serif; color: white;'
    document.body.appendChild singleTestProgressIndicator
    fade 'singleTestProgressIndicator', 1, 0, 10, new Date().getTime()


    # ------------------------------------------------------
    # add the progress bar, which is made of two nested divs
    allTestsProgressBar = document.createElement "div"
    allTestsProgressBar.id = "allTestsProgressBar"
    allTestsProgressBar.style.cssText = 'position: absolute; left: 20%; top: 0px; font-size: xx-large; font-family: sans-serif; width: 100%; height: 50px; background: rgb(173, 173, 173);'

    allTestsProgressBarWrap = document.createElement "div"
    allTestsProgressBarWrap.id = "allTestsProgressBarWrap"
    allTestsProgressBarWrap.style.cssText = 'position: absolute; left: 110px; top: 5px; font-size: xx-large; font-family: sans-serif; width: 100px; height: 14px; overflow: hidden; background: rgb(0, 0, 0);'
    allTestsProgressBarWrap.appendChild(allTestsProgressBar)
    document.body.appendChild(allTestsProgressBarWrap)
    fade 'allTestsProgressBarWrap', 1, 0, 10, new Date().getTime()

    # add the div highlighting the percentage progress of the test
    allTestsProgressIndicator = document.createElement "div"
    allTestsProgressIndicator.id = "allTestsProgressIndicator"
    allTestsProgressIndicator.style.cssText = 'position: absolute; left: 115px; top: 5px; font-size: 0.8em; font-family: sans-serif; color: white;'
    document.body.appendChild(allTestsProgressIndicator)
    fade 'allTestsProgressIndicator', 1, 0, 10, new Date().getTime()


    # ------------------------------------------------------
    # add the div with title and description of the test
    testTitleAndDescription = document.createElement "div"
    testTitleAndDescription.id = "testTitleAndDescription"
    testTitleAndDescription.style.cssText = 'position: absolute; left: 0px; top: 25px; font-size: 1.5em; font-family: sans-serif; background-color: rgba(128, 128, 128, 1); width: 860px; height: 340px; padding: 50px; color: white;'
    document.body.appendChild(testTitleAndDescription)
    fade 'testTitleAndDescription', 1, 0, 10, new Date().getTime()
    #testTitleAndDescription.innerHTML = "Test asdasdasdasdasdakjhdasdasdasd"

    # ------------------------------------------------------
    # add the div highlighting the percentage progress of the test
    numberOfTestsDoneIndicator = document.createElement "div"
    numberOfTestsDoneIndicator.id = "numberOfTestsDoneIndicator"
    numberOfTestsDoneIndicator.style.cssText = 'position: absolute; left: 217px; top: 5px; font-size: 0.8em; font-family: sans-serif; color: black;'
    document.body.appendChild numberOfTestsDoneIndicator
    fade 'numberOfTestsDoneIndicator', 1, 0, 10, new Date().getTime()

    # ------------------------------------------------------
    # add the div highlighting the number of failed tests
    numberOfFailedTests = document.createElement "div"
    numberOfFailedTests.id = "numberOfFailedTests"
    numberOfFailedTests.style.cssText = 'position: absolute; left: 291px; top: 5px; font-size: 0.8em; font-family: sans-serif; color: black; text-decoration: underline; cursor:pointer;'
    document.body.appendChild(numberOfFailedTests)
    numberOfFailedTests.onclick = ->
        debugger
        world.automatorRecorderAndPlayer.saveFailedScreenshots()
    #fade('numberOfFailedTests', 1, 0, 10, new Date().getTime());
