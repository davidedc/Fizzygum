
# This is meant to be used as a horizontal menu bar at the top or
# bottom of widgets. As such, it doesn't scroll its contents and
# it just hides entries that are "beyond" its width, tough
# luck for the content that doesn't fit...

class HorizontalMenuPanelWdgt extends PanelWdgt

  # TODO pretty sure that we don't need numberOfIconsOnPanel
  numberOfIconsOnPanel: 0
  internalPadding: 5
  thumbnailSize: 30

  constructor: ->
    super
    @rawSetExtent new Point 300,15

  add: (aMorph, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->

    if (aMorph instanceof ModifiedTextTriangleAnnotationWdgt) or
     (aMorph instanceof HandleMorph)
      super
    else
      aMorph.isTemplate = true
      if !aMorph.extentToGetWhenDraggedFromGlassBox?
        aMorph.extentToGetWhenDraggedFromGlassBox = aMorph.extent()

      if !(aMorph instanceof GlassBoxBottomWdgt)
        glassBoxBottom = new GlassBoxBottomWdgt()
        glassBoxBottom.add aMorph

        if !aMorph.actionableAsThumbnail
          glassBoxTop = new GlassBoxTopWdgt()
          glassBoxBottom.add glassBoxTop
          glassBoxTop.toolTipMessage = aMorph.toolTipMessage

        glassBoxBottom.fullRawMoveTo @topLeft().add new Point @internalPadding, @internalPadding
        if (aMorph instanceof MenuItemMorph)
          aMorph.shrinkToTextSize()
          glassBoxBottom.rawSetExtent new Point aMorph.width(), @thumbnailSize
        else
          glassBoxBottom.rawSetExtent new Point @thumbnailSize, @thumbnailSize
        glassBoxBottom.reLayout()

        aMorph = glassBoxBottom


      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      foundDrop = false

      if positionOnScreen? and childrenNotHandlesNorCarets.length > 0
        positionNumberAmongSiblings = 0

        for w in childrenNotHandlesNorCarets
          if w.bounds.growBy(@internalPadding).containsPoint positionOnScreen
            foundDrop = true
            if w.bounds.growBy(@internalPadding).rightHalf().containsPoint positionOnScreen
              positionNumberAmongSiblings++
            break
          positionNumberAmongSiblings++
      
      if foundDrop
        super aMorph, positionNumberAmongSiblings, layoutSpec, beingDropped
      else
        super aMorph, @numberOfIconsOnPanel, layoutSpec, beingDropped

      @numberOfIconsOnPanel++
      @reLayout()


  rawSetExtent: (aPoint) ->
    super
    @reLayout()

  reLayout: ->

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    widthOfContentsSoFar = @internalPadding
    countOfItems = 0

    for w in childrenNotHandlesNorCarets
      if widthOfContentsSoFar + @internalPadding  + w.width() > @width()
        break

      widthOfContentsSoFar += @internalPadding  + w.width()
      countOfItems++

    widthLayingDown = @internalPadding
    for i in [0...countOfItems]
      childrenNotHandlesNorCarets[i].unCollapse()
      startingPoint = @position().add new Point (@width() - widthOfContentsSoFar)/2, 0
      childrenNotHandlesNorCarets[i].fullRawMoveTo (startingPoint.add new Point widthLayingDown, (@height()-childrenNotHandlesNorCarets[i].height())/2).round()
      widthLayingDown += childrenNotHandlesNorCarets[i].width() + @internalPadding

    for i in [countOfItems...childrenNotHandlesNorCarets.length]
      childrenNotHandlesNorCarets[i].collapse()

    trackChanges.pop()
    @fullChanged()

