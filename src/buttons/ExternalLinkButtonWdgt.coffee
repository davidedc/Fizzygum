class ExternalLinkButtonWdgt extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new ExternalLinkIconAppearance @

  mouseClickLeft: ->
    if @parent? and (@parent instanceof SimpleLinkWdgt)
      window.open @parent.outputTextArea.text

  mouseEnter: ->
    world.worldCanvas.style.cursor = 'pointer'
  
  mouseLeave: ->
    world.worldCanvas.style.cursor = ''
