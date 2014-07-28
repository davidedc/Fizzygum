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
  constructor: () ->
    SystemTestsControlPanelDiv = document.createElement('div')
    SystemTestsControlPanelDiv.id = "SystemTestsControlPanel"
    SystemTestsControlPanelDiv.style.cssText = 'border: 1px solid green; overflow: hidden;'
    document.body.appendChild(SystemTestsControlPanelDiv)

    theCanvasDiv = document.getElementById('world')
    # one of these is for IE and the other one
    # for everybody else
    theCanvasDiv.style.styleFloat = 'left';
    theCanvasDiv.style.cssFloat = 'left';

    aTag = document.createElement("a")
    aTag.setAttribute "href", "yourlink.htm"
    aTag.innerHTML = "link text"
    SystemTestsControlPanelDiv.appendChild aTag


    
