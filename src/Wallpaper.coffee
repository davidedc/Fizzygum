# Wallpaper — the desktop's wallpaper: the available background patterns, the
# currently-chosen one, applying a choice, and the menu to pick it. Lifted out
# of WorldWdgt as a plain delegated collaborator (the MacroToolkit pattern): the
# world HAS-A one, reachable as world.wallpaper, and DesktopAppearance paints the
# desktop by reading world.wallpaper.patternName / .pattern1..7. NB inside these
# methods `world.` is the live world GLOBAL, while `@` means this Wallpaper --
# so the picker menu items target `@` to reach this object's own setPattern.
# OO-backlog Phase 6 step 6a.3.
class Wallpaper

  pattern1: "plain"
  pattern2: "circles"
  pattern3: "vert. stripes"
  pattern4: "oblique stripes"
  pattern5: "dots"
  pattern6: "zigzag"
  pattern7: "bricks"
  patternName: undefined
  # world.wallpaper is a shared, per-world singleton: when something that refers to
  # it is deep-copied (e.g. duplicating a menu whose item targets it), the copy must
  # KEEP THE REFERENCE, not clone the wallpaper -- otherwise the copy's picker would
  # set a dead clone's pattern instead of the desktop's. This flag tells
  # the Duplicator to keep the reference (the way it already keeps external Widgets).
  keptByReferenceOnDeepCopy: true

  # Serialization: this per-world singleton is encoded symbolically as {"$wk":"wallpaper"}
  # and re-bound to the destination world's own wallpaper on restore. WellKnownObjects
  # matches it primarily by identity against world.wallpaper; this marker documents intent
  # and is the eventual replacement for keptByReferenceOnDeepCopy. See
  # docs/architecture/serialization-duplication-reference.md §4a.
  wellKnownKey: "wallpaper"

  constructor: ->
    @patternName = @pattern1

  # my seven patterns in menu order, as a list rather than seven hand-numbered call sites
  patternNames: ->
    [@pattern1, @pattern2, @pattern3, @pattern4, @pattern5, @pattern6, @pattern7]

  # what a reflecting menu row reads to decide whether it is the ticked one
  # (MenuRowReflectionSpec.readerName)
  currentPatternName: -> @patternName

  # ── dataflow node protocol ─────────────────────────────────────────────────────────────────
  # I am a NODE, and I need not be a Widget to be one — the protocol is duck-typed, exactly as
  # SecondsSource/FrameSource already prove. Being a node is what lets a menu row SUBSCRIBE to my
  # pattern instead of being fixed up by whoever happened to change it.
  dataflowValue: -> @patternName

  wallpapersMenu: (ignored,targetWidget)->
    menu = new MenuWdgt world, target: targetWidget, title: "Wallpapers"

    # Each row DECLARES that it shows my current pattern; the row is born with the right label and
    # re-derives it whenever I announce a change, in this menu and in every other open copy
    # (MenuItemWdgt._subscribeToMyReflectedSource). Nothing here indexes rows[1..7] any more —
    # that hand-numbering broke the day anyone added a divider.
    for patternName in @patternNames()
      menu.addMenuItem patternName, @, "setPatternFromMenu",
        arg1: patternName
        reflection: MenuRowReflectionSpec.tickWhen @, "currentPatternName", patternName, patternName

    menu.popUpAtHand()

  # menuItem is the OPTIONAL menu context (only setPatternFromMenu has one) and rides last,
  # where omitting it costs no caller an `undefined`.
  setPattern: (thePatternName, menuItem) ->
    if @patternName == thePatternName
      return

    @patternName = thePatternName
    # the world repaints its backdrop itself in this public notification (its
    # DesktopAppearance reads my patternName)
    world.noteWallpaperChanged()

    # ANNOUNCE the change: the drain then re-derives every subscribed menu row, wherever it is.
    # However my pattern changed — this menu, another open copy, a script, the loader — the ticks
    # follow, because they are views of this value rather than a redraw somebody remembered to do.
    world.dataflow.markStale @

  # THE MENU ADAPTER (see StringWdgt.setFontNameFromMenu for the shape): a menu action is
  # dispatched as `target[action].call target, dataSource, widgetEnv, arg1, arg2`, so the
  # picked pattern rides slot 3 and the item itself slot 1.
  setPatternFromMenu: (menuItem, ignored2, thePatternName) ->
    @setPattern thePatternName, menuItem


