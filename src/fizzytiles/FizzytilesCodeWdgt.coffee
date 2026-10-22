# Fizzytiles' CODE PANE: the LiveCodeLang the fridge's tiles compile to, shown and editable (an edit
# runs on the 3D pane, setText). My builder sets my text in the code role -- fonts.code and the
# codeText ink -- at its fixed size (FridgeMagnetsWdgt).
#   I am one of Fizzytiles' four bordered panes, and my whole look is read from the theme as my
# text is rendered, so a pane saved, loaded or duplicated wears the look of the world it is shown
# in:
#   my BACKGROUND  the fizzytilesCodePaneFill role (_surfaceBackgroundFill, which
#                  StringWdgt._backgroundFill asks while I hold no backgroundColor of my own; a
#                  background set on me later is mine)
#   my BORDER      a 1 px ring just inside my box, the fizzytilesCodePaneStroke role, painted into my
#                  back buffer over my background and under my text (_prepareTextBufferContext)
#   my TEXT        codePanePadding in from my box on every side (_textInset, which every query
#                  that places, wraps, fits, hit-tests or carets my text reads), so it never touches
#                  the border
# My box is my builder's: the border and the inset sit inside it.

class FizzytilesCodeWdgt extends TextWdgt

  fridgeMagnetsCanvas: undefined

  # stated rather than inherited (a text's "text"): the code Fizzytiles compiles, the app's proper
  # name keeping its capital
  colloquialName: -> "Fizzytiles code"

  _surfaceBackgroundFill: ->
    WorldWdgt.theme.fizzytilesCodePaneFill

  # my text stands codePanePadding in from my box, inside my border (I am never dressed as a
  # document item, so StringWdgt's item-shape inset has nothing to say here)
  _textInset: ->
    padding = WorldWdgt.theme.codePanePadding
    new Point padding, padding

  # my back buffer's preparation (StringWdgt's: the font, the alignment, my background), then my
  # border over that background, before my text is drawn. The context is in logical pixels here;
  # the 1 px ring is stroked inset half a pixel, the house crisp spelling.
  _prepareTextBufferContext: (backBufferContext) ->
    super backBufferContext
    backBufferContext.save()
    backBufferContext.lineWidth = 1
    backBufferContext.strokeStyle = WorldWdgt.theme.fizzytilesCodePaneStroke.toString()
    backBufferContext.strokeRect 0.5, 0.5, Math.round(@width()) - 1, Math.round(@height()) - 1
    backBufferContext.restore()

  # my buffer's key: a text's, plus my border's colour and my inset, so a buffer of mine is never
  # shared with a text that has neither, and a changed role re-renders me
  createBufferCacheKey: ->
    theme = WorldWdgt.theme
    super() + "-codePaneBorder" + theme.fizzytilesCodePaneStroke.toString() + "-inset" + theme.codePanePadding

  # compileTiles (my only caller, via FridgeWdgt's drop/grab gesture hooks) runs inside the gesture's
  # settle, so set the text through the NON-settling core (minus the now-redundant settle).
  showCompiledCode: (theTextContent) ->
    @_setTextNoSettle theTextContent

  setText: (theTextContent) ->
    super theTextContent
    @fridgeMagnetsCanvas?.newGraphicsCode @text
