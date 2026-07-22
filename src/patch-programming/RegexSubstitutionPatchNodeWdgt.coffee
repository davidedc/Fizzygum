# this file is excluded from the fizzygum homepage build

class RegexSubstitutionPatchNodeWdgt extends PatchNodeWdgt

  # shared dataflow-node behaviour (dataflow protocol, connect-to-target menu, setter menus, _reLayout
  # scaffold, padding, and the input1/input2/output/textWidget preamble) lives on PatchNodeWdgt.

  regexEntryField: nil
  defaultContents: nil

  substitutionTextArea: nil
  substitutionTextAreaText: nil

  outputTextArea: nil
  outputTextAreaText: nil

  input3: nil
  input4: nil

  # we need to keep track of which inputs are
  # connected because we wait for those to be
  # all updated before the node fires
  setInput1IsConnected: false
  setInput2IsConnected: false
  setInput3IsConnected: false
  setInput4IsConnected: false

  constructor: (@defaultContents = "") ->
    super new Point 200,400
    @_buildAndConnectChildren()

  colloquialName: ->
    "Regex subst. patch node"

  setInput1: (newvalue, ignored) ->
    @input1 = newvalue
    @updateTarget()

  setInput2: (newvalue, ignored) ->
    @input2 = newvalue
    @updateTarget()

  setInput3: (newvalue, ignored) ->
    @input3 = newvalue
    @updateTarget()

  setInput4: (newvalue, ignored) ->
    @input4 = newvalue
    @updateTarget()

  recalculateOutput: ->
    if @textWidget.text != ""

      # from: https://stackoverflow.com/a/22763959
      regParts = @textWidget.text.match(/^\/(.*?)\/([gim]*)$/)
      if regParts
        # the parsed pattern had delimiters and modifiers. handle them.
        regexp = new RegExp(regParts[1], regParts[2])
      else
        # we got pattern string without delimiters
        regexp = new RegExp(@textWidget.text)

      @output = @input1.replace regexp, @substitutionTextAreaText.text
      @outputTextAreaText._setTextConnector @output

  _buildAndConnectChildrenNoSettle: ->

    @regexEntryField = new SimpleTextScrollPanelWdgt @defaultContents, false, 5
    @regexEntryField.configureAsMonoTextPanel true
    @textWidget = @regexEntryField.textWdgt
    @_addNoSettle @regexEntryField

    @substitutionTextArea = new SimpleTextScrollPanelWdgt @defaultContents, false, 5
    @substitutionTextArea.configureAsMonoTextPanel true
    @substitutionTextAreaText = @substitutionTextArea.textWdgt
    @_addNoSettle @substitutionTextArea

    @outputTextArea = new SimpleTextScrollPanelWdgt @defaultContents, false, 5
    @outputTextArea.configureAsMonoTextPanel false
    @outputTextAreaText = @outputTextArea.textWdgt
    @_addNoSettle @outputTextArea


    @_invalidateLayout()

  # subclass hook for PatchNodeWdgt::_reLayout — position my own children within the (already-applied) frame.
  _layOutNodeContents: ->

    availableHeight = @height() - 2 * @externalPadding - 2 * @internalPadding
    text1Height = Math.round(availableHeight * 1/4)
    text2Height = Math.round(availableHeight * 1/4)
    text3Height = Math.round(availableHeight * 2/4)

    if @regexEntryField.parent == @
      @regexEntryField._applyBounds (new Point @left() + @externalPadding, @top() + @externalPadding), new Point @width() - 2 * @externalPadding, text1Height

    if @substitutionTextArea.parent == @
      @substitutionTextArea._applyBounds (new Point @left() + @externalPadding, @regexEntryField.bottom() + @internalPadding), new Point @width() - 2 * @externalPadding, text2Height

    if @outputTextArea.parent == @
      @outputTextArea._applyBounds (new Point @left() + @externalPadding, @substitutionTextArea.bottom() + @internalPadding), new Point @width() - 2 * @externalPadding, text3Height
