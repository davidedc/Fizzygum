# A TOOL CELL: the square a toolbar's tool stands in (ToolPanelWdgt wraps every tool it is given in
# one), which is also the larger target a thumbnail is grabbed by. It holds the tool -- its ITEM, its
# first child -- and, over a tool that is there only to be dragged out (not actionableAsThumbnail),
# the LID a press lands on (GlassBoxTopWdgt).
#
# MY LOOK is my tool's state and nothing else, every value a Theme role or metric (the draft's tool
# button): a square rounded at toolCellCornerRadius with no border; no fill at rest, so the glyph
# stands alone on whatever the strip stands on; toolCellHoverFill while my tool is hovered,
# toolCellPressedFill while it is pressed, toolCellActiveFill while it is the ACTIVE tool (hovered or
# not; pressed shows pressed). While my tool has NOTHING TO ACT ON (a property tool handed no subject
# that offers its verb) I am DIMMED: no fill in any pointer state -- the disabled look every control
# wears, hover and press dropped with it -- and my tool's glyph re-inks itself in toolbarGlyphDimmed,
# asking me (EditorContentPropertyChangerButtonWdgt._fillForMyState), so my fill and its ink come
# from one answer. The pointer state is the hand's answer about the widget a press on me reaches
# (thumbnailClickReceiver: the lid, or the tool itself), when that widget is a tool that lights its
# cell (lightsAToolCell); whether my tool is active, and whether it has something to act on, are its
# own answers (isActiveTool, hasSomethingToActOn: capabilities, so a tool that is never active, or
# never dims -- a creator, a paint tool --, need not answer). The look is read from these as I am
# painted (_fillForMyState), and repainted when I am told one moved (noteItemStateChanged): by the
# tool whose pointer state moved (every tool family and the lid say so as the hand tells them), and
# by the toolbar I stand in when which tool is active, or which has
# something to act on, may have moved (ToolbarWdgt.noteToolStatesChanged: the selection, its style
# or its mode moved, a paint tool's holder changed its tool, or the toolbar docked or left). No tool
# pushes a colour onto me, and I keep none, so no family can leave one behind.
#
# MY TOOL IS CUT TO MY OUTLINE: it lies flush in my square, so I paint my children inside my rounded
# outline, and a press in one of my corner notches reaches neither me nor my tool but whatever lies
# behind me (_roundedChildClipRadii: the rounded frame's mechanism, visual-design-system §4.7).
# Anywhere else in my square a press lands on my tool, at rest as much as hovered: a fill of no
# colour changes how I paint, never my shape.

