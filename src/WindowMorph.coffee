# WindowMorph //////////////////////////////////////////////////////

class WindowMorph extends BoxMorph

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

    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    if !window.recalculatingLayouts
      debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      @notifyChildrenThatParentHasReLayouted()
      return

    @rawSetBounds newBoundsForThisLayout

    closeIconSize = 16

    # label
    labelLeft = @left() + @padding + closeIconSize + @padding
    labelTop = @top() + @padding
    labelRight = @right() - @padding
    labelWidth = labelRight - labelLeft

    if @label.parent == @
      labelBounds = new Rectangle new Point labelLeft, labelTop
      labelBounds = labelBounds.setBoundsWidthAndHeight labelWidth, 15
      @label.doLayout labelBounds
      @resizer.silentUpdateResizerHandlePosition()
    labelBottom = labelTop + @label.height() + 2

    # close button
    if @topLeftButton.parent == @
      buttonBounds = new Rectangle new Point @left() + @padding, @top() + @padding
      buttonBounds = buttonBounds.setBoundsWidthAndHeight closeIconSize, closeIconSize
      @topLeftButton.doLayout buttonBounds


    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()

  