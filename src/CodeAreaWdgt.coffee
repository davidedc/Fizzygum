# Shared base for the "code/text area + footer band of buttons" widget family:
# ConsoleWdgt ("dev -> console"), ScriptWdgt (a standalone script on the desktop),
# CodePromptWdgt (the code-entry popup) and ErrorsLogViewerWdgt (the error log).
# It carries what is common to the family: the code-area fields + the padding, the build
# settle-wrapper, the two code-area builder variants (the EDITABLE white panel with
# modified-content tracking -- Script/CodePrompt -- and the plain mono panel -- Console/ErrorsLog),
# my look, and my ARRANGEMENT: the code area on top, then my footer band (FooterBandLayout), whose
# rule is my one seam. Everything that differs per class stays on the subclass: the constructor
# signature, the buttons, which of them sit in the footer's left group and which in its right
# (_footerLeftButtons / _footerRightButtons), and what their actions DO (CodePromptWdgt alone
# carries a target/callback pair, delivered through its deliverValue pair).
class CodeAreaWdgt extends Widget

  tempPromptEntryField: undefined
  textWidget: undefined

  # space between my top and side edges and the code area -- often left 0 because windows
  # already add their own inner padding. The code area always runs down to my footer band.
  externalPadding: 0

  # I paint no background (my window's body shows) -- only my footer band's rule.
  constructor: ->
    super()
    @appearance = new SeamRulesAppearance @

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  # My CODE AREA, as both variants below build it: a TextAreaWdgt in the CODE role -- its text born in
  # fonts.code and the codeText ink, codePanePadding in from its edges -- and with NO BORDER of its
  # own: it is my window's content down to my footer band, so the window's border runs along its
  # sides, the window's title strip ends in a rule above it and my footer band's rule ends it below,
  # and a border of its own would double each of those lines (visual-design-system §4.1). Its fills
  # stay. Set here, on my code area only: a TextAreaWdgt anywhere else keeps its border.
  _newCodeArea: (initialText) ->
    theme = WorldWdgt.theme
    codeArea = new TextAreaWdgt initialText, false, theme.codePanePadding, fontRole: theme.fonts.code, textColor: theme.codeText
    for surface in [codeArea, codeArea.contents]
      surface.strokeColor = undefined
    codeArea

  # the EDITABLE code-area variant (ScriptWdgt / CodePromptWdgt): my code area (_newCodeArea) on a
  # white viewport, drops disabled, modified-content indicator, its text transparent, editable, with
  # selection enabled. The text it opens with is the text it compares against, so it starts
  # UNMODIFIED: the indicator stays hidden, and a save button the notified widget keeps in step
  # starts disabled, until the text diverges.
  _buildEditableCodeAreaNoSettle: (initialText) ->
    @tempPromptEntryField = @_newCodeArea initialText
    @tempPromptEntryField.textWdgt.considerCurrentTextAsReferenceText()
    @tempPromptEntryField.disableDrops()
    @tempPromptEntryField.contents.disableDrops()
    @tempPromptEntryField.color = WorldWdgt.theme.codePaneFill
    @tempPromptEntryField.addModifiedContentIndicator()

    # register this wdgt as one to be notified when the text
    # changes/unchanges from "reference" content
    # so we can enable/disable the save button (@saveButton)
    @tempPromptEntryField.widgetToBeNotifiedOfTextModificationChange = @

    @textWidget = @tempPromptEntryField.textWdgt
    @textWidget.backgroundColor = Color.TRANSPARENT
    @textWidget.isEditable = true
    @textWidget.enableSelecting()

    @_addNoSettle @tempPromptEntryField

  # the plain mono-panel variant (ConsoleWdgt / ErrorsLogViewerWdgt): my code area (_newCodeArea),
  # configured as an editable mono text panel (TextAreaWdgt.configureAsMonoTextPanel)
  _buildMonoCodeAreaNoSettle: (initialText) ->
    @tempPromptEntryField = @_newCodeArea initialText
    @tempPromptEntryField.configureAsMonoTextPanel true
    @textWidget = @tempPromptEntryField.textWdgt
    @_addNoSettle @tempPromptEntryField

  # My footer band's two groups of buttons, each in order, left to right (FooterBandLayout).
  # None by default: each subclass names its own.
  _footerLeftButtons: ->
    []

  _footerRightButtons: ->
    []

  # My one seam: my footer band's rule, between the code area and the buttons.
  _seamRects: ->
    [FooterBandLayout.ruleIn new Rectangle 0, 0, @width(), @height()]

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me):
  # the code area from externalPadding in at my top and sides, flush down to my footer band, then
  # the band's buttons. The code area's height is clamped at 0: a transient degenerate height mid
  # window-negotiation must not invert its rect.
  _layOutOwnContents: ->
    codeAreaTop = @top() + @externalPadding
    codeAreaHeight = Math.max 0, (FooterBandLayout.topIn @bounds) - codeAreaTop

    if @tempPromptEntryField.parent == @
      @tempPromptEntryField._applyBounds (new Point @left() + @externalPadding, codeAreaTop), new Point @width() - 2 * @externalPadding, codeAreaHeight

    FooterBandLayout.arrange @, @_footerLeftButtons(), @_footerRightButtons()
