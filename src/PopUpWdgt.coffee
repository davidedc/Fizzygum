# PopUp widgets are special Widgets that have quite complex logic for
# opening themselves, closing themseves when users click outside,
# popping up, opening sub-widgets, and pinning them down.
# They don't specify their own "look" (apart from shadowsn, see below),
# nor the contents or the look of the contents.
#
# PopUps have 3 different shadows: "normal", "when dragged" and
# "pinned on desktop", plus no shadow when pinned on anything
# else other than the desktop.

class PopUpWdgt extends Widget

  killThisPopUpIfClickOnDescendantsTriggers: true
  killThisPopUpIfClickOutsideDescendants: true
  isPopUpMarkedForClosure: false
  # the morphOpeningThePopUp is only useful to get the "parent" pop-up.
  # the "parent" pop-up is the menu that this menu is attached to,
  # but we need this extra property because it's not the
  # actual parent. The reason is that menus are actually attached
  # to the world morph. This is for a couple of reasons:
  # 1) they can still appear at the top even if the "parent menu"
  #    or the parent object are not in the foreground. This is
  #    what happens for example in OSX, you can right-click on a
  #    morph that is not in the background but the menu that comes up
  #    will be in the foreground.
  # 2) they can appear unoccluded if the "parent morph" or "parent object"
  #    are in a morph that clips at its boundaries.
  morphOpeningThePopUp: nil

  constructor: (@morphOpeningThePopUp, @killThisPopUpIfClickOutsideDescendants = true, @killThisPopUpIfClickOnDescendantsTriggers = true) ->
    super()
    @isLockingToPanels = false
    world.freshlyCreatedPopUps.add @
    world.openPopUps.add @

  hierarchyOfPopUps: ->
    ascendingWdgts = @
    hierarchy = new Set [ascendingWdgts]
    while ascendingWdgts?.getParentPopUp?
      ascendingWdgts = ascendingWdgts.getParentPopUp()
      if ascendingWdgts?
        hierarchy.add ascendingWdgts
    return hierarchy

  # for pop ups, the propagation happens through the getParentPopUp method
  # rather than the parent property, but for other normal widgets it goes
  # up the parent property
  propagateKillPopUps: ->
    if @killThisPopUpIfClickOnDescendantsTriggers
      @getParentPopUp()?.propagateKillPopUps()
      @markPopUpForClosure()

  markPopUpForClosure: ->
    world.popUpsMarkedForClosure.add @
    @isPopUpMarkedForClosure = true

  # why introduce a new flag when you can calculate
  # from existing flags?
  isPopUpPinned: ->
    return !(@killThisPopUpIfClickOnDescendantsTriggers or @killThisPopUpIfClickOutsideDescendants)

  getParentPopUp: ->
    if @isPopUpPinned()
      return @parent
    else
      if @morphOpeningThePopUp?
        return @morphOpeningThePopUp.firstParentThatIsAPopUp()
    return nil

  firstParentThatIsAPopUp: ->
    if !@isPopUpMarkedForClosure or !@parent? then return @
    return @parent.firstParentThatIsAPopUp()

  # this is invoked on the menu morph to be
  # pinned. The triggering menu item is the first
  # parameter.
  pinPopUp: (pinMenuItem)->
    @killThisPopUpIfClickOnDescendantsTriggers = false
    @killThisPopUpIfClickOutsideDescendants = false
    @onClickOutsideMeOrAnyOfMyChildren nil
    if pinMenuItem?
      pinMenuItem.firstParentThatIsAPopUp().propagateKillPopUps()
    else
      @getParentPopUp()?.propagateKillPopUps()
    world.closePopUpsMarkedForClosure()
    
    # leave the menu attached to whatever it's attached,
    # just change the shadow.
    @updatePopUpShadow()


  fullCopy: ->
    copiedMorph = super
    copiedMorph.onClickOutsideMeOrAnyOfMyChildren nil
    copiedMorph.killThisPopUpIfClickOnDescendantsTriggers = false
    copiedMorph.killThisPopUpIfClickOutsideDescendants = false
    return copiedMorph


  addMorphSpecificMenuEntries: (unused_morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    menu.addMenuItem "pin", false, @, "pin"
 
  justDropped: (whereIn) ->
    super
    if whereIn != world
      @pinPopUp()

    @updatePopUpShadow()

  updatePopUpShadow: ->
    if @isPopUpPinned()
      if @parent == world
        @addShadow()
      else
        @removeShadow()
    else 
      @addShadow()

  # shadow is added to a morph by
  # the ActivePointerWdgt while floatDragging
  addShadow: (offset = new Point(5, 5), alpha = 0.2, color) ->

    if @isPopUpPinned() and @parent == world
      super new Point(3, 3), 0.3
      return

    super offset, alpha
  
  popUpCenteredAtHand: (world) ->
    @popUp (world.hand.position().subtract @extent().floorDivideBy 2), world
  
  # »>> this part is excluded from the fizzygum homepage build
  # currently unused
  popUpCenteredInWorld: (world) ->
    @popUp (world.center().subtract @extent().floorDivideBy 2), world
  # this part is excluded from the fizzygum homepage build <<«

  popUpAtHand: ->
    @popUp world.hand.position(), world

  popUp: (pos, morphToAttachTo) ->
    # console.log "menu popup"
    @silentFullRawMoveTo pos
    morphToAttachTo.add @
    # the @fullRawMoveWithin method
    # needs to know the extent of the morph
    # so it must be called after the morphToAttachTo.add
    # method. If you call before, there is
    # nopainting happening and the morph doesn't
    # know its extent.
    @fullRawMoveWithin world
    if Automator and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()
    # shadow must be added after the morph
    # has been placed somewhere because
    # otherwise there is no visible image
    # to base the shadow on
    # P.S. this is the thing that causes the MenuMorph buffer
    # to be painted after the creation.
    @addShadow()
    @fullChanged()

  destroy: ->
    super()
    world.openPopUps.delete @

  close: ->
    super()
    world.openPopUps.delete @

