# Shared base for the "code/text area + bottom action-button row" widget family:
# ConsoleWdgt ("dev -> console"), ScriptWdgt (a standalone script on the desktop),
# CodePromptWdgt (the code-entry popup) and ErrorsLogViewerWdgt (the error log).
# It carries what is byte-identical across the family: the code-area fields + the
# two paddings, the build settle-wrapper, and the two code-area builder variants
# (the EDITABLE white panel with modified-content tracking -- Script/CodePrompt --
# and the plain mono panel -- Console/ErrorsLog). Everything that differs per
# class stays on the subclass: the constructor signature, the button row and what
# its actions DO (CodePromptWdgt alone carries a target/callback pair, delivered
# through its deliverValue pair), and the _reLayout geometry (2 vs 3 buttons, row
# heights, damage handling -- the four _reLayouts are deliberately NOT folded: a
# verbatim diff shows they differ beyond the button fields).
class CodeAreaWdgt extends Widget

  tempPromptEntryField: undefined
  textWidget: undefined

  # space between the container's edges and its internal contents -- often
  # left 0 because windows already add their own inner padding.
  externalPadding: 0
  # the internal padding is the space between the internal
  # components. It doesn't necessarily need to be equal to the
  # external padding
  internalPadding: 5

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  # the EDITABLE code-area variant (ScriptWdgt / CodePromptWdgt): white scroll panel,
  # drops disabled, modified-content indicator, transparent mono editable text with
  # selection enabled.
  _buildEditableCodeAreaNoSettle: (initialText) ->
    @tempPromptEntryField = new TextAreaWdgt initialText, false, 5
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = Color.WHITE
    @tempPromptEntryField.addModifiedContentIndicator()

    # register this wdgt as one to be notified when the text
    # changes/unchanges from "reference" content
    # so we can enable/disable the "save" button
    @tempPromptEntryField.widgetToBeNotifiedOfTextModificationChange = @

    @textWidget = @tempPromptEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget._setFontNameNoSettle @textWidget.monoFontStack
    @textWidget.isEditable = true
    @textWidget.enableSelecting()

    @_addNoSettle @tempPromptEntryField

  # the plain mono-panel variant (ConsoleWdgt / ErrorsLogViewerWdgt)
  _buildMonoCodeAreaNoSettle: (initialText) ->
    @tempPromptEntryField = new TextAreaWdgt initialText, false, 5
    @tempPromptEntryField.configureAsMonoTextPanel true
    @textWidget = @tempPromptEntryField.textWdgt
    @_addNoSettle @tempPromptEntryField

