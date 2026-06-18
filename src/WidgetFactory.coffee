# this file is excluded from the fizzygum homepage build
#
# WidgetFactory — the dev/demo "parts bin": builds the sample widgets offered by
# WorldWdgt's "make a widget" / "parts bin" demo menus and floats each on the
# hand. Lifted out of WorldWdgt as a plain delegated collaborator (the
# MacroToolkit pattern): the world HAS-A one, reachable as world.widgetFactory.
# This is all dev/demo scaffolding, hence the whole-file homepage exclusion
# above (and the guarded `if WidgetFactory?` construction in the WorldWdgt
# ctor). The widgets are floated via world.create, which STAYS on WorldWdgt as
# the shared pickUp helper (used widely, e.g. by MenusHelper). NB: inside these
# methods `world.` is the live world -- it was `@` when they lived on WorldWdgt.
# OO-backlog Phase 6 step 6a.2.
class WidgetFactory

  # world.widgetFactory is a shared, per-world singleton used as a menu-item target
  # (the demo menus). When a menu that targets it is duplicated, the copy must KEEP
  # THE REFERENCE, not clone the factory -- this flag tells DeepCopierMixin to do so
  # (the way it already keeps external Widgets). Without it, duplicating such a menu
  # would throw (the deep-copy hazard found in OO-backlog Phase 6 step 6a.3).
  keptByReferenceOnDeepCopy: true

  createNewStackElementsSizeAdjustingWdgt: ->
    world.create new StackElementsSizeAdjustingWdgt

  createNewLayoutElementAdderOrDropletWdgt: ->
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
    newWdgt.rawSetExtent new Point 350, 250
    world.create newWdgt
  createNewScrollPanelWdgt: ->
    newWdgt = new ScrollPanelWdgt
    newWdgt.adjustContentsBounds()
    newWdgt.adjustScrollBars()
    newWdgt.rawSetExtent new Point 350, 250
    world.create newWdgt
  createNewCanvas: ->
    newWdgt = new CanvasWdgt
    newWdgt.rawSetExtent new Point 350, 250
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
  createNewSpeechBubbleWdgt: ->
    newWdgt = new SpeechBubbleWdgt
    world.create newWdgt
  createNewToolTipWdgt: ->
    newWdgt = new ToolTipWdgt
    world.create newWdgt
  createNewGrayPaletteWdgt: ->
    world.create new GrayPaletteWdgt
  createNewColorPaletteWdgt: ->
    world.create new ColorPaletteWdgt
  createNewGrayPaletteWdgtInWindow: ->
    gP = new GrayPaletteWdgt
    wm = new WindowWdgt nil, nil, gP
    world.add wm
    wm.rawSetExtent new Point 130, 70
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
  createNewColorPaletteWdgtInWindow: ->
    cP = new ColorPaletteWdgt
    wm = new WindowWdgt nil, nil, cP
    world.add wm
    wm.rawSetExtent new Point 130, 100
    wm.fullRawMoveTo world.hand.position().subtract new Point 50, 100
  createNewColorPickerWdgt: ->
    world.create new ColorPickerWdgt
  createNewSensorDemo: ->
    newWdgt = new MouseSensorWdgt
    newWdgt.setColor Color.create 230, 200, 100
    newWdgt.cornerRadius = 35
    newWdgt.alpha = 0.2
    newWdgt.rawSetExtent new Point 100, 100
    world.create newWdgt
  createNewAnimationDemo: ->
    foo = new BouncerWdgt
    foo.fullRawMoveTo new Point 50, 20
    foo.rawSetExtent new Point 300, 200
    foo.alpha = 0.9
    foo.speed = 3
    bar = new BouncerWdgt
    bar.setColor Color.create 50, 50, 50
    bar.fullRawMoveTo new Point 80, 80
    bar.rawSetExtent new Point 80, 250
    bar.type = "horizontal"
    bar.direction = "right"
    bar.alpha = 0.9
    bar.speed = 5
    baz = new BouncerWdgt
    baz.setColor Color.create 20, 20, 20
    baz.fullRawMoveTo new Point 90, 140
    baz.rawSetExtent new Point 40, 30
    baz.type = "horizontal"
    baz.direction = "right"
    baz.speed = 3
    garply = new BouncerWdgt
    garply.setColor Color.create 200, 20, 20
    garply.fullRawMoveTo new Point 90, 140
    garply.rawSetExtent new Point 20, 20
    garply.type = "vertical"
    garply.direction = "up"
    garply.speed = 8
    fred = new BouncerWdgt
    fred.setColor Color.create 20, 200, 20
    fred.fullRawMoveTo new Point 120, 140
    fred.rawSetExtent new Point 20, 20
    fred.type = "vertical"
    fred.direction = "down"
    fred.speed = 4
    bar.add garply
    bar.add baz
    foo.add fred
    foo.add bar
    world.create foo
  createNewPenWdgt: ->
    world.create new PenWdgt
  underTheCarpet: ->
    newWdgt = new BasementWdgt
    world.create newWdgt
