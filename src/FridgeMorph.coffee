#| FridgeMorph //////////////////////////////////////////////////////////

class FridgeMorph extends FrameMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  tabs: []
  sourceCodeHolder: nil
  fridgeMagnetsCanvas: nil

  topMostMagnet: (setOfMorphs = @children) ->
    filtered = setOfMorphs.filter (m) ->
      m.putIntoWords? and !m.putIntoWords

    calculated = filtered.map (m) ->
      m.top()
    calcIndex = calculated.indexOf(Math.min(calculated...))
    if calcIndex == -1 then return nil

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
    if calcIndex == -1 then return nil
    return correctSide[calcIndex]

  # the magnet following another magnet is
  # not necessarily the closest magnet to the right
  # consider this case:
  #   |   |
  #   | A |
  #   |   | |   |
  #         | B |
  #    |   ||   |
  #    | C |
  #    |   |
  # 
  # A's closest magnet to the right is B, but it's not the
  # correct one, because B's closest magnet to the left is NOT A
  # (it's C).
  # So in order to find the correct magnet we need to verify
  # that they are reciprocally the closest ones.
  magnetFollowing: (aMagnet) ->
    correctHeight = @children.filter (m) ->
      m.putIntoWords? and !m.putIntoWords and
      (
        (m.bottom() >= aMagnet.top() and m.top() <= aMagnet.top()) or
        (m.top() <= aMagnet.bottom() and m.bottom() >= aMagnet.bottom())
      )
    
    correctSide = correctHeight.filter (m) ->
      m.left() > aMagnet.left()

    # distance from the magnet to all the magnets that are
    # about the same height and to the right
    calculated = correctSide.map (m) ->
      m.leftCenter().distanceTo(aMagnet.rightCenter())

    comparator = (arr) ->
      (a, b) ->
        if arr[a] < arr[b] then 1 else if arr[a] > arr[b] then -1 else 0

    # Sort by distance
    correctSide = correctSide.sort(comparator(calculated))

    # now we check each magnet K that could follow H. If we find that
    # K's distance with his left is smaller than K's distance with H
    # then K doesn't follow H and we need to check the
    # next one.
    # vice versa, if K's distance with his left is bigger, then indeed
    # K follows H so we stop the search and we are done.
    for eachMagnet in correctSide

      left = @magnetToLeftOf eachMagnet
      if !left? or left.rightCenter().distanceTo(eachMagnet.leftCenter()) > aMagnet.rightCenter().distanceTo(eachMagnet.leftCenter())
        return eachMagnet
    return nil


  # the idea is that we first find the top most one
  # and then we filter through the ones on the left
  # of it and we keep doing that recursively until
  # all the ones on the left are all COMPLETELY below
  # the top morph.
  topLeftMostMagnet: ->
    bag = @children.filter (m) ->
      m.putIntoWords? and !m.putIntoWords

    topMostMagnet = nil

    while bag.length > 0
      topMostMagnet = @topMostMagnet bag
      if !topMostMagnet? then return nil

      # filter through the ones on the left
      bag = bag.filter (m) ->
        m.left() < topMostMagnet.left()

      # check if all the ones on the left are
      # strictly below the topmost. If they are
      # then we are done
      notStrictlyBelow = bag.filter (m) ->
        m.top() < topMostMagnet.bottom()

      # if eliminating the ones on the left
      # and eliminating the ones strictly below
      # you remain with nothing, then the
      # search is over
      if notStrictlyBelow.length == 0
        break

    return topMostMagnet


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
        somethingToTheRight = @magnetFollowing currentTranslitteratedMagnet

      somethingBelow = @topLeftMostMagnet()

    return translitteration.trim()

  compileTiles: ->
   if @sourceCodeHolder?
      code = @putIntoWords()
      debugger
      @sourceCodeHolder.showCompiledCode code
      @fridgeMagnetsCanvas?.newGraphicsCode code


  reactToGrabOf: ->
    @compileTiles()

  reactToDropOf: ->
    @compileTiles() 
