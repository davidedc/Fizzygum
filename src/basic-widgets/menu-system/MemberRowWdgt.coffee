# A MEMBER row: a row of a MEMBER list -- a list of an object's members (a ListWdgt built with a
# memberFactsQuery: the Object Inspector's) -- showing on one line what KIND of member it stands
# for, and the member's NAME:
#   - my KIND TAG (kindTag, a StringWdgt): a short word my builder chooses ("fn", "var"), in
#     fonts.memberKindTag (10 px bold), memberRowSideInset in, in a memberRowTagColumnWidth column;
#   - my NAME (label, a StringWdgt): my labelString in fonts.memberName (13 px mono), from
#     memberRowTagGap after that column out to memberRowSideInset short of my right edge -- a name
#     too long for that box is cut off with "…" (StringWdgt's CROP fitting), never dropped, so I
#     always name my member; DIMMED (my spec's `dimmed`), it is muted rather than ink.
# Each is one line tall, placed in my selection plate's height by the draft's rule for an explicit
# line height (UI-guidelines §1.1, rule 1): its top lies floor((plate - line) / 2) below mine -- 12
# for the name's 16 px line, 14 for the tag's 12 px line, which is the draft's 16 px tag band at 12
# holding the tag's line at 12 + floor((16 - 12) / 2).
#   I am memberRowHeight tall and as wide as my rows panel makes me (my list's width less the
# panel's padding, CommandPanelWdgt._myArrangedWidth): member rows stack flush, so my height is my
# list's pitch. My look (_lookFor): no fill at rest; while I am my list's selection, and while I am
# pressed, a memberRowPlateHeight plate of the accent tint across my whole width at my top, and my
# tag in the accent. No hover look (a list row ignores hovering), no hairline (my panel tells member
# rows none), no indicators.
#   Otherwise I am a list row like any other (MenuItemWdgt): a click selects me and a double-click
# opens my member (ListWdgt.select / ListWdgt.openRow), and the toolkit finds me by my labelString
# and aims into my label.

class MemberRowWdgt extends MenuItemWdgt

  # my KIND TAG, a StringWdgt: built with me from my spec's kindTag, adopted and placed by
  # _placeMyParts, which runs again whenever my label is rebuilt -- the tag belongs to my member, not
  # to the label of the moment
  kindTag: undefined
  # is my name DIMMED -- shown in memberRowDimmedNameText rather than memberRowNameText? An own field
  # only when true.
  dimmed: false

  # My spec names my member (its label, also my labelString) and says what I show of it beside the
  # name (its kindTag, and whether it is dimmed); `opts` is my panel's context, as for any row.
  #   ⚠ My dimming and my tag are set BEFORE super, for the reason MenuItemWdgt's constructor gives:
  # my look is read (_lookFor) and my parts are placed (_placeMyParts) while it runs.
  constructor: (commandSpec, opts = {}) ->
    theme = WorldWdgt.theme
    @dimmed = true  if commandSpec.dimmed
    @kindTag = new StringWdgt (commandSpec.kindTag ? ""), fontRole: theme.fonts.memberKindTag, color: theme.memberRowTagText
    super commandSpec, opts

  # MY LOOK (MenuItemWdgt reads it before super): my name in fonts.memberName, in ink or, dimmed, in
  # muted; no fill at rest; ONE plate while I am selected and while I am pressed, the accent tint,
  # memberRowPlateHeight tall at memberRowPlateRadius; and my rhythm -- memberRowSideInset at my
  # sides, and, as my iconGap, memberRowTagGap between my tag's column and my name (I carry no icon).
  _lookFor: ->
    theme = WorldWdgt.theme
    font: theme.fonts.memberName
    ink: if @dimmed then theme.memberRowDimmedNameText else theme.memberRowNameText
    restFill: theme.memberRowFill
    highlightFill: theme.memberRowSelectedFill
    pressFill: theme.memberRowSelectedFill
    plateRadius: theme.memberRowPlateRadius
    plateHeight: theme.memberRowPlateHeight
    sideInset: theme.memberRowSideInset
    iconGap: theme.memberRowTagGap

  # My NAME: a one-line StringWdgt of my labelString in my font and ink, in StringWdgt's own fitting
  # -- its box fixed and its text cropped to it with "…" (not the hug a menu row's TextWdgt label
  # takes) -- its box sized and placed by _placeMyParts. Building it gives me my height. _addNoSettle
  # (NOT add): _createLabel is driven by _reLayoutSelf, a layout pass.
  _createLabel: ->
    @label = new StringWdgt @labelString,
      fontSize: @fontSize
      fontName: @fontStyle
      bold: @labelBold
      italic: @labelItalic
      color: @labelColor
    @_addNoSettle @label
    @__commitExtent new Point @width(), WorldWdgt.theme.memberRowHeight

  # WHAT STANDS LEFT OF MY NAME: my side inset, my tag's column, and the gap after it.
  _leadingWidth: ->
    @sideInset + WorldWdgt.theme.memberRowTagColumnWidth + @iconGap

  # My TAG and my NAME, placed against my box as it now is (my _reLayoutSelf runs this after every
  # change of my box): the tag in its column at my side inset, the name from _leadingWidth out to my
  # side inset short of my right edge, so a narrower row crops more of a long name; each one line
  # tall, its top floor((plate - line) / 2) below mine (see the class comment). The tag is placed
  # BEFORE it is adopted, so the add damages the spot it will be painted at. Every number is whole.
  _placeMyParts: ->
    theme = WorldWdgt.theme
    plateHeight = theme.memberRowPlateHeight
    tagLine = @kindTag.linePitch @kindTag.originallySetFontSize
    @kindTag.__commitMoveTo @position().add new Point @sideInset, Math.floor (plateHeight - tagLine) / 2
    @kindTag.__commitExtent new Point theme.memberRowTagColumnWidth, tagLine
    @_addNoSettle @kindTag  unless @kindTag.parent is @
    nameLine = @label.linePitch @label.originallySetFontSize
    @label.__commitMoveTo @position().add new Point @_leadingWidth(), Math.floor (plateHeight - nameLine) / 2
    @label.__commitExtent new Point (Math.max 0, @width() - @_leadingWidth() - @_trailingWidth()), nameLine

  # My tag's ink follows my state: the accent while I am out of my rest state -- my list's selection,
  # or pressed -- and memberRowTagText at rest. Run after every change of my state (below).
  _inkMyTag: ->
    theme = WorldWdgt.theme
    @kindTag.setColor (if @state is @STATE_NORMAL then theme.memberRowTagText else theme.memberRowSelectedTagText)

  # THE CHANGES OF MY STATE, each made the way any list row makes it (MenuItemWdgt, LabelButtonWdgt)
  # and followed by my tag: a press (pressed; my panel unselects my siblings first), my click
  # (selected), and my panel unselecting me.
  pressBegan: (pos) ->
    super
    @_inkMyTag()

  activated: ->
    super
    @_inkMyTag()

  unselect: ->
    super
    @_inkMyTag()

  # A COPY of me keeps my state, and my tag's ink with it: my state is my list's SELECTION, which a
  # copy of my list keeps (its `selected` is my copy), never a hover -- I have no hover look and no
  # tooltip, the two things a label button's copy drops (LabelButtonWdgt._reactToBeingCopied).
  _reactToBeingCopied: ->
