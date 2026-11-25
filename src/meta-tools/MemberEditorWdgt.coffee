# A MEMBER EDITOR: an inspector's view of ONE member of one object (my memberRef, a MemberRef) --
# its source, or its value, as CoffeeScript text, and the Save that writes my text back as that
# member. I am the code area family's (CodeAreaWdgt: the code area on top, my footer band of buttons
# below), the member's inspector is the one I stand in (InspectorWdgt), and that inspector's subject
# is my memberRef too: chosen in the member list on its left (MemberListWdgt.selectionFromList).
#   HOW my member is edited is my memberRef's to know (its save: an object's member through the
# instance edit protocol, a class's through its meta-object, recorded), and so is whether it is
# edited at all (MemberRef.canEdit): a member no Save edits -- of a number, a Point, a built-in
# class's prototype -- gets no Save, and with it no footer band (CodeAreaWdgt._hasAFooterBand), my
# code area running down to my bottom. `constructor`'s code is shown, never edited: it is the class
# itself, which a save would replace (Class.refuseTheConstructor).
#   My text is my member's as my memberRef shows it (MemberRef.shownText), at my build and again
# whenever my member is CHOSEN AGAIN (_reloadNoSettle): put back over whatever is typed as one step of
# my text's undo history, so the undo chord brings the typing back. Another member gets another
# editor, with a history of its own, so no undo brings back a text of another member's that a Save
# would write into this one.
#   I stand on the body of the row of inspectors that holds me: my code area wears the inspector's
# pane roles, no fill and no border, and the rules between me and my neighbours are theirs and the
# bands'. My division box gives me a floor of my own (inspectorEditorLeastWidth wide, a footer band
# tall), since I have no division children to derive one from, and a large most size, so the slack of
# my inspector's column is mine.
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
    theme = WorldWdgt.theme
    least = new Point theme.inspectorEditorLeastWidth, theme.footerBandHeight
    @setMinAndMaxBoundsAndSpreadability least, least, DivisionStackLayoutSpec.SPREADABILITY_SPACERS
    @_buildAndConnectChildren()

  # HOW MUCH OF ITS ROW'S SPARE WIDTH MY INSPECTOR TAKES, by weight (InspectorWdgt sets its own most
  # width from it): nearly all of it, since code is what wants width. My inspector's most width is
  # 1 + 100 x 1e6 = 100,000,001 px, ten thousand times a member list's weight, so beside one I take all
  # its row's spare but under half a px of it (MemberListWdgt.rowSlackWeight has the arithmetic).
  rowSlackWeight: -> 100

  # My code area, as the editable variant builds it (CodeAreaWdgt), its text my member's, then dressed
  # in the inspector's pane roles in place of the code pane's (ViewportWdgt.wearPaneRoles, read as it
  # paints and kept by name), so the row's body shows through it as through a member list. Then my
  # Save, when my member is edited by one, and my code area's content check: my text is the text it
  # compares against, so it starts unmodified and the Save disabled.
  _buildAndConnectChildrenNoSettle: ->
    @_buildEditableCodeAreaNoSettle @memberRef.shownText()
    @tempPromptEntryField.wearPaneRoles fill: "inspectorPaneFill", stroke: "inspectorPaneStroke"
    @textWidget.backgroundColor = WorldWdgt.theme.inspectorPaneFill
    # `constructor`'s code is shown, never edited: it is my member's holder's class itself
    @textWidget.isEditable = @memberRef.name isnt "constructor"
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
  # is an object my Save edits as an object's (MemberRef.codeReceiverOf); a class's member, or a value
  # no Save edits, gets no run rows.
  codeReceiver: ->
    MemberRef.codeReceiverOf @memberRef.holder

  # My Save: my text written back as my member (my memberRef's save), which makes the edit, records it
  # where a world snapshot needs it, and tells once. Every save step compiles before it changes
  # anything, so an edit that does not compile changes nothing: it is reported beside the hand, and
  # stays MODIFIED, my Save still enabled (Widget._savingTypedCode). The gesture asks MemberRef.canEdit
  # too, not only my build: a restored editor keeps the button its file holds. Answers whether it saved.
  save: ->
    return false unless @saveButton? and MemberRef.canEdit @memberRef.holder
    return false unless @_savingTypedCode => @memberRef.save @textWidget.text.toString()
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    true

  # MY MEMBER CHOSEN AGAIN (InspectorRowWdgt.showChoice, the subject my inspector already shows): its
  # text put back over whatever is typed, as one step of my text's undo history, so the undo chord
  # brings the typing back; that text is then the text my code area compares against, so it reads
  # unmodified and my Save disables. A core: the row calls it inside its one settle.
  _reloadNoSettle: ->
    @textWidget._setTextNoSettle @memberRef.shownText()
    @textWidget.pushUndoState @textWidget.text.length
    @textWidget.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.checkIfTextContentWasModifiedFromTextAtStart()
    return
