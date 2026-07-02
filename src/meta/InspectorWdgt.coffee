class InspectorWdgt extends Widget

  target: nil
  currentProperty: nil
  markOwnershipOfProperties: true
  # panes:
  list: nil
  detail: nil

  classesButtons: nil
  classesNames: nil
  angledArrows: nil
  hierarchyHeaderString: nil
  propertyHeaderString: nil

  showMethodsOnButton: nil
  showMethodsOffButton: nil
  showMethodsToggle: nil

  showFieldsOnButton: nil
  showFieldsOffButton: nil
  showFieldsToggle: nil

  showInheritedOnButton: nil
  showInheritedOffButton: nil
  showInheritedToggle: nil

  showOwnPropsOnlyOnButton: nil
  showOwnPropsOnlyOffButton: nil
  showOwnPropsOnlyToggle: nil

  lastLabelInHierarchy: nil
  lastArrowInHierarchy: nil

  hierarchyBackgroundPanel: nil

  showingFields: true
  showingMethods: true
  showingInherited: false
  showingOwnPropsOnly: false

  addPropertyButton: nil
  renamePropertyButton: nil
  removePropertyButton: nil
  saveButton: nil
  saveTextWdgt: nil

  # opaque background appearance, painted ONLY while the inspector is
  # free-floating (naked); dropped while it is WindowWdgt content (the
  # window supplies the background) — see the constructor + setLayoutSpec
  inspectorBackgroundAppearance: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

  # normally buttons only contain centered lower case text
  # so we can get away with just no padding between button
  # bounds and text. Some of these buttons however contain
  # left-aligned class names (with capital letters) so we
  # do need to add some padding...
  classNamesTextPadding: 2

  colloquialName: ->
    "Object Inspector (" + @target.colloquialName() + ")"

  showFields: ->
    if !@showingFields
      @showingFields = true
      @_buildAndConnectChildren()

  showMethods: ->
    if !@showingMethods
      @showingMethods = true
      @_buildAndConnectChildren()

  showInherited: ->
    if !@showingInherited
      @showingInherited = true
      @_buildAndConnectChildren()

  showOwnPropsOnly: ->
    if !@showingOwnPropsOnly
      @showingOwnPropsOnly = true
      @_buildAndConnectChildren()

  hideFields: ->
    if @showingFields
      @showingFields = false
      @_buildAndConnectChildren()

  hideMethods: ->
    if @showingMethods
      @showingMethods = false
      @_buildAndConnectChildren()

  hideInherited: ->
    if @showingInherited
      @showingInherited = false
      @_buildAndConnectChildren()

  hideOwnPropsOnly: ->
    if @showingOwnPropsOnly
      @showingOwnPropsOnly = false
      @_buildAndConnectChildren()

  constructor: (@target) ->
    @classesButtons = []
    @classesNames = []
    @angledArrows = []
    super()

    # A naked (chrome-less) inspector must establish its OWN usable extent.
    # Without a WindowWdgt to size it, _reLayout would divide the Widget-default
    # ~50x40 across three panes and collapse them. The windowed path
    # (Widget::spawnInspector) overrides this via the window's setExtent, so
    # setting it here is windowed-pixel-neutral.
    @__commitExtent new Point 560, 410

    # When free-floating (naked on the desktop) the inspector paints its own
    # opaque background; inside a WindowWdgt the window supplies it. The
    # appearance is toggled off when the inspector becomes window content
    # (setLayoutSpec, below) so the windowed render stays byte-identical.
    @color = Color.create 248, 248, 248
    @inspectorBackgroundAppearance = new RectangularAppearance @
    @appearance = @inspectorBackgroundAppearance

    @_buildAndConnectChildren()

  # Paint our own opaque background ONLY when free-floating (naked); as
  # WindowWdgt content the window provides it, so drop the appearance then
  # (keeping the windowed inspector byte-identical). This mirrors how the
  # @resizer HandleWdgt shows only when free-floating — both are driven off
  # the same layout-spec change in Widget::setLayoutSpec.
  setLayoutSpec: (newLayoutSpec) ->
    super
    @appearance =
      if @isFreeFloating()
        @inspectorBackgroundAppearance
      else
        nil
  
  # CONVERT (end-of-cycle-flush-drawdown): a live inspector rebuild -- a property add/rename/remove, or a
  # show/hide toggle -- is a DISCRETE public mutation, so SELF-SETTLE it once, instead of the leading
  # fullDestroyChildren's _destroyNoSettle riding the per-frame end-of-cycle flush. SINGLE tier over a
  # non-settling core: the body's @add's are @_addNoSettle, so the multi-add rebuild does NOT re-enter the
  # flush per child -- they invalidate, and the ONE _settleLayoutsAfter flush at the end re-fits the COMPLETE
  # inspector. (No BATCH tier needed: the settle fires ONCE, AFTER the build, so there is no mid-build re-fit
  # of a half-wired child -- the mid-build re-fit crash a batch settler would guard against can't arise here.) At CONSTRUCTION
  # this is called last on an orphan -> _settleLayoutsAfter now SETTLES the orphan subtree synchronously
  # (orphan-settledness), so `new InspectorWdgt` returns settled; the single flush still runs over the
  # complete, fully-wired inspector.
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # subwidgets of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    attribs = []
    @classesButtons = []
    @classesNames = []
    @angledArrows = []

    # properties list. Note that this picks up ALL properties
    # (enumerable such as strings and un-enumerable such as functions)
    # of the whole prototype chain.
    #
    #   a) some of these are DECLARED as part of the class that defines the object
    #   and are proprietary to the object. These are shown RED
    # 
    #   b) some of these are proprietary to the object but are initialised by
    #   code higher in the prototype chain. These are shown GREEN
    #
    #   c) some of these are not proprietary, i.e. they belong to an object up
    #   the chain of prototypes. These are shown BLUE
    #
    # TODO show the static methods and variables in yet another color.
    
    for property of @target
      # dummy condition, to be refined
      attribs.push property  if property

    if !@showingMethods
      attribs = attribs.filter (prop) => !Utils.isFunction @target[prop]

    if !@showingFields
      attribs = attribs.filter (prop) => Utils.isFunction @target[prop]

    # if we don't show inherited props, then we let through two types of props (each side of the "or"
    # takes care of one type):
    #   1) the ones that are defined in the immediate class of the object (i.e. are own properties of the prototype)
    #   2) the ones that are just stitched to the object but are in none of the classes upwards i.e.
    #      are not a reachable property from the prototype
    if !@showingInherited
      attribs = attribs.filter (prop) => @target.constructor.prototype.hasOwnProperty(prop) or (prop not of @target.constructor.prototype)

    if @showingOwnPropsOnly
      attribs = attribs.filter (prop) => @target.hasOwnProperty(prop)


    # caches the own methods of the object
    if @markOwnershipOfProperties
      targetOwnMethods = Object.getOwnPropertyNames @target.constructor::
      #alert targetOwnMethods

    if @target?
      goingUpTargetProtChain = @target.__proto__
      while goingUpTargetProtChain.constructor.name != "Object"
        @classesNames.push goingUpTargetProtChain.constructor.name
        goingUpTargetProtChain = goingUpTargetProtChain.__proto__

    @hierarchyBackgroundPanel = new RectangleWdgt
    @hierarchyBackgroundPanel.setColor Color.create 255,255,255,.2
    @_addNoSettle @hierarchyBackgroundPanel

    counter = 0
    for eachNamedClass in @classesNames
      classButton = new SimpleButtonWdgt true, @, "openClassInspector", (new StringWdgt eachNamedClass, WorldWdgt.preferencesAndSettings.textInButtonsFontSize),nil,nil,nil,nil,eachNamedClass,nil,nil,@classNamesTextPadding
      @classesButtons.push classButton
      @_addNoSettle classButton

      # the top class doesn't get an arrow pointing upwards
      if counter > 0
        angledArrow = new AngledArrowUpLeftIconWdgt Color.BLACK
        @angledArrows.push angledArrow
        @_addNoSettle angledArrow

      counter++

    # single-line label; the layout below gives it a fixed 150×15 box, so it
    # needs no self-sizing — a StringWdgt fits "this object" left-aligned.
    @lastLabelInHierarchy = new StringWdgt "this object"
    @_addNoSettle @lastLabelInHierarchy
    @lastArrowInHierarchy = new AngledArrowUpLeftIconWdgt Color.BLACK
    @_addNoSettle @lastArrowInHierarchy

    @showMethodsOnButton = new SimpleButtonWdgt true, @, "hideMethods", "methods: on"
    @showMethodsOffButton = new SimpleButtonWdgt true, @, "showMethods", "methods: off"
    @showMethodsToggle = new ToggleButtonWdgt @showMethodsOnButton, @showMethodsOffButton, if @showingMethods then 0 else 1
    @_addNoSettle @showMethodsToggle

    @showFieldsOnButton = new SimpleButtonWdgt true, @, "hideFields", "fields: on"
    @showFieldsOffButton = new SimpleButtonWdgt true, @, "showFields", "fields: off"
    @showFieldsToggle = new ToggleButtonWdgt @showFieldsOnButton, @showFieldsOffButton, if @showingFields then 0 else 1
    @_addNoSettle @showFieldsToggle

    @showInheritedOnButton = new SimpleButtonWdgt true, @, "hideInherited", "inherited: on"
    @showInheritedOffButton = new SimpleButtonWdgt true, @, "showInherited", "inherited: off"
    @showInheritedToggle = new ToggleButtonWdgt @showInheritedOnButton, @showInheritedOffButton, if @showingInherited then 0 else 1
    @_addNoSettle @showInheritedToggle

    @buildAndConnectObjOwnPropsButton()

    @addPropertyButton = new SimpleButtonWdgt true, @, "addPropertyPopout", "add..."
    @_addNoSettle @addPropertyButton
    @renamePropertyButton = new SimpleButtonWdgt true, @, "renamePropertyPopout", "rename..."
    @_addNoSettle @renamePropertyButton
    @removePropertyButton = new SimpleButtonWdgt true, @, "removeProperty", "remove"
    @_addNoSettle @removePropertyButton

    @saveTextWdgt = (new StringWdgt "save", WorldWdgt.preferencesAndSettings.textInButtonsFontSize).alignCenter()
    @saveButton = new SimpleButtonWdgt true, @, "save", @saveTextWdgt
    @_addNoSettle @saveButton



    # open a new inspector, just on objects so
    # the idea is that you can view / change
    # its fields
    doubleClickAction = =>
      if !Utils.isObject @currentProperty
        return
      inspector = new @constructor @currentProperty
      inspector._applyMoveTo world.hand.position()
      inspector._moveWithin world
      world.add inspector
      inspector.changed()

    @list = new ListWdgt(
      @, # target
      "selectionFromList", #action
      (if @target instanceof Array then attribs else attribs.sort()), #elements
      nil, #labelGetter
      @filterProperties(targetOwnMethods), #format
      doubleClickAction #doubleClickAction
    )
    @list.disableDrops()

    # we know that the content of this list in this pane is not going to need the
    # step function, so we disable that from here by setting it to nil, which
    # prevents the recursion to children. We could have disabled that from the
    # constructor of MenuWdgt, but who knows, maybe someone might intend to use a MenuWdgt
    # with some animated content? We know that in this specific case it won't need animation so
    # we set that here. Note that the ListWdgt itself does require animation because of the
    # scrollbars, but the MenuWdgt (which contains the actual list contents)
    # in this context doesn't.
    world.steppingWdgts.delete @list.listContents
    @_addNoSettle @list

    # we add a Widget alignment here because adjusting IDs whenever
    # we add or remove methods is a pain...
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()


    # details pane
    @detail = new SimplePlainTextScrollPanelWdgt "", false, 5
    @detail.disableDrops()
    @detail.contents.disableDrops()
    @detail.color = Color.WHITE
    @detail.addModifiedContentIndicator()
    
    # when there is no selected item in the list
    # (for example when the inspector is started)
    # we need to manually remove the "modified" indicator
    # and disable the "save" button
    if !@list.selected?
      @detail.modifiedTextTriangleAnnotation?.hide()
      @saveTextWdgt.setColor Color.create 200, 200, 200

    # register this wdgt as one to be notified when the text
    # changes/unchanges from "reference" content
    # so we can enable/disable the "save" button
    @detail.widgetToBeNotifiedOfTextModificationChange = @

    @textWidget = @detail.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget._setFontNameNoSettle nil, nil, @textWidget.monoFontStack
    @textWidget.isEditable = false

    @_addNoSettle @detail



    @hierarchyHeaderString = new StringWdgt "Hierarchy", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @hierarchyHeaderString.toggleHeaderLine()
    @hierarchyHeaderString.alignCenter()
    @_addNoSettle @hierarchyHeaderString


    @propertyHeaderString = new StringWdgt "Properties", WorldWdgt.preferencesAndSettings.textInButtonsFontSize
    @propertyHeaderString.toggleHeaderLine()
    @propertyHeaderString.alignCenter()
    @_addNoSettle @propertyHeaderString

    # The inspector's own resize handle. It is shown ONLY when the inspector
    # is free-floating (naked on the desktop) and hidden when it is WindowWdgt
    # content (HandleWdgt::updateVisibility, driven by Widget::setLayoutSpec),
    # so a naked inspector is self-resizable while a windowed one defers to the
    # window's resizer. Covered by
    # SystemTest_macroNakedInspectorRendersResizesAndEdits.
    # Attach the resizer, then record it -- @resizer stays nil during its own add (byte-identical to the old
    # `@resizer = new HandleWdgt @`, whose in-constructor add ran while @resizer was still nil; see WindowWdgt).
    resizer = new HandleWdgt
    @_addNoSettle resizer, nil, resizer.defaultLayoutSpecWhenAddedTo(@)
    @resizer = resizer

    # update layout
    @_invalidateLayout()

  textContentModified: ->
    # TODO this would stand for enabling/disabling the button
    # but really we are just changing the color and the button
    # still works. Need some better enabling/disabling
    @saveTextWdgt.setColor Color.BLACK

  textContentUnmodified: ->
    # TODO this would stand for enabling/disabling the button
    # but really we are just changing the color and the button
    # still works. Need some better enabling/disabling
    @saveTextWdgt.setColor Color.create 200, 200, 200


  buildAndConnectObjOwnPropsButton: ->
    @showOwnPropsOnlyOnButton = new SimpleButtonWdgt true, @, "hideOwnPropsOnly", "obj own props only: on"
    @showOwnPropsOnlyOffButton = new SimpleButtonWdgt true, @, "showOwnPropsOnly", "obj own props only: off"
    @showOwnPropsOnlyToggle = new ToggleButtonWdgt @showOwnPropsOnlyOnButton, @showOwnPropsOnlyOffButton, if @showingOwnPropsOnly then 0 else 1
    @_addNoSettle @showOwnPropsOnlyToggle

  openClassInspector: (ignored,ignored2,className) ->
    classInspector = new ClassInspectorWdgt window[className].prototype
    world.openWindowWith classInspector, (new Point 560, 410), world.hand.position().subtract(new Point 50, 100)

  filterProperties: (targetOwnMethods)->
    if @markOwnershipOfProperties
      return [
        # give color criteria from the most general to the most specific
        [Color.create(0, 0, 180),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            true
        ],
        [Color.create(0, 180, 0),
          (element) =>
            # if the element is either an enumerable property of the object
            # or it belongs to the own methods, then it is highlighted.
            # Note that hasOwnProperty doesn't pick up non-enumerable properties such as
            # functions.
            # In theory, getOwnPropertyNames should give ALL the properties but the methods
            # are still not picked up, maybe because of the coffeescript construction system, I am not sure
            @target.constructor.prototype.hasOwnProperty(element)
        ]
      ]
    else
      return nil

  selectionFromList: (selected) ->
    if selected == undefined then return

    val = @target[selected]
    @currentProperty = val

    # functions should have a source somewhere
    # either in the object or in a superclass,
    # try to find it.
    if Utils.isFunction(val)
      if @target[selected + "_source"]?
          val = @target[selected + "_source"]
      else
        goingUpTargetProtChain = @target
        while goingUpTargetProtChain != Object
          if goingUpTargetProtChain.constructor.class.nonStaticPropertiesSources[selected]?
            val = goingUpTargetProtChain.constructor.class.nonStaticPropertiesSources[selected]
            break
          goingUpTargetProtChain = goingUpTargetProtChain.__proto__
      txt = val.toString()
    else
      # this is for finding the static variables
      if val is undefined
        val = @target.constructor[selected]
      
      if !val?
        txt = "nil"
      else if Utils.isString val
        txt = '"'+val+'"'
      else
        txt = val.toString()

    cnts = @detail.textWdgt
    cnts.setText txt
    cnts.setReceiver @target
    cnts.isEditable = true
    cnts.enableSelecting()
    cnts.considerCurrentTextAsReferenceText()
    @detail.checkIfTextContentWasModifiedFromTextAtStart()
  
  _reLayout: (newBoundsForThisLayout) ->

    if @_handleCollapsedStateShouldWeReturn() then return

    # Establish THIS layout pass's final bounds on OURSELVES first, before positioning the
    # children below. The base Widget::_reLayout (our `super` at the end) is what normally
    # applies newBoundsForThisLayout to @bounds — but we lay the children out manually from
    # @left()/@width()/@bottom() BEFORE calling super, so without this they'd be sized to the
    # PREVIOUS pass's extent and lag the inspector by one layout. During a resize that lag
    # equals the last drag STEP, whose size depends on how many frames the drag spanned — so
    # under variable cycle cadence (dpr2 + parallel test load) the centered headers + the
    # detail scrollbar settle to a nondeterministic 1px offset (the macroNakedInspector dpr2
    # flake). Applying the bounds here makes the child layout read the FINAL extent, so the
    # render is identical regardless of cadence. `super` re-applies the same bounds (idempotent).
    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
    @_applyMoveTo newBoundsForThisLayout.origin
    @_applyExtent newBoundsForThisLayout.extent()

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    headerBounds = new Rectangle new Point(Math.round(@left() + @externalPadding), Math.round(@top() + @externalPadding))
    headerBounds = headerBounds.setBoundsWidthAndHeight @width() - 2 * @externalPadding, 15
    @hierarchyHeaderString._reLayout headerBounds


    # classes diagram
    justAcounter = 0
    anotherCount = 0
    # reverse works in-place, so we need to remember
    # to put them back right after we are done
    @classesButtons.reverse()
    for eachClassButton in @classesButtons
      if eachClassButton.parent == @
        buttonBounds = new Rectangle new Point(Math.round(@left() + @externalPadding + @internalPadding + justAcounter), Math.round(@hierarchyHeaderString.bottom() + 2*@internalPadding + justAcounter))
        buttonBounds = buttonBounds.setBoundsWidthAndHeight 120 + @classNamesTextPadding * 2, 15 + @classNamesTextPadding * 2
        eachClassButton._reLayout buttonBounds

        # the top class doesn't get an arrow pointing upwards
        if anotherCount > 0
          if @angledArrows[anotherCount-1].parent == @
            @angledArrows[anotherCount-1]._applyMoveTo new Point(eachClassButton.left() - 15, Math.round(eachClassButton.top()))
            @angledArrows[anotherCount-1]._applyExtent new Point 15, 15

        justAcounter += 20

      anotherCount++
    @classesButtons.reverse()
    @layoutLastLabelInHierarchy Math.round(@left() + @externalPadding + @internalPadding + justAcounter), Math.round(@hierarchyHeaderString.bottom() + 2 * @internalPadding + justAcounter)

    @hierarchyBackgroundPanel._applyMoveTo new Point @left() + @externalPadding, @hierarchyHeaderString.bottom() + @internalPadding
    @hierarchyBackgroundPanel._applyExtent new Point @width() - 2 * @externalPadding, justAcounter + 20 + @internalPadding

    headerBounds = new Rectangle new Point @left() + @externalPadding , @hierarchyBackgroundPanel.bottom()+ @internalPadding
    headerBounds = headerBounds.setBoundsWidthAndHeight @width() - 2 * @externalPadding , 15
    @propertyHeaderString._reLayout headerBounds

    listWidth = Math.floor((@width() - 2 * @externalPadding - @internalPadding ) / 3)
    detailWidth = 2*listWidth

    @layoutOwnPropsOnlyToggle @propertyHeaderString.bottom() + @internalPadding, listWidth, detailWidth

    # list
    listHeight = (@bottom() - @externalPadding - @internalPadding - 15) - (@showMethodsToggle.bottom() + @internalPadding)
    if @list.parent == @
      @list._applyMoveTo new Point @left() + @externalPadding, @showMethodsToggle.bottom() + @internalPadding
      @list._applyExtent new Point listWidth, listHeight

    # detail
    if @detail.parent == @
      @detail._applyMoveTo new Point @list.right() + @internalPadding, @list.top()
      @detail._applyExtent (new Point detailWidth, listHeight).round()

    widthOfButtonsUnderList = Math.round((listWidth - 2 * @internalPadding)/3)

    buttonBounds = new Rectangle new Point @left() + @externalPadding, @bottom() - 15 - @externalPadding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight widthOfButtonsUnderList, 15
    @addPropertyButton._reLayout buttonBounds

    buttonBounds = new Rectangle new Point @addPropertyButton.right() + @internalPadding, @bottom() - 15 - @externalPadding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight widthOfButtonsUnderList, 15
    @renamePropertyButton._reLayout buttonBounds

    buttonBounds = new Rectangle new Point @renamePropertyButton.right() + @internalPadding, @bottom() - 15 - @externalPadding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight widthOfButtonsUnderList, 15
    @removePropertyButton._reLayout buttonBounds

    buttonBounds = new Rectangle new Point Math.round(@right() - @width()/4 - @externalPadding - @internalPadding - WorldWdgt.preferencesAndSettings.handleSize), @bottom() - 15 - @externalPadding
    buttonBounds = buttonBounds.setBoundsWidthAndHeight Math.round(@width()/4), 15
    @saveButton._reLayout buttonBounds

    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

  layoutOwnPropsOnlyToggle: (height, listWidth, detailWidth) ->
    # layout-apply-sanctioned: apply helper, runs under _reLayout (settle point)

    toggleBounds = new Rectangle new Point @left()+@externalPadding , height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (listWidth-@internalPadding)/ 2,15).round()
    @showMethodsToggle._reLayout toggleBounds

    toggleBounds = new Rectangle new Point @showMethodsToggle.right() + @internalPadding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (listWidth-@internalPadding)/ 2,15).round()
    @showFieldsToggle._reLayout toggleBounds
 
    toggleBounds = new Rectangle new Point @showFieldsToggle.right() + @internalPadding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (detailWidth-@internalPadding)/ 2,15).round()
    @showInheritedToggle._reLayout toggleBounds

    toggleBounds = new Rectangle new Point @showInheritedToggle.right() + @internalPadding, height
    toggleBounds = toggleBounds.setBoundsWidthAndHeight (new Point (detailWidth-@internalPadding)/ 2,15).round()
    @showOwnPropsOnlyToggle._reLayout toggleBounds


  layoutLastLabelInHierarchy: (posx, posy) ->
    if @lastLabelInHierarchy.parent == @
      @lastLabelInHierarchy._applyMoveTo new Point posx, posy
      @lastLabelInHierarchy._applyExtent new Point 150, 15

    if @lastArrowInHierarchy.parent == @
      @lastArrowInHierarchy._applyMoveTo new Point posx - 15, posy
      @lastArrowInHierarchy._applyExtent new Point 15, 15


  notifyInstancesOfSourceChange: (propertiesArray)->
    @target.sourceChanged()
  
  #InspectorWdgt editing ops:
  # Shared save scaffolding: object inspectors inject the property, class
  # inspectors evaluate an assignment — the only differing step is isolated in
  # the overridable applyPropertyEdit hook (ClassInspectorWdgt overrides it).
  save: ->
    if !@list.selected? then return
    txt = @detail.contents.children[0].text.toString()
    propertyName = @list.selected.labelString
    @applyPropertyEdit propertyName, txt

    @detail.textWdgt.considerCurrentTextAsReferenceText()
    @detail.checkIfTextContentWasModifiedFromTextAtStart()

    # it's possible that the user might have fixed
    # a "painting" error, so give another chance to all
    # "banned" widgets (banned from repainting)
    for eachWidget in world.widgetsGivingErrorWhileRepainting
      eachWidget.show()
    world.widgetsGivingErrorWhileRepainting = []

  # the one differing step between object- and class-inspector save: an object
  # inspector injects the property onto the instance (ClassInspectorWdgt
  # overrides this to evaluate an assignment against the class prototype).
  applyPropertyEdit: (propertyName, txt) ->
    # inject code will also break the layout and the widget
    @target.injectProperty propertyName, txt


  # TODO should have a removeProperty method in Widget (and in the classes somehow)
  # rather than here
  addProperty: (ignoringThis, widgetWithProperty) ->
    prop = widgetWithProperty.text.text
    if prop?
      if prop.getValue?
        prop = prop.getValue()
      @target[prop] = nil
      @_buildAndConnectChildren()
      @notifyInstancesOfSourceChange([prop])
  
  addPropertyPopout: ->
    @prompt "new property name:", @, "addProperty", "property" # Chrome cannot handle empty strings (others do)

  # TODO should have a removeProperty method in Widget (and in the classes somehow)
  # rather than here
  renameProperty: (ignoringThis, widgetWithProperty) ->
    propertyName = @list.selected.labelString
    prop = widgetWithProperty.text.text
    if prop.getValue?
      prop = prop.getValue()
    
    delete @target[propertyName]
    @target[prop] = @currentProperty

    @_buildAndConnectChildren()
    @notifyInstancesOfSourceChange([prop, propertyName])
  
  renamePropertyPopout: ->
    propertyName = @list.selected.labelString
    @prompt "property name:", @, "renameProperty", propertyName
  
  # TODO should have a removeProperty method in Widget (and in the classes somehow)
  # rather than here
  removeProperty: ->
    propertyName = @list.selected.labelString

    delete @target[propertyName]

    @currentProperty = nil
    @_buildAndConnectChildren()
    @notifyInstancesOfSourceChange([propertyName])
