# Wallpaper — the desktop's wallpaper: the available background patterns, the
# currently-chosen one, applying a choice, and the menu to pick it. Lifted out
# of WorldWdgt as a plain delegated collaborator (the MacroToolkit pattern): the
# world HAS-A one, reachable as world.wallpaper, and DesktopAppearance paints the
# desktop by reading world.wallpaper.patternName / .pattern1..7. NB inside these
# methods `world.` is the live world (it was `@` when they lived on WorldWdgt),
# while `@` now means this Wallpaper -- so the picker menu items target `@` to
# reach this object's own setPattern. OO-backlog Phase 6 step 6a.3.
class Wallpaper

  pattern1: "plain"
  pattern2: "circles"
  pattern3: "vert. stripes"
  pattern4: "oblique stripes"
  pattern5: "dots"
  pattern6: "zigzag"
  pattern7: "bricks"
  patternName: nil
  # world.wallpaper is a shared, per-world singleton: when something that refers to
  # it is deep-copied (e.g. duplicating a menu whose item targets it), the copy must
  # KEEP THE REFERENCE, not clone the wallpaper -- otherwise the copy's picker would
  # set a dead clone's pattern instead of the desktop's. This flag tells
  # DeepCopierMixin to keep the reference (the way it already keeps external Widgets).
  keptByReferenceOnDeepCopy: true

  # Serialization: this per-world singleton is encoded symbolically as {"$wk":"wallpaper"}
  # and re-bound to the destination world's own wallpaper on restore. WellKnownObjects
  # matches it primarily by identity against world.wallpaper; this marker documents intent
  # and is the eventual replacement for keptByReferenceOnDeepCopy. See
  # docs/serialization-duplication-reference.md §4a.
  wellKnownKey: "wallpaper"

  constructor: ->
    @patternName = @pattern1

  wallpapersMenu: (a,targetWidget)->
    menu = new MenuWdgt world, target: targetWidget, title: "Wallpapers"

    # we add the "untick" prefix to all entries
    # so we allocate the right amount of space for
    # the labels, we are going to put the
    # right ticks soon after
    menu.addMenuItem untick + @pattern1, @, "setPattern", arg1: @pattern1
    menu.addMenuItem untick + @pattern2, @, "setPattern", arg1: @pattern2
    menu.addMenuItem untick + @pattern3, @, "setPattern", arg1: @pattern3
    menu.addMenuItem untick + @pattern4, @, "setPattern", arg1: @pattern4
    menu.addMenuItem untick + @pattern5, @, "setPattern", arg1: @pattern5
    menu.addMenuItem untick + @pattern6, @, "setPattern", arg1: @pattern6
    menu.addMenuItem untick + @pattern7, @, "setPattern", arg1: @pattern7

    @updatePatternsMenuEntriesTicks menu

    menu.popUpAtHand()

  setPattern: (menuItem, ignored2, thePatternName) ->
    if @patternName == thePatternName
      return

    @patternName = thePatternName
    world.changed()

    # was `menuItem.parent instanceof MenuWdgt` (type-test-elimination campaign)
    if menuItem?.parent? and menuItem.parent.isMenu?()
      @updatePatternsMenuEntriesTicks menuItem.parent


  # cheap way to keep menu consistency when pinned
  # note that there is no consistency in case
  # there are multiple copies of this menu changing
  # the wallpaper, since there is no real subscription
  # of a menu to react to wallpaper change coming
  # from other menus or other means (e.g. API)...
  updatePatternsMenuEntriesTicks: (menu) ->
    pattern1Tick = pattern2Tick = pattern3Tick =
    pattern4Tick = pattern5Tick = pattern6Tick =
    pattern7Tick = untick

    switch @patternName
      when @pattern1
        pattern1Tick = tick
      when @pattern2
        pattern2Tick = tick
      when @pattern3
        pattern3Tick = tick
      when @pattern4
        pattern4Tick = tick
      when @pattern5
        pattern5Tick = tick
      when @pattern6
        pattern6Tick = tick
      when @pattern7
        pattern7Tick = tick

    menu.children[1].label.setText pattern1Tick + @pattern1
    menu.children[2].label.setText pattern2Tick + @pattern2
    menu.children[3].label.setText pattern3Tick + @pattern3
    menu.children[4].label.setText pattern4Tick + @pattern4
    menu.children[5].label.setText pattern5Tick + @pattern5
    menu.children[6].label.setText pattern6Tick + @pattern6
    menu.children[7].label.setText pattern7Tick + @pattern7