class GlassBoxBottomWdgt extends BoxWdgt

  # The LID over my tool, when my tool is there only to be dragged out (not actionableAsThumbnail): the
  # GlassBoxTopWdgt the tool panel that wraps the tool puts on me and records here
  # (ToolPanelWdgt._addNoSettle); undefined when my tool catches its own taps, and once my lid has left
  # me (_reactToChildRemoved). A reference into my own subtree, so a copy holds its own lid and a save
  # keeps it.
  lid: undefined

  colloquialName: -> "tool cell"

  # my rounding is the tool cell's, from the theme, as I am built; my fill is read as I am painted
  constructor: ->
    super WorldWdgt.theme.toolCellCornerRadius

  # I already stand in a tool panel's grid as a cell, so a panel I am added to seats me as I am and
  # wraps me in no second cell (ToolPanelWdgt._addNoSettle asks whatever it is given; only I answer).
  standsAsAToolCell: ->
    true

  # The one widget I wrap -- the tool this cell offers, which is what names the cell in a menu.
  # (GlassBoxTopWdgt's grab reads the same first child.)
  glassBoxItem: ->
    @children[0]

  # The widget a TAP on me actually reaches, which is therefore what any PROJECTION of this cell
  # -- a toolbar overflow menu's row -- must click: one dispatch contract for every tool family.
  # A tool that is not actionable as a thumbnail wears a LID (ToolPanelWdgt puts one there), and
  # then the lid is what the pointer lands on and the lid is what carries the click; a tool that
  # handles its own clicks wears none and catches its taps itself. It is also the widget whose
  # pointer state my look shows.
  thumbnailClickReceiver: ->
    @lid ? @glassBoxItem()

  # MY LID LEFT ME, wherever it went (destroyed, or re-parented by "Attach"): I forget it, so a tap on
  # me reaches my tool again and I never name a widget standing elsewhere, or a destroyed one (the dock
  # slots' rule, FrameWdgt._freeDockSlotOf). A lid re-added to me is still mine.
  _reactToChildRemoved: (child) ->
    @lid = undefined if child is @lid and child.parent isnt @

  # ===== my look =====

  # MY TOOL'S STATE MOVED: the hand's answers about the widget a press on me reaches moved (that
  # widget's notePointerStateChanged tells me: CreatorWdgt, EditorContentPropertyChangerButtonWdgt,
  # CodeInjectingSimpleRectangularButtonWdgt), or my tool may have become or stopped being the active
  # one, or gained or lost something to act on (told by my toolbar, ToolbarWdgt.noteToolStatesChanged:
  # the edited text, its style or its mode moved, the holder of a paint tool changed, the toolbar
  # docked or left). My look is read as I am painted, so I repaint -- my tool's glyph with me, whose
  # ink reads me -- and I pass the news on, so what shows my tool's state THROUGH me re-reads it: a
  # toolbar overflow menu's row for my tool, ticked by holdsActiveTool (OverflowChevronButtonWdgt).
  # markNonValueChange: what moved is not a value (I have none to deliver).
  noteItemStateChanged: ->
    @_changed()
    world.dataflow?.markNonValueChange @

  # Is my tool the ACTIVE one, by its own answer (isActiveTool, a capability: a tool that is never
  # active answers nothing)? Read by my look and by a menu row that reflects me
  # (MenuRowReflectionSpec.readerName).
  holdsActiveTool: ->
    @glassBoxItem()?.isActiveTool?() ? false

  # Has my tool NOTHING TO ACT ON, by its own answer (hasSomethingToActOn answering false; a tool that
  # answers nothing is never dimmed)? Read by my look and by my tool's ink
  # (EditorContentPropertyChangerButtonWdgt._fillForMyState).
  holdsToolWithNothingToActOn: ->
    @glassBoxItem()?.hasSomethingToActOn?() is false

  # My fill for my tool's state now, which my BoxyAppearance reads as it paints me (and no border: I
  # answer no stroke). Dimmed, I show the rest fill whatever the pointer does; else the tool cell's
  # look (fillForToolState).
  _fillForMyState: ->
    return WorldWdgt.theme.toolCellFill if @holdsToolWithNothingToActOn()
    GlassBoxBottomWdgt.fillForToolState @thumbnailClickReceiver(), @holdsActiveTool()

  # THE TOOL CELL'S FILL for a tool whose pointer state `stateHolder` shows -- the hand's answers about
  # it (ActivePointerWdgt.pressesOn, restsOn), when it is a tool that lights a cell (lightsAToolCell:
  # every toolbar tool family, a cell's lid, the overflow chevron; an absent holder, or any other
  # widget -- a menu row standing in a cell shows its own hover --, reads as at rest) -- and which is or
  # is not the active tool: toolCellPressedFill while pressed, toolCellHoverFill while hovered, else
  # toolCellActiveFill while active, else toolCellFill. ONE answer for every wearer of the look: my
  # cells, and the toolbar's overflow chevron, which stands in no cell (OverflowChevronAppearance).
  @fillForToolState: (stateHolder, isActive) ->
    theme = WorldWdgt.theme
    if stateHolder?.lightsAToolCell?()
      return theme.toolCellPressedFill if world.hand.pressesOn stateHolder
      return theme.toolCellHoverFill if world.hand.restsOn stateHolder
    if isActive then theme.toolCellActiveFill else theme.toolCellFill

  # ===== my tool, cut to my outline =====

  # The per-corner radii [topLeft, topRight, bottomRight, bottomLeft] of the rounded outline my
  # children are cut to, or undefined when I have no rounding: my own outline's. My paint asks it
  # (below), and so does every descendant's pointer test (Widget.isPointerTargetAt, AM-I-UNCUT).
  _roundedChildClipRadii: ->
    radii = @appearance?.outlineCornerRadii?()
    return undefined unless radii? and Math.max(radii...) > 0
    radii

  # Widget's content paint -- my own fill, my children, the selection overlay -- with my children
  # painted inside my rounded outline (Widget._paintChildrenInsideMyRoundedOutline, the rounded
  # frame's own): they lie inside my square, so nothing of theirs is lost but what my notches cut.
  # Unrounded, exactly Widget's body. ⚠ LOCKSTEP with Widget's
  # _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: an edit to that body must be
  # mirrored here.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    radii = @_roundedChildClipRadii()
    if !radii?
      @_paintChildrenOver aContext, clippingRectangle, appliedShadow
    else
      damagedPartOfMe = @boundingBox().intersect clippingRectangle
      unless damagedPartOfMe.isEmpty()
        @_paintChildrenInsideMyRoundedOutline aContext, damagedPartOfMe, appliedShadow, radii
    @_paintEditorSelectionOverlayIfSelected aContext, clippingRectangle, appliedShadow

  _reLayoutSelf: ->

    @_repaintAsOneUnit =>

      thumbnailSize = @width()

      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      for w in childrenNotHandlesNorCarets

        # a menu item is sized to its text; other contents become square thumbnails
        # (instead of `w instanceof MenuItemWdgt`; type-test-elimination campaign)
        if w.isTextSizedGlassBoxItem?()
          w._applyMoveTo @topLeft().add((new Point 0 ,(@height() - w.height())/2 ).round())
        else
          if w.idealRatioWidthToHeight?
            ratio = w.idealRatioWidthToHeight
            if ratio > 1
              # more wide than tall
              w._applyExtent new Point thumbnailSize, thumbnailSize / ratio
            else
              # more tall than wide
              w._applyExtent new Point thumbnailSize * ratio, thumbnailSize
          else
            w._applyExtent new Point thumbnailSize, thumbnailSize

          w._applyMoveTo @topLeft().add((new Point (thumbnailSize - w.width())/2 ,(thumbnailSize - w.height())/2 ).round())
