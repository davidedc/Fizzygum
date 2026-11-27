# A MEMBER EDITOR: an inspector's view of ONE member of one object (my memberRef, a MemberRef) --
# its source, or its value, as CoffeeScript text, and the Save that writes my text back as that
# member. I am the code area family's (CodeAreaWdgt: the code area on top, my footer band of buttons
# below), the member's inspector is the one I stand in (InspectorWdgt), and that inspector's subject
# is my memberRef too: chosen in the member list before it in its browser's sequence
# (MemberListWdgt.selectionFromList); that inspector stands where its browser's body goes, below the
# lists or beside them (InspectorBrowserWdgt.bodyPlace).
#   HOW my member is edited is my memberRef's to know (its save: an object's member through the
# instance edit protocol, a class's through its meta-object, recorded), and so is whether it is
# edited at all (MemberRef.canEdit): a member no Save edits -- of a number, a Point, a plain object,
# a built-in class's prototype -- gets no Save, and with it no footer band
# (CodeAreaWdgt._hasAFooterBand), my code area running down to my bottom. My text takes typing
# exactly while a Save can apply it: a member no Save edits is shown, never typed into, and so is
# `constructor`'s code: it is the class itself, which a save would replace
# (Class.refuseTheConstructor). A value with no code form on a holder a Save edits (a widget-valued
# field, a function with no source kept) keeps its typing and its Save: CoffeeScript typed over its
# printed form is the way to replace it.
#   My text is my member's as my memberRef shows it (MemberRef.shownText): a function's source, a
# field's recorded source, else the field's value as code where it has a code form (a field holding
# a Fizzygum class reads as the class's name), else its printed form; at my build and again
# whenever my member is CHOSEN AGAIN (_reloadNoSettle): put back over whatever is typed as one step of
# my text's undo history, so the undo chord brings the typing back. After a Save I show what my
# member then shows, whatever kind of thing was stored: where that is the text typed (a function
# literal, kept as its source; a value typed in its code form) the text stays, its caret, selection
# and undo history with it; where it is not, it is put back the same way (`1 + 1` saved reads `2`,
# `Math.max` the compiled text of the function it names). Another member gets another editor, with a
# history of its own, so no undo brings back a text of another member's that a Save would write into
# this one.
#   I stand on the body of the inspector browser that holds me: my code area wears the inspector's
# pane roles, no fill and no border, and the rules between me and my neighbours are theirs and the
# bands'. Standing anywhere else -- a person took me out of my inspector -- I paint that body myself,
# under my code area and my footer's rule (InspectorBodyAppearance, in place of the seam rules alone
# my family paints). My division box gives me a floor of my own (inspectorEditorLeastWidth wide, a
# footer band tall), since I have no division children to derive one from, and a large most size, so
# the slack of my inspector's column is mine.
class MemberEditorWdgt extends CodeAreaWdgt

  # a file holding me needs the class member maps before I am restored: the text I show of a class's
  # member is its recorded source (Deserializer._needsTheReflectiveLayer, which both file doors consult)
  readsClassMemberMaps: true

  # the member I show and edit (a MemberRef: an object's member, or a ClassMemberRef: a class's)
  memberRef: undefined
  # my Save -- the primary action, at my footer band's right -- or undefined while my member is
  # edited by no Save. Enabled exactly while my code area holds an edit to save (textContentModified);
  # a disabled button still catches a press and does nothing.
  saveButton: undefined

  # The member reference is my identity, my one positional parameter.
  constructor: (@memberRef) ->
    super()
    @appearance = new InspectorBodyAppearance @
    theme = WorldWdgt.theme
    least = new Point theme.inspectorEditorLeastWidth, theme.footerBandHeight
    @setMinAndMaxBoundsAndSpreadability least, least, DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    @_buildAndConnectChildren()

  # MY SHADOW IS THE BODY'S BOX, my parts' silhouettes left out, while I paint the body
  # (InspectorBodyAppearance.castsOnlyTheBody says when, and its header why); otherwise my base's pass.
  _fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow: (aContext, clippingRectangle, appliedShadow) ->
    if @appearance.castsOnlyTheBody appliedShadow
      @paintIntoAreaOrBlitFromBackBuffer aContext, clippingRectangle, appliedShadow
    else
      super

  # My code area, as the editable variant builds it (CodeAreaWdgt), its text my member's, then dressed
  # in the inspector's pane roles in place of the code pane's (ViewportWdgt.wearPaneRoles, read as it
  # paints and kept by name), so the browser's body shows through it as through a member list. Then my
  # Save, when my member is edited by one, and my code area's content check: my text is the text it
  # compares against, so it starts unmodified and the Save disabled.
  _buildAndConnectChildrenNoSettle: ->
    @_buildEditableCodeAreaNoSettle @memberRef.shownText()
    @tempPromptEntryField.wearPaneRoles fill: "inspectorPaneFill", stroke: "inspectorPaneStroke"
    @textWidget.backgroundColor = WorldWdgt.theme.inspectorPaneFill
    # my text takes typing exactly while a Save can apply it: my member's holder is edited at all,
    # and my member is not `constructor`, my member's holder's class itself
    @textWidget.isEditable = (MemberRef.canEdit @memberRef.holder) and @memberRef.name isnt "constructor"
    if MemberRef.canEdit @memberRef.holder
      @saveButton = new SimpleButtonWdgt target: @, action: "save", face: "Save", primary: true
      @_addNoSettle @saveButton
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    @_invalidateLayout()

  # My footer band holds my Save at its RIGHT, when I have one (none: no band, _hasAFooterBand).
  _footerRightButtons: ->
    [@saveButton]

  # My code area tells me when its text comes to differ from the text last loaded or saved, and when
  # it agrees with it again: my Save is enabled exactly while there is an edit to save.
  textContentModified: ->
    @saveButton?.setEnabled true

  textContentUnmodified: ->
    @saveButton?.setEnabled false

  # What code typed in me runs against (TextWdgt._codeReceiver): my member's holder, exactly while it
  # is an object my Save edits as an object's and a receiver typed code runs against
  # (MemberRef.codeReceiverOf); a class's member, a paint tool's, or a value no Save edits, gets no run
  # rows.
  codeReceiver: ->
    MemberRef.codeReceiverOf @memberRef.holder

  # My Save: my text written back as my member (my memberRef's save), which makes the edit, records it
  # where a world snapshot needs it, and tells once. Every save step compiles before it changes
  # anything, so an edit that does not compile changes nothing: it is reported beside the hand, and
  # stays MODIFIED, my Save still enabled (Widget._savingTypedCode). The gesture asks MemberRef.canEdit
  # too, not only my build: a restored editor keeps the button its file holds. Then I show what my
  # member SHOWS (MemberRef.shownText), one rule whatever was stored: where that is the text typed,
  # read once before the save, nothing moves -- the text stays, its caret, selection and undo history
  # with it; where it differs, it is put back (_reloadNoSettle, one step of my undo history), so I show
  # what was stored: `Color.GRAY` saved reads as its code form, a text NAMING a function (`Math.max`,
  # `@otherMethod`), which keeps no source, as that function's compiled text. Either way the text
  # shown is then the one my code area compares against: unmodified, my Save disabled. Answers whether
  # it saved.
  save: ->
    return false unless @saveButton? and MemberRef.canEdit @memberRef.holder
    typed = @textWidget.text.toString()
    return false unless @_savingTypedCode => @memberRef.save typed
    if @memberRef.shownText() is typed
      @textWidget.considerCurrentTextAsReferenceText()
      @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    else
      @_settleLayoutsAfter => @_reloadNoSettle()
    true

  # MY MEMBER CHOSEN AGAIN (InspectorBrowserWdgt.showChoice, the subject my inspector already shows),
  # or just saved, when what it shows is not the text typed (save): its text put back over whatever is
  # typed, as one step of my text's undo history, so the undo chord brings the typing back; that text
  # is then the text my code area compares against, so it reads unmodified and my Save disables. A
  # core: the browser calls it inside its one settle, my Save inside its own.
  _reloadNoSettle: ->
    @textWidget._setTextNoSettle @memberRef.shownText()
    @textWidget.pushUndoState @textWidget.text.length
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    return
