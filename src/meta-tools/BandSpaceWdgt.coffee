# A SPACE: a cell of a DIVISION stack (StackLayoutEngine) whose division box is all it is. I paint
# nothing, and I have no children. Three makers make me:
#   A BAND (BandWdgt) makes its GAP between two of its controls, a fixed number of px wide, and its
# SPRING, which takes whatever width the band has to spare. A band holding a text that gives has no
# spring of mine: that text is its spring, and takes the spare itself. There I am an element of the
# band's horizontal division row.
#   An INSPECTOR (InspectorWdgt) makes a spring to keep the PLACE its view left in its vertical
# stack: it desires 1 px each way, as a band's spring does, and spreads, so it takes the height the
# inspector's pinned header leaves and claims none of the inspector's width.
#   An EMPTY BODY, an inspector on no subject (InspectorWdgt._newEmptyPane), makes a spring as its one
# view, "Nothing": a member editor's least size (inspectorEditorLeastWidth by a footer band's height)
# as my desired size, and that height as my least, so the empty body needs and desires the height a
# member's body does, and spreads, taking the height its header leaves.
#   A gap's box is fixed: least = desired = most = the size given, and no spreadability at all (0,
# not SPREADABILITY_NONE, which still leaves a tenth of the desired size to take slack: a "fixed"
# piece would then wobble a px as the band's width changes). A spring's least width is 0, and its
# desired size along its stack is 1, never 0: a stack whose elements desire 0 in all divides by zero
# (StackLayoutEngine.arrange, its third regime), and a spring may be a band's only element for a
# moment, or an inspector's once its header is taken out too. Its spreadability is a spacer's, so
# the slack goes to it and not to the controls.
#   In a band my HEIGHT is the band's, and that is what makes the band that tall: a division row is
# as tall as its tallest element (Widget._getRecursiveStackDim), whatever its own box says.
#   I may be 0 wide, so my minimumExtent is 0 x 0 (the base's 5 x 5 would clamp what the stack hands
# me), and I am my holder's internal structure, so the hierarchy menu passes over me.
class BandSpaceWdgt extends Widget

  # `width` and `height` are my identity: the size I take (a spring's desired size: a band gives its
  # spring as 1 wide, an inspector its view's place as 1 by 1, an empty body its pane as a member
  # editor's least); opts.springs makes me a SPRING
  constructor: (width, height, opts = {}) ->
    super()
    @minimumExtent = new Point 0, 0
    if opts.springs
      @setMinAndMaxBoundsAndSpreadability (new Point 0, height), (new Point width, height), DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    else
      extent = new Point width, height
      @setMinAndMaxBoundsAndSpreadability extent, extent, 0

  # I am my holder's internal structure -- a band's, the place an inspector keeps, or an empty body's
  # pane -- like the row a prompt's buttons stand in: the ancestor hierarchy menu passes over me
  # (Widget.getHierarchyMenuWidgets)
  hiddenFromHierarchyMenu: ->
    true
