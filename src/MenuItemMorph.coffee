# MenuItemMorph ///////////////////////////////////////////////////////

# I automatically determine my bounds

class MenuItemMorph extends TriggerMorph
  constructor: (target, action, labelString, fontSize, fontStyle, environment, hint, color) ->
    @init target, action, labelString, fontSize, fontStyle, environment, hint, color

MenuItemMorph::createLabel = ->
  np = undefined
  @label.destroy()  if @label isnt null
  # bold
  # italic
  # numeric
  # shadow offset
  # shadow color
  @label = new StringMorph(@labelString, @fontSize, @fontStyle, false, false, false, null, null, @labelColor)
  @silentSetExtent @label.extent().add(new Point(8, 0))
  np = @position().add(new Point(4, 0))
  @label.bounds = np.extent(@label.extent())
  @add @label


# MenuItemMorph events:
MenuItemMorph::mouseEnter = ->
  unless @isListItem()
    @image = @highlightImage
    @changed()
  @bubbleHelp @hint  if @hint

MenuItemMorph::mouseLeave = ->
  unless @isListItem()
    @image = @normalImage
    @changed()
  @world().hand.destroyTemporaries()  if @hint

MenuItemMorph::mouseDownLeft = (pos) ->
  if @isListItem()
    @parent.unselectAllItems()
    @escalateEvent "mouseDownLeft", pos
  @image = @pressImage
  @changed()

MenuItemMorph::mouseMove = ->
  @escalateEvent "mouseMove"  if @isListItem()

MenuItemMorph::mouseClickLeft = ->
  unless @isListItem()
    @parent.destroy()
    @root().activeMenu = null
  @trigger()

MenuItemMorph::isListItem = ->
  return @parent.isListContents  if @parent
  false

MenuItemMorph::isSelectedListItem = ->
  return @image is @pressImage  if @isListItem()
  false
