# Widgetic node class only cares about the
# parent/child connection between
# widgets. It's good to connect/disconnect
# widgets and to find parents or children
# who satisfy particular properties.
# OUT OF SCOPE:
# It's important to note that this layer
# knows nothing about visibility, targets,
# image buffers, dirty rectangles, events,
# position and extent (and hence bounds).
# Please no invocations to changed or fullChanged
# or updateBackBuffer in here, and no
# touching of any of the out-of-scope properties
# mentioned.

class TreeNode

  parent: nil
  # "children" is an ordered list of the immediate
  # children of this node. First child is at the
  # back relative to other children, last child is at the
  # top.
  #
  # The repaint mechanism in Fizzygum is back-to-front,
  # so first the "parent" widget is drawn, then the children,
  # where first child is re-painted first.
  #
  # The slight exception is the shadow, which, when it exists, is NOT
  # a child widget — it is a "property" object (@shadowInfo) rendered as
  # a pure drawing effect: a widget that has a shadow re-paints its WHOLE
  # subtree once, faintly and offset, FIRST (before the normal
  # back-to-front paint of itself + its children), so the shadow sits
  # behind everything. Widgets never bake a shadow into their own
  # back-buffer — this unified recursive re-paint is the only shadow
  # mechanism (see Widget.coffee "How the shadow painting works").
  #
  # This makes intuitive sense if you think for example
  # at a textWidget being added to a box widget: it is
  # added to the children list of the box widget, at the end,
  # and it's painted on top (otherwise it wouldn't be visible).
  #
  # Note that when you add a widget A to a widget B, it doesn't
  # mean that A is contained in B. The two potentially might
  # not even overlap.
  children: nil

  rootCache: nil
  rootCacheChecker: nil

  checkFirstParentClippingAtBoundsCache: nil
  cachedFirstParentClippingAtBounds: nil

  gcSessionIdMark: 0 # TODO unused
  gcReferenceExaminedSessionIdMark: 0

  constructor: (@parent = nil, @children = []) ->

  
  # TreeNode string representation: e.g. 'a TreeNode[3]'
  toString: ->
    if @children?
      childrenLength = @children.length
    else
      childrenLength = "-"
    "a TreeNode" + "[" + childrenLength + "]"

  # TreeNode accessing:
  addChild: (node, position = nil) ->
    WorldWdgt.noteStructureChange()
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    if !position?
      @children.push node
    else
      @children.splice position, 0, node
    node.parent = @
  
  isLastChild: ->
    if !@parent?
      return false

    # got a parent but I'm not one of the children
    idx = @parent.children.indexOf @
    if idx == -1
      return false

    # check if already last child
    # i.e. topmost
    if idx == @parent.children.length - 1
      return true
    return false


  # used from bringToForeground method
  # for example when you
  # click widgets around... they
  # pop to the foreground
  moveAsLastChild: ->
    return unless @parent?

    # got a parent but I'm not one of the children
    idx = @parent.children.indexOf @
    if idx == -1
      return

    # check if already last child
    # i.e. topmost
    if @isLastChild()
      return

    @parent.children.splice idx, 1
    @parent.children.push @
    @parent._reactToChildMovedToFront? @
    # whoever invoked this should probably
    # do a fullChanged() we don't do it
    # here because it seems like a lower-level
    # function calling a higher-level one.
  
  removeChild: (node) ->
    # remove the array element from the
    # array
    WorldWdgt.noteStructureChange()
    @invalidateFullBoundsCache @
    @invalidateFullClippedBoundsCache @
    @children.remove node
    node.parent = nil

  markReferenceAsVisited: (newGcSessionId) ->
    @gcReferenceExaminedSessionIdMark = newGcSessionId

  wasReferenceVisited: (newGcSessionId) ->
    @gcReferenceExaminedSessionIdMark == newGcSessionId

  markItAndItsParentsAsReachable: (newGcSessionId) ->
    @gcSessionId = newGcSessionId
    if @parent?
      if @parent.gcSessionId == newGcSessionId
        return
      if @isDirectlyInBasement()
        return
      @parent.markItAndItsParentsAsReachable newGcSessionId
  
  # is this Widget attached to neither the world nor to
  # the hand?
  isOrphan: ->
    root = @root()
    if root == world or root == world.hand
      return false
    return true

  # check if the widget is on its own in the basement
  # (rather than being part of a widget that is in the
  # basement)
  isDirectlyInBasement: ->
    @parent?.parent?.parent == world.basementWdgt

  # check if it's in the basement on its own or
  # as part of another widget.
  isInBasement: ->
    thereCouldBeOne = @allParentsBottomToTopSuchThat (eachWdgt) ->
      eachWdgt == world.basementWdgt
    return thereCouldBeOne.length == 1

  isInBasementButReachable: (newGcSessionId) ->
    if @gcSessionId == newGcSessionId
      return true
    if @parent.gcSessionId == newGcSessionId
      return true
    if @parent == world.basementWdgt
      return false
    return @parent.isInBasementButReachable newGcSessionId


  # TreeNode functions:
  SLOWroot: ->
    if @parent?
      return @parent.SLOWroot()
    else
      return @

  # TreeNode functions:
  root: ->
    if @rootCacheChecker == WorldWdgt.structureVersion
      result = @rootCache
    else
  
      theRoot = @
      if @parent?
        theRoot = @parent.root()

      @rootCacheChecker = WorldWdgt.structureVersion
      @rootCache = theRoot
      result = @rootCache

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWroot()
        debugger
        alert "root is broken"

    return result

  # returns the path of this widget in terms
  # of children positions relative to the world.
  # Meaning that if the widget is not attached to the
  # world or if it's attached to the hand, then
  # nil is returned.
  # Example: [0, 2, 1] means that this widget is
  # at
  #  world.children[0].children[2].children[1]
  pathOfChildrenPositionsRelativeToWorld: (pathSoFar) ->
    if !pathSoFar?
      pathSoFar =
        actualPath: []
        lengthOfChildrenArrays: []

    if @parent?
      pathSoFar.actualPath.push @parent.children.indexOf @
      pathSoFar.lengthOfChildrenArrays.push @parent.children.length
      @parent.pathOfChildrenPositionsRelativeToWorld pathSoFar
    else
      if @ == world
        pathSoFar.actualPath.reverse()
        pathSoFar.lengthOfChildrenArrays.reverse()
        return pathSoFar
      else
        return nil

  
  # »>> this part is excluded from the fizzygum homepage build
  # currently unused
  depth: ->
    return 0  unless @parent
    @parent.depth() + 1
  # this part is excluded from the fizzygum homepage build <<«
  
  # Returns all the internal AND terminal nodes in the subtree starting
  # at this node - including this node.
  # Remember that the @children property already sorts widgets
  # from bottom to top

  allChildrenBottomToTop: ->
    result = [@] # includes myself
    @children.forEach (child) ->
      result = result.concat child.allChildrenBottomToTop()
    result

  # the easiest way here would be to just return
  #   @allChildrenBottomToTop().shallowCopy().reverse()
  # but that's slower.
  # So we do the proper visit here instead.
  allChildrenTopToBottomSuchThat: (predicate) ->
    collected = []


    # if I have children, then start from the top
    # one (i.e. the last in the array) towards the bottom
    # one and concatenate their respective
    # top-to-bottom lists
    for widgetNumber in [@children.length-1..0] by -1
      widget = @children[widgetNumber]
      collected = collected.concat widget.allChildrenTopToBottomSuchThat predicate

    # base case: after we checked all the
    # children, we add ourselves to the last position
    # of the list since this node is at the bottom of all of
    # its children...
    if predicate.call nil, @
      collected.push @ # include myself

    return collected


  # A shorthand to run a function on all the internal/terminal nodes in the subtree
  # starting at this node - including this node.
  # Note that the function first runs on this node
  # (which is, when painted, the very bottom-est widget of them all)
  # and the proceeds by visiting the first child
  # which is the most "bottom" of the children
  # (i.e. when painted, the first child in the "children" array
  # and its children are painted just above the parent node)
  # and then recursively depth-first all its children
  # and then the second - bottomest child and children etc.
  # Also note that there is a more elegant implementation where
  # we just use @allChildrenBottomToTop() but that would mean to create
  # all the intermediary arrays with also all the unneeded node elements,
  # there is no need for that.
  # This is the simplest and cheapest way to visit all Widgets in
  # a tree of widgets.
  forAllChildrenBottomToTop: (aFunction) ->
    aFunction.call nil, @
    if @children.length
      @children.forEach (child) ->
        child.forAllChildrenBottomToTop aFunction
  
  # »>> this part is excluded from the fizzygum homepage build
  # currently unused
  allLeafsBottomToTop: ->
    if @children.length == 0
      return [@]
    result = []
    @children.forEach (child) ->
      result = result.concat child.allLeafsBottomToTop()
    return result
  # this part is excluded from the fizzygum homepage build <<«

  # Return all "parent" nodes from the root down to this node (including both)
  allParentsBottomToTop: ->
    if @parent?
      someParents = @parent.allParentsBottomToTop()
      someParents.push @
      return someParents
    else
      return [@]
  
  # Return all "parent" nodes from this node up to the root (including both)
  # Implementation commented-out below works but it's probably
  # slower than the one given, because concat is slower than pushing just
  # an array element, since concat does a shallow copy of both parts of
  # the array...
  #   allParentsTopToBottom: ->
  #    # includes myself
  #    result = [@]
  #    if @parent?
  #      result = result.concat(@parent.allParentsTopToBottom())
  #    result

  # Return all "parent" nodes from this note up to the root (including both)
  allParentsTopToBottom: ->
    return @allParentsBottomToTop().reverse()

  # this should be quicker than allParentsTopToBottomSuchThat
  # cause there are no concats making shallow copies.
  allParentsBottomToTopSuchThat: (predicate) ->
    result = []
    if @parent?
      result = @parent.allParentsBottomToTopSuchThat predicate
    if predicate.call(nil, @)
      result.push @
    result

  allParentsTopToBottomSuchThat: (predicate) ->
    collected = []
    if predicate.call nil, @
      collected = [@] # include myself
    if @parent?
      collected = collected.concat @parent.allParentsTopToBottomSuchThat predicate
    return collected

  # quicker version that doesn't need us
  # to create any intermediate arrays
  # but rather just loops up the chain
  # and lets us return as soon as
  # we find a match
  isAncestorOf: (widget) ->

    # »>> this part is excluded from the fizzygum homepage build
    if Automator? and !widget?
      # this happens when in a test, you select
      # a menu entry that doesn't exist.
      # so it's a good thing that we block the test
      # and let the user navigate through the world
      # to find the state of affairs that caused
      # the problem.
      console.log "failed to find widget in test: " + world.automator.name
      console.log "...the macro is looking for a widget/menu item that isn't present in the current world state"
      debugger
    # this part is excluded from the fizzygum homepage build <<«

    # test the widget itself
    if widget is @
      return true
    examinedWidget = widget
    # could use recursion, but
    # a loop will do too
    while examinedWidget.parent?
      examinedWidget = examinedWidget.parent
      if examinedWidget is @
        return true
    return false

  # »>> this part is excluded from the fizzygum homepage build
  # The direct children of the parent of this node. (current node not included)
  # never used in Fizzygum
  # There is an alternative solution here below, in comment,
  # but I believe to be slower because it requires applying a function to
  # all the children. My version below just required an array copy, then
  # finding an element and splicing it out. I didn't test it so I don't
  # even know whether it works, but gut feeling...
  #  siblings: ->
  #    return []  unless @parent
  #    @parent.children.filter (child) =>
  #      child isnt @
  #
  # currently unused
  siblings: ->
    return []  unless @parent
    siblings = @parent.children.shallowCopy()
    # now remove myself
    siblings.remove @
    return siblings

  amITheFirstSibling: ->
    if @parent.children[0] == @
      return true
    return false

  amITheLastSibling: ->
    if @parent.children[@parent.children.length - 1] == @
      return true
    return false

  positionAmongSiblings: ->
    theCount = 0
    for eachSibling in @parent.children
      if eachSibling == @
        return theCount
      theCount++

  siblingBeforeMeIsA: (theConstructor) ->
    if @amITheFirstSibling()
      return false
    if @parent.children[@positionAmongSiblings()-1] instanceof theConstructor
      return true
    return false

  siblingAfterMeIsA: (theConstructor) ->
    if @amITheLastSibling()
      return false
    if @parent.children[@positionAmongSiblings()+1] instanceof theConstructor
      return true
    return false
  # this part is excluded from the fizzygum homepage build <<«

  lastSiblingBeforeMeSuchThat: (predicate) ->
    theCount = 0
    indexOfWidget = nil
    for eachSibling in @parent.children
      if eachSibling == @
        break
      if predicate.call nil, eachSibling
        indexOfWidget = theCount
      theCount++

    if indexOfWidget?
      return @parent.children[indexOfWidget]
    else
      return nil

  firstSiblingAfterMeSuchThat: (predicate) ->
    searchActuallyOngoing = false
    for eachSibling in @parent.children
      if searchActuallyOngoing
        if predicate.call nil, eachSibling
          return eachSibling
      if eachSibling == @
        searchActuallyOngoing = true
    return nil

  childrenNotHandlesNorCarets: (whereToAct = @) ->
    whereToAct.children.filter (w) ->
      !w.isLayoutInert?()

  # find the nth child satisfying
  # a property.
  # This is used when finding
  # the nth buttons of a menu
  # having a particular label.
  # (so that we can say: automatically
  # click on the nth button labelled "X")
  nthChildSuchThat: (n, predicate) ->
    theCount = 0
    for w in @children
      if predicate.call nil, w
        theCount++
        if theCount is n
          return w
    return nil

  firstChildSuchThat: (predicate) ->
    @nthChildSuchThat 1, predicate

  SLOWfirstParentClippingAtBounds: (widgetToStartFrom = @) ->
    if widgetToStartFrom.parent?
      if widgetToStartFrom.parent.clipsAtRectangularBounds
        return widgetToStartFrom.parent
      else
        return widgetToStartFrom.parent.SLOWfirstParentClippingAtBounds()
    else
      return nil

  firstParentClippingAtBounds: ->
    if @checkFirstParentClippingAtBoundsCache == WorldWdgt.structureVersion
      if world.doubleCheckCachedMethodsResults
        if @cachedFirstParentClippingAtBounds != @SLOWfirstParentClippingAtBounds()
          debugger
          alert "firstParentClippingAtBounds is broken (cached)"
      return @cachedFirstParentClippingAtBounds

    if @parent?
      if @parent.clipsAtRectangularBounds
        result = @parent
      else
        result = @parent.firstParentClippingAtBounds()
    else
      result =  nil

    if world.doubleCheckCachedMethodsResults
      if result != @SLOWfirstParentClippingAtBounds()
        debugger
        alert "firstParentClippingAtBounds is broken (uncached)"

    @checkFirstParentClippingAtBoundsCache = WorldWdgt.structureVersion
    @cachedFirstParentClippingAtBounds = result


  
  # returns the first parent (going up from this node) that is of a particular class
  # (includes this particular node)
  # This is a subcase of "parentThatIsAnyOf".
  parentThatIsA: (constructors...) ->
    # including myself
    for eachConstructor in constructors
      if @ instanceof eachConstructor
        return [@, eachConstructor]
    return nil  unless @parent
    @parent.parentThatIsA constructors...

  # »>> this part is excluded from the fizzygum homepage build
  # checks whether the widget is a child,
  # directly or indirectly, of a specified
  # supposed ancestor widget
  # currently unused
  isADescendantOf: (theSupposedAncestorWidget) ->
    if @ == theSupposedAncestorWidget
      return true
    if !@parent?
      return false
    return @parent.isADescendantOf theSupposedAncestorWidget
  # this part is excluded from the fizzygum homepage build <<«
  

  # There would be another, simpler, implementation
  # which is also slower, where you first collect all
  # the children from top to bottom and then do the
  # test on each. But this is more efficient - we don't
  # need to create that entire list to start with, we
  # just navigate through the children arrays depth-first
  # (in reverse order though, see below)
  # and stop at the first widget that satisfies the test.
  topWdgtSuchThat: (predicate) ->
    # base case - I am a leaf child, so I just test
    # the predicate on myself and return myself
    # if I satisfy, else I return nil
    if @children.length == 0
      if predicate.call nil, @
        return @
      else
        return nil
    # if I have children, then start to test from
    # the top one (the last one in the array)
    # and proceed to test "towards the back" i.e.
    # testing elements of the array towards 0
    # If you find any widget satisfying, the search is
    # over.
    for widgetNumber in [@children.length-1..0] by -1
      widget = @children[widgetNumber]
      foundWidget = widget.topWdgtSuchThat predicate
      if foundWidget?
        return foundWidget
    # now that all children are tested, test myself
    if predicate.call nil, @
      return @

    # ok none of my children nor me test positive,
    # so return nil.
    return nil

  topmostChildSuchThat: (predicate) ->
    # start to test from
    # the top one (the last one in the array)
    # and proceed to test "towards the back" i.e.
    # testing elements of the array towards 0
    # If you find any child that satisfies, the search is
    # over.
    for widgetNumber in [@children.length-1..0] by -1
      widget = @children[widgetNumber]
      if predicate.call nil, widget
        return widget
    # ok none of my children test positive,
    # so return nil.
    return nil

  collectAllChildrenBottomToTopSuchThat: (predicate) ->
    collected = []
    if predicate.call(nil, @)
      collected = [@] # include myself
    @children.forEach (child) ->
      collected = collected.concat(child.collectAllChildrenBottomToTopSuchThat(predicate))
    return collected

