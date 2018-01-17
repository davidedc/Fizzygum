# SimpleScrollingVerticalStack ////////////////////////////////////////////////////

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class SimpleScrollingVerticalStack extends ScrollFrameMorph

  constructor: ->
    VS = new VerticalStackWdgt()
    VS.tight = false
    VS.isLockingToPanels = true
    super VS
    @disableDrops()
    @isTextLineWrapping = true
    @color = new Color 255, 255, 255

    ostmA = new TextMorph2BridgeForWrappingText(
      "A small string\n\n\nhere another.",nil,nil,nil,nil,nil,new Color(230, 230, 130), 1)
    ostmA.isEditable = true
    ostmA.enableSelecting()
    @setContents ostmA, 5

  lockAllChildern: ->
    @disableDrops()
    @contents.disableDrops()

    childrenNotHandlesNorCarets = @contents?.children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    if childrenNotHandlesNorCarets?
      for each in childrenNotHandlesNorCarets
        each.lockToPanels()
        if each.isEditable?
          each.isEditable = false

  unlockAllChildern: ->
    @enableDrops()
    @contents.enableDrops()

    childrenNotHandlesNorCarets = @contents?.children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    if childrenNotHandlesNorCarets?
      for each in childrenNotHandlesNorCarets
        each.unlockFromPanels()
        if each.isEditable?
          each.isEditable = true

  allSubMorphsAreLocked: ->
    childrenNotHandlesNorCarets = @contents?.children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    if !childrenNotHandlesNorCarets?
      return true

    if childrenNotHandlesNorCarets.length == 0
      return true

    notLocking = childrenNotHandlesNorCarets.filter (each) ->
      !each.isLockingToPanels

    if !notLocking?
      return false

    if notLocking.length != 0
      return false

    return true

  addMorphSpecificMenuEntries: (morphOpeningTheMenu, menu) ->
    super

    childrenNotHandlesNorCarets = @contents?.children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

    if childrenNotHandlesNorCarets? and childrenNotHandlesNorCarets.length > 0
      menu.addLine()
      if @allSubMorphsAreLocked()
        menu.addMenuItem "unlock content", true, @, "unlockAllChildern", "lets you drag content in and out"
      else
        menu.addMenuItem "lock content", true, @, "lockAllChildern", "prevents dragging content in and out"
