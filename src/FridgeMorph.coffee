#| FridgeMorph //////////////////////////////////////////////////////////

class FridgeMorph extends FrameMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  tabs: []
  sourceCodeHolder: null
  codeCompiler: new CodeCompiler()

  topMostMagnet: ->
    filtered = @children.filter (m) ->
      m.putIntoWords? and !m.putIntoWords
    calculated = filtered.map (m) ->
      m.top()
    calcIndex = calculated.indexOf(Math.min(calculated...))
    if calcIndex == -1 then return null
    return filtered[calcIndex]

  magnetToLeftOf: (aMagnet) ->
    # first, filter all the morphs that are roughly at the same level
    # of the passed morph
    correctHeight = @children.filter (m) ->
      m.putIntoWords? and !m.putIntoWords and
      (
        (m.bottom() >= aMagnet.top() and m.top() <= aMagnet.top()) or
        (m.top() <= aMagnet.bottom() and m.bottom() >= aMagnet.bottom())
      )
    
    # then filter all the morphs that are on the left
    correctSide = correctHeight.filter (m) ->
      m.right() < aMagnet.right()

    # then pick the morph that minimises the distance of its right-center point
    # with the left-center point of the passed morph
    # (i.e. the "closest" morph to the left side)
    calculated = correctSide.map (m) ->
      m.rightCenter().distanceTo(aMagnet.leftCenter())
    calcIndex = calculated.indexOf(Math.min(calculated...))
    if calcIndex == -1 then return null
    return correctSide[calcIndex]

  # symmetric of magnetToLeftOf
  magnetToRightOf: (aMagnet) ->
    correctHeight = @children.filter (m) ->
      m.putIntoWords? and !m.putIntoWords and
      (
        (m.bottom() >= aMagnet.top() and m.top() <= aMagnet.top()) or
        (m.top() <= aMagnet.bottom() and m.bottom() >= aMagnet.bottom())
      )
    
    correctSide = correctHeight.filter (m) ->
      m.left() > aMagnet.left()

    calculated = correctSide.map (m) ->
      m.leftCenter().distanceTo(aMagnet.rightCenter())
    calcIndex = calculated.indexOf(Math.min(calculated...))
    if calcIndex == -1 then return null
    return correctSide[calcIndex]

  topLeftMostMagnet: ->
    topMostMagnet = @topMostMagnet()
    somethingToTheLeft = topMostMagnet

    while somethingToTheLeft
      topLeftMostMagnet = somethingToTheLeft
      somethingToTheLeft = @magnetToLeftOf topLeftMostMagnet

    return topLeftMostMagnet

  clearUpTranslitteratedFlags: ->
    for eachChild in @children
      if eachChild.putIntoWords?
        eachChild.putIntoWords = false

  putIntoWords: ->
    translitteration = ""
    tabs = []
    @clearUpTranslitteratedFlags()

    topLeftMostMagnet = @topLeftMostMagnet()
    somethingBelow = topLeftMostMagnet

    while somethingBelow
      # processing a new line
      topLeftMostMagnet = somethingBelow

      # finding out how many tabs
      validTabsMap = tabs.filter (t) ->
        Math.abs(t - topLeftMostMagnet.left()) < 15

      if validTabsMap.length == 0
        tabs.push topLeftMostMagnet.left()
        tabs.sort((a, b) -> a - b)
        howManyTabs = (tabs.indexOf topLeftMostMagnet.left())
      else
        howManyTabs = (tabs.indexOf validTabsMap[0])

      translitteration += "\n" + "  ".repeat(howManyTabs)

      # keep going to the right of the line
      somethingToTheRight = topLeftMostMagnet

      while somethingToTheRight
        currentTranslitteratedMagnet = somethingToTheRight
        translitteration += currentTranslitteratedMagnet.labelString + " "
        currentTranslitteratedMagnet.putIntoWords = true
        somethingToTheRight = @magnetToRightOf currentTranslitteratedMagnet

      somethingBelow = @topLeftMostMagnet()

    return translitteration.trim()

  compileTiles: ->
   if @sourceCodeHolder?
      cnts = new TextMorph @putIntoWords()
      cnts.isEditable = true
      cnts.enableSelecting()
      @sourceCodeHolder.setContents cnts, 2
      compiled = @codeCompiler.compileCode cnts.text
      console.log compiled
      console.log compiled.program
      @parent.visualOutput.graphicsCode = @codeCompiler.lastCorrectOutput.program


  reactToGrabOf: ->
    @compileTiles()

  reactToDropOf: ->
    @compileTiles() 
