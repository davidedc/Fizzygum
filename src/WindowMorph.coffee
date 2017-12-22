# WindowMorph //////////////////////////////////////////////////////

class WindowMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  label: nil
  topLeftButton: nil
  labelContent: nil
  resizer: nil
  padding: nil

  constructor: (@labelContent, @topLeftButton) ->
    super()
    # override inherited properties:
    @setExtent new Point(WorldMorph.preferencesAndSettings.handleSize * 20,
      WorldMorph.preferencesAndSettings.handleSize * 20 * 2 / 3.5).round()
    @padding = if WorldMorph.preferencesAndSettings.isFlat then 1 else 5
    @color = new Color 172, 172, 172
    @buildAndConnectChildren()
  
  buildAndConnectChildren: ->
    # label
    @label = new TextMorph @labelContent
    @label.fontSize = WorldMorph.preferencesAndSettings.menuFontSize
    @label.isBold = true
    @label.color = new Color 255, 255, 255
    @add @label

    # upper-left button, often a close button
    # but it can be anything
    if !@topLeftButton?
      @topLeftButton = new CloseIconButtonMorph @
    @add @topLeftButton

    @resizer = new HandleMorph @

    @layoutLabelAndTopLeftButton()

  
  layoutLabelAndTopLeftButton: ->

    closeIconSize = 16

    # label
    labelLeft = @left() + @padding + closeIconSize + @padding
    labelTop = @top() + @padding
    labelRight = @right() - @padding
    labelWidth = labelRight - labelLeft
    if @label.parent == @
      @label.fullRawMoveTo new Point labelLeft, labelTop
      @label.rawSetWidth labelWidth
      if @label.height() > @height() - 50
        @silentRawSetHeight @label.height() + 50
        # TODO run the tests when commenting this out
        # because this one point to the Morph implementation
        # which is empty.
        @reLayout()
        
        @changed()
        @resizer.silentUpdateResizerHandlePosition()
    labelBottom = labelTop + @label.height() + 2

    # close button
    if @topLeftButton.parent == @
      @topLeftButton.fullRawMoveTo new Point @left() + @padding, @top() + @padding
      @topLeftButton.rawSetHeight closeIconSize
      @topLeftButton.rawSetWidth closeIconSize


    @changed()

  layoutSubmorphs: (morphStartingTheChange = nil) ->
    super morphStartingTheChange
    @layoutLabelAndTopLeftButton()


