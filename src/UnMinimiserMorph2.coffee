# UnMinimiserMorph2 ///////////////////////////////////////////////////////////

# this should really extend TriggerMorph, but
# I prefer to extend StringMorph2 until
# a new version of TriggerMorph is ready.

# Un-minimises a minimised Morph

class UnMinimiserMorph2 extends StringMorph2
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  constructor: (@target) -> # the morph to be un-minimised

      super(
        "⇕ " + @target.toString(),
        null, #@originallySetFontSize,
        null, #@fontStyle,
        null, #@isBold,
        null, #@isItalic,
        false, # isNumeric
        null, #color,
        null, #fontName
        new Color(255, 255, 255), #@backgroundColor,
        null, #@backgroundTransparency
        )
      # override inherited properties:
      @noticesTransparentClick = true

      @scaleAboveOriginallyAssignedFontSize = true
      @cropWritingWhenTooBig = true


  # Every time the user clicks on the text, a new edit()
  # is triggered, which creates a new caret.
  mouseClickLeft: (pos) ->
    if @target.destroyed
      @inform "The morph to be\nun-minimised is dead!"
      return

    myPosition = @positionAmongSiblings()
    @parent.add @target, myPosition
    @target.fullMoveTo @position()
    @target.fullChanged()
    @destroy()

  closeThis: ->
    @destroy()

  closeThisAndTarget: ->
    @target.destroy()
    @destroy()

  developersMenu: ->
    menu = @developersMenuOfMorph()
    menu.addLine 1
    menu.addItem "close this button", true, @, "closeThis"
    menu.addItem "close target morph", true, @, "closeThisAndTarget"
    menu


