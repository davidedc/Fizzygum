#
# WidgetFactory — the dev/demo "parts bin": builds the sample widgets offered by
# WorldWdgt's "make a widget" / "parts bin" demo menus and floats each on the
# hand. Lifted out of WorldWdgt as a plain delegated collaborator (the
# MacroToolkit pattern): the world HAS-A one, reachable as world.widgetFactory.
# This is all dev/demo scaffolding, hence its own 'dev-tools' part (absent
# from the homepage/lean profiles) and the guarded `if WidgetFactory?`
# construction in the WorldWdgt ctor. The widgets are floated via
# world.create, which STAYS on WorldWdgt as
# the shared pickUp helper (used widely, e.g. by MenusHelper). NB: inside these
# methods `world.` is the live world -- it was `@` when they lived on WorldWdgt.
# OO-backlog Phase 6 step 6a.2.
class WidgetFactory

  # world.widgetFactory is a shared, per-world singleton used as a menu-item target
  # (the demo menus). When a menu that targets it is duplicated, the copy must KEEP
  # THE REFERENCE, not clone the factory -- this flag tells the Duplicator to do so
  # (the way it already keeps external Widgets). Without it, duplicating such a menu
  # would throw (the deep-copy hazard found in OO-backlog Phase 6 step 6a.3).
  keptByReferenceOnDeepCopy: true

  # Serialization: encoded symbolically as {"$wk":"widgetFactory"} and re-bound to the
  # destination world's factory on restore. See docs/architecture/serialization-duplication-reference.md
  # §4a. (This whole file is homepage-excluded, so the marker is absent in homepage builds
  # -- where there is no factory to resolve anyway.)
  wellKnownKey: "widgetFactory"

  createNewStackElementsSizeAdjustingWdgt: ->
    world.create new StackElementsSizeAdjustingWdgt

  # ⚠ the adder/droplet is the LAZY 'authoring' part — same eager->lazy shape as
  # createNewSpeechBubbleWdgt below, same fix (a guard would swallow the click).
  createNewLayoutElementAdderOrDropletWdgt: ->
    world.parts.whenAllLoaded ["authoring"], ->
      world.create new LayoutElementAdderOrDropletWdgt

  createNewRectangleWdgt: ->
    world.create new RectangleWdgt
  createNewBoxWdgt: ->
    world.create new BoxWdgt
  createNewCircleBoxWdgt: ->
    world.create new CircleBoxWdgt
  createNewSliderWdgt: ->
    world.create new SliderWdgt
  createNewPanelWdgt: ->
    newWdgt = new PanelWdgt
    newWdgt._applyExtent new Point 350, 250
    world.create newWdgt
  createNewScrollPanelWdgt: ->
    newWdgt = new ScrollPanelWdgt
    # layout-apply-sanctioned: construction-time dev factory (orphan, no cycle yet)
    newWdgt._positionAndResizeChildren()
    newWdgt._reLayoutScrollbars()
    newWdgt._applyExtent new Point 350, 250
    world.create newWdgt
  createNewCanvas: ->
    newWdgt = new CanvasWdgt
    newWdgt._applyExtent new Point 350, 250
    world.create newWdgt
  createNewHandle: ->
    world.create new HandleWdgt
  createNewString: ->
    newWdgt = new StringWdgt "Hello, World!"
    newWdgt.isEditable = true
    world.create newWdgt
  createNewText: ->
    newWdgt = new TextWdgt("Ich weiß nicht, was soll es bedeuten, dass ich so " +
      "traurig bin, ein Märchen aus uralten Zeiten, das " +
      "kommt mir nicht aus dem Sinn. Die Luft ist kühl " +
      "und es dunkelt, und ruhig fließt der Rhein; der " +
      "Gipfel des Berges funkelt im Abendsonnenschein. " +
      "Die schönste Jungfrau sitzet dort oben wunderbar, " +
      "ihr gold'nes Geschmeide blitzet, sie kämmt ihr " +
      "goldenes Haar, sie kämmt es mit goldenem Kamme, " +
      "und singt ein Lied dabei; das hat eine wundersame, " +
      "gewalt'ge Melodei. Den Schiffer im kleinen " +
      "Schiffe, ergreift es mit wildem Weh; er schaut " +
      "nicht die Felsenriffe, er schaut nur hinauf in " +
      "die Höh'. Ich glaube, die Wellen verschlingen " +
      "am Ende Schiffer und Kahn, und das hat mit ihrem " +
      "Singen, die Loreley getan.")
    newWdgt.isEditable = true
    # TextWdgt wraps to its own width via softWrap, like the
    # createNewTextWdgtWithBackground demo.
    world.create newWdgt
  # ⚠ SpeechBubbleWdgt is the LAZY 'app-kit' part (the shared base layer the app parts derive from),
  # and this class is the EAGER 'dev-tools' one -- the same eager->lazy shape as the two demo
  # factories below, and it takes the same fix. An `if SpeechBubbleWdgt?` guard would be the WRONG
  # one: it answers "is it here?" when the question is "get it here", so the menu click would be
  # silently swallowed instead of fetching the part.
  createNewSpeechBubbleWdgt: ->
    world.parts.whenAllLoaded ["app-kit"], ->
      newWdgt = new SpeechBubbleWdgt
      world.create newWdgt
  createNewToolTipWdgt: ->
    newWdgt = new ToolTipWdgt
    world.create newWdgt
  createNewGrayPaletteWdgt: ->
    world.create new GrayPaletteWdgt
  createNewColorPaletteWdgt: ->
    world.create new ColorPaletteWdgt
  # These two frame the palette AFTER world.add, so the window is already live and painted when it is
  # sized -- which makes this a public mutation, and a public mutator must SELF-SETTLE. A raw
  # _applyBounds here leaves the relayout on the end-of-cycle work list instead (the "careless push" the
  # capstone gate fails on); setBounds is the one-shot position+extent public form that flushes once.
  # (The siblings below bound their widget BEFORE adding it, where nothing is painted yet and the raw
  # core is correct.)
  createNewGrayPaletteWdgtInWindow: ->
    gP = new GrayPaletteWdgt
    wm = new FrameWdgt gP
    world.add wm
    wm.setBounds (world.hand.position().subtract new Point 50, 100), new Point 130, 70
  createNewColorPaletteWdgtInWindow: ->
    cP = new ColorPaletteWdgt
    wm = new FrameWdgt cP
    world.add wm
    wm.setBounds (world.hand.position().subtract new Point 50, 100), new Point 130, 100
  createNewColorPickerWdgt: ->
    world.create new ColorPickerWdgt
  # ⚠⚠ BouncerWdgt and PenWdgt are the LAZY 'demos' part, and this class is the EAGER 'dev-tools'
  # one -- a lazy requirement on an eager owner, which check-part-edges.js discounts entirely when
  # scanning these files (parts.json //requires): the await below is what satisfies the gate.
  # Both are reached from world menu -> 'demo ➜', which offers the items but loads
  # nothing, so without this await the click threw '<Class> is not defined' on index.html.
  # Awaiting here rather than at the menu door is deliberate: only these two factory methods want
  # the demo family, and the rest of that menu is core widgets that must stay instant.
  createNewAnimationDemo: ->
    world.parts.whenAllLoaded ["demos"], ->
      foo = new BouncerWdgt
      foo._applyBounds (new Point 50, 20), new Point 300, 200
      foo.alpha = 0.9
      foo.speed = 3
      bar = new BouncerWdgt
      bar.setColor Color.create 50, 50, 50
      bar._applyBounds (new Point 80, 80), new Point 80, 250
      bar.type = "horizontal"
      bar.direction = "right"
      bar.alpha = 0.9
      bar.speed = 5
      baz = new BouncerWdgt
      baz.setColor Color.create 20, 20, 20
      baz._applyBounds (new Point 90, 140), new Point 40, 30
      baz.type = "horizontal"
      baz.direction = "right"
      baz.speed = 3
      garply = new BouncerWdgt
      garply.setColor Color.create 200, 20, 20
      garply._applyBounds (new Point 90, 140), new Point 20, 20
      garply.type = "vertical"
      garply.direction = "up"
      garply.speed = 8
      fred = new BouncerWdgt
      fred.setColor Color.create 20, 200, 20
      fred._applyBounds (new Point 120, 140), new Point 20, 20
      fred.type = "vertical"
      fred.direction = "down"
      fred.speed = 4
      bar.add garply
      bar.add baz
      foo.add fred
      foo.add bar
      world.create foo
  createNewPenWdgt: ->
    world.parts.whenAllLoaded ["demos"], ->
      world.create new PenWdgt
  underTheCarpet: ->
    newWdgt = new BinWdgt
    world.create newWdgt

  # The layout-demo gallery builds LayoutSpacerWdgt springs, which live in the LAZY
  # 'authoring' part — whenAllLoaded's inline fast path keeps this SYNCHRONOUS when the
  # part is already in (the all-eager harness page), which the layout macros that call
  # setupTestScreen1 rely on.
  setupTestScreen1: ->
    world.parts.whenAllLoaded ["authoring"], =>

      ## draw some reference patterns to see the sizes

      for i in [0..5]
        lmHolder = new RectangleWdgt
        lmHolder.setBounds (new Point 10 + 60 * i, 10 + 50 * 0), new Point 10 + i*10,10 + i*10

        world.add lmHolder

      # ----------------------------------------------

      lmHolder = new RectangleWdgt
      lmContent1 = new RectangleWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt

      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20)
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 20,20), 2* DivisionStackLayoutSpec.SPREADABILITY_MEDIUM

      lmHolder.moveTo new Point 10 + 60 * 0, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

      # ----------------------------------------------

      lmHolder = new RectangleWdgt
      lmContent1 = new RectangleWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt

      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)

      lmHolder.moveTo new Point 10 + 60 * 1, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

      # ----------------------------------------------

      lmHolder = new RectangleWdgt
      lmContent1 = new RectangleWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt
      lmContent3 = new RectangleWdgt

      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      lmHolder.add lmContent3, nil, lmContent3._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE
      lmContent3.setColor Color.YELLOW

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
      lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)

      lmHolder.moveTo new Point 10 + 60 * 2, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

      # ----------------------------------------------

      lmHolder = new RectangleWdgt
      lmContent1 = new RectangleWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt
      lmAdj2 = new StackElementsSizeAdjustingWdgt
      lmContent3 = new RectangleWdgt

      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      lmHolder.add lmAdj2, nil, lmAdj2._ensureDivisionBox()
      lmHolder.add lmContent3, nil, lmContent3._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE
      lmContent3.setColor Color.YELLOW

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)
      lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 10,10) , (new Point 10,10)

      lmHolder.moveTo new Point 10 + 60 * 3, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

      # ----------------------------------------------

      lmHolder = new RectangleWdgt

      lmSpacer1 = new LayoutSpacerWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent1 = new RectangleWdgt
      lmAdj2 = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt
      lmAdj3 = new StackElementsSizeAdjustingWdgt
      lmContent3 = new RectangleWdgt
      lmAdj4 = new StackElementsSizeAdjustingWdgt
      lmSpacer2 = new LayoutSpacerWdgt

      lmHolder.add lmSpacer1, nil, lmSpacer1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj2, nil, lmAdj2._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      lmHolder.add lmAdj3, nil, lmAdj3._ensureDivisionBox()
      lmHolder.add lmContent3, nil, lmContent3._ensureDivisionBox()
      lmHolder.add lmAdj4, nil, lmAdj4._ensureDivisionBox()
      lmHolder.add lmSpacer2, nil, lmSpacer2._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE
      lmContent3.setColor Color.YELLOW

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
      lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)

      lmHolder.moveTo new Point 10 + 60 * 4, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

      # ----------------------------------------------

      lmHolder = new RectangleWdgt

      lmSpacer1 = new LayoutSpacerWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent1 = new RectangleWdgt
      lmAdj2 = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt
      lmAdj3 = new StackElementsSizeAdjustingWdgt
      lmContent3 = new RectangleWdgt
      lmAdj4 = new StackElementsSizeAdjustingWdgt
      lmSpacer2 = new LayoutSpacerWdgt 2

      lmHolder.add lmSpacer1, nil, lmSpacer1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj2, nil, lmAdj2._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      lmHolder.add lmAdj3, nil, lmAdj3._ensureDivisionBox()
      lmHolder.add lmContent3, nil, lmContent3._ensureDivisionBox()
      lmHolder.add lmAdj4, nil, lmAdj4._ensureDivisionBox()
      lmHolder.add lmSpacer2, nil, lmSpacer2._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE
      lmContent3.setColor Color.YELLOW

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)
      lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30)

      lmHolder.moveTo new Point 10 + 60 * 5, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

      # ----------------------------------------------

      lmHolder = new RectangleWdgt

      lmSpacer1 = new LayoutSpacerWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent1 = new RectangleWdgt
      lmAdj2 = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt
      lmAdj3 = new StackElementsSizeAdjustingWdgt
      lmContent3 = new RectangleWdgt
      lmAdj4 = new StackElementsSizeAdjustingWdgt
      lmSpacer2 = new LayoutSpacerWdgt 2

      lmHolder.add lmSpacer1, nil, lmSpacer1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj2, nil, lmAdj2._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      lmHolder.add lmAdj3, nil, lmAdj3._ensureDivisionBox()
      lmHolder.add lmContent3, nil, lmContent3._ensureDivisionBox()
      lmHolder.add lmAdj4, nil, lmAdj4._ensureDivisionBox()
      lmHolder.add lmSpacer2, nil, lmSpacer2._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE
      lmContent3.setColor Color.YELLOW

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 60,60), DivisionStackLayoutSpec.SPREADABILITY_NONE
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 60,60)
      lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 60,60), 2 * DivisionStackLayoutSpec.SPREADABILITY_MEDIUM

      lmHolder.moveTo new Point 10 + 60 * 6, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

      # ----------------------------------------------

      lmHolder = new RectangleWdgt

      lmSpacer1 = new LayoutSpacerWdgt
      lmAdj = new StackElementsSizeAdjustingWdgt
      lmContent1 = new RectangleWdgt
      lmAdj2 = new StackElementsSizeAdjustingWdgt
      lmContent2 = new RectangleWdgt
      lmAdj3 = new StackElementsSizeAdjustingWdgt
      lmContent3 = new RectangleWdgt
      lmAdj4 = new StackElementsSizeAdjustingWdgt
      lmSpacer2 = new LayoutSpacerWdgt 2

      lmHolder.add lmSpacer1, nil, lmSpacer1._ensureDivisionBox()
      lmHolder.add lmAdj, nil, lmAdj._ensureDivisionBox()
      lmHolder.add lmContent1, nil, lmContent1._ensureDivisionBox()
      lmHolder.add lmAdj2, nil, lmAdj2._ensureDivisionBox()
      lmHolder.add lmContent2, nil, lmContent2._ensureDivisionBox()
      lmHolder.add lmAdj3, nil, lmAdj3._ensureDivisionBox()
      lmHolder.add lmContent3, nil, lmContent3._ensureDivisionBox()
      lmHolder.add lmAdj4, nil, lmAdj4._ensureDivisionBox()
      lmHolder.add lmSpacer2, nil, lmSpacer2._ensureDivisionBox()
      
      lmContent1.setColor Color.LIME
      lmContent2.setColor Color.BLUE
      lmContent3.setColor Color.YELLOW

      lmContent1.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30), DivisionStackLayoutSpec.SPREADABILITY_NONE
      lmContent2.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30), DivisionStackLayoutSpec.SPREADABILITY_NONE
      lmContent3.setMinAndMaxBoundsAndSpreadability (new Point 30,30) , (new Point 30,30), DivisionStackLayoutSpec.SPREADABILITY_NONE

      lmHolder.moveTo new Point 10 + 60 * 7, 30 + 50 * 1

      world.add lmHolder
      lmHolder.add new HandleWdgt

  # The BORDER-LAYOUT scaffold (Swing's N/W-C-E/S) assembled by COMPOSITION — the layout
  # spec-family arc's design claim: no dedicated 5-region engine, just a vertical division
  # stack whose middle cell is a horizontal division row, with a divider at every seam.
  # The North/South/West/East bands are SPREADABILITY_NONE (near-fixed thickness); the
  # Center absorbs the spare space on both axes. Drop content into a region, drag the
  # dividers to re-apportion, or "edit layout" on a band to get drop-slots.
  createBorderLayoutScaffold: ->
    holder = new RectangleWdgt
    north = new RectangleWdgt
    vdiv1 = new StackElementsSizeAdjustingWdgt
    centerRow = new RectangleWdgt
    vdiv2 = new StackElementsSizeAdjustingWdgt
    south = new RectangleWdgt
    holder.add north, nil, north.divisionBox('y')
    holder.add vdiv1, nil, vdiv1.divisionBox('y')
    holder.add centerRow, nil, centerRow.divisionBox('y')
    holder.add vdiv2, nil, vdiv2.divisionBox('y')
    holder.add south, nil, south.divisionBox('y')
    north.setMinAndMaxBoundsAndSpreadability (new Point 40, 24), (new Point 60, 40), DivisionStackLayoutSpec.SPREADABILITY_NONE
    south.setMinAndMaxBoundsAndSpreadability (new Point 40, 24), (new Point 60, 40), DivisionStackLayoutSpec.SPREADABILITY_NONE
    west = new RectangleWdgt
    hdiv1 = new StackElementsSizeAdjustingWdgt
    center = new RectangleWdgt
    hdiv2 = new StackElementsSizeAdjustingWdgt
    east = new RectangleWdgt
    centerRow.add west, nil, west.divisionBox()
    centerRow.add hdiv1, nil, hdiv1.divisionBox()
    centerRow.add center, nil, center.divisionBox()
    centerRow.add hdiv2, nil, hdiv2.divisionBox()
    centerRow.add east, nil, east.divisionBox()
    west.setMinAndMaxBoundsAndSpreadability (new Point 30, 30), (new Point 50, 60), DivisionStackLayoutSpec.SPREADABILITY_NONE
    east.setMinAndMaxBoundsAndSpreadability (new Point 30, 30), (new Point 50, 60), DivisionStackLayoutSpec.SPREADABILITY_NONE
    for region in [north, south, west, east]
      region.setColor Color.create 235, 235, 235
    center.setColor Color.WHITE
    holder._applyExtent new Point 300, 300
    world.create holder
