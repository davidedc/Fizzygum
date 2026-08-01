class ExternalLinkButtonWdgt extends IconWdgt

  createAppearance: -> new ExternalLinkIconAppearance @

  mouseClickLeft: ->
    # ask my containing link to open its URL (was `@parent instanceof SimpleLinkWdgt`
    # plus reaching into @parent.outputTextArea). (type-test-elimination campaign)
    @parent?.openExternalURL?()

  mouseEnter: ->
    world.worldCanvas.style.cursor = 'pointer'
  
  mouseLeave: ->
    world.worldCanvas.style.cursor = ''
