# LayoutSpec

# this comment below is needed to figure our dependencies between classes

# This is a port of the
# respective Cuis Smalltalk classes (version 4.2-1766)
# Cuis is by Juan Vuletich

# LayoutSpecs are the basis for the layout mechanism.
# Any Morph can be given a LayoutSpec, but in order to honor it,
# its owner must be a LayoutMorph.

# A LayoutSpec specifies how a morph wants to be laid out.
# It can specify either a fixed width or a fraction of some
# available owner width. Same goes for height. If a fraction
# is specified, a minimum extent is also possible.


# Alternatives:
#  - proportionalWidth notNil, fixedWidth notNil ->    Use fraction of available space, take fixedWidth as minimum desired width
#  - proportionalWidth isNil, fixedWidth isNil   ->    Use current morph width
#  - proportionalWidth isNil, fixedWidth notNil    ->    Use fixedWidth
#  - proportionalWidth notNil, fixedWidth isNil    ->    NOT VALID

#Same goes for proportionalHeight and fixedHeight

class LayoutSpec
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  morph: null
  minorDirectionPadding: 0.5
  fixedWidth: 0
  fixedHeight: 0
  proportionalWidth: 1.0
  proportionalHeight: 1.0


  # Just some reasonable defaults, use all available space
  constructor: ->

  @newWithFixedExtent: (aPoint) ->
    @newWithFixedWidthFixedHeight(aPoint.x, aPoint.y)

  @newWithFixedHeight: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.setFixedHeight aNumber
   return layoutSpec

  @newWithFixedWidth: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.setFixedWidth aNumber
   return layoutSpec

  @newWithFixedWidthFixedHeight: (aNumber, otherNumber) ->
   layoutSpec = new @()
   layoutSpec.setFixedWidth aNumber
   layoutSpec.setFixedHeight otherNumber
   return layoutSpec

  @newWithFixedWidthFixedHeightMinorDirectionPadding: (aNumber, otherNumber, aSymbolOrNumber) ->
   layoutSpec = new @()
   layoutSpec.setFixedWidth aNumber
   layoutSpec.setFixedHeight otherNumber
   layoutSpec.setMinorDirectionPadding aSymbolOrNumber
   return layoutSpec

  @newWithFixedWidthProportionalHeight: (aNumber, otherNumber) ->
   layoutSpec = new @()
   layoutSpec.setFixedWidth aNumber
   layoutSpec.setProportionalHeight otherNumber
   return layoutSpec

  @newWithFixedWidthProportionalHeightMinorDirectionPadding: (aNumber, otherNumber, aSymbolOrNumber) ->
   layoutSpec = new @()
   layoutSpec.setFixedWidth aNumber
   layoutSpec.setProportionalHeight otherNumber
   layoutSpec.setMinorDirectionPadding aSymbolOrNumber
   return layoutSpec

  @newWithKeepMorphExtent: ->
   layoutSpec = new @()
   layoutSpec.useMorphWidth
   layoutSpec.useMorphHeight
   return layoutSpec

  @newWithMorphHeightFixedWidth: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.setFixedWidth aNumber
   layoutSpec.useMorphHeight
   return layoutSpec

  @newWithMorphHeightProportionalWidth: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.setProportionalWidth aNumber
   layoutSpec.useMorphHeight()
   return layoutSpec

  @newWithMorphWidthFixedHeight: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.useMorphWidth()
   layoutSpec.setFixedHeight aNumber
   return layoutSpec

  @newWithMorphWidthProportionalHeight: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.useMorphWidth()
   layoutSpec.setProportionalHeight aNumber
   return layoutSpec

  # Will use all available width
  @newWithProportionalHeight: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.setProportionalHeight aNumber
   return layoutSpec

  # Will use all available height
  @newWithProportionalWidth: (aNumber) ->
   layoutSpec = new @()
   layoutSpec.setProportionalWidth aNumber
   return layoutSpec

  @newWithProportionalWidthFixedHeight: (aNumber, otherNumber) ->
   layoutSpec = new @()
   layoutSpec.setProportionalWidth aNumber
   layoutSpec.setFixedHeight otherNumber
   return layoutSpec

  @newWithProportionalWidthFixedHeightMinorDirectionPadding: (aNumber, otherNumber, aSymbolOrNumber) ->
   layoutSpec = new @()
   layoutSpec.setProportionalWidth aNumber
   layoutSpec.setFixedHeight otherNumber
   layoutSpec.setMinorDirectionPadding aSymbolOrNumber
   return layoutSpec

  @newWithProportionalWidthProportionalHeight: (aNumber, otherNumber) ->
   layoutSpec = new @()
   layoutSpec.setProportionalWidth aNumber
   layoutSpec.setProportionalHeight otherNumber
   return layoutSpec

  @newWithProportionalWidthProportionalHeightMinorDirectionPadding: (aNumber, otherNumber, aSymbolOrNumber) ->
   layoutSpec = new @()
   layoutSpec.setProportionalWidth aNumber
   layoutSpec.setProportionalHeight otherNumber
   layoutSpec.setMinorDirectionPadding aSymbolOrNumber
   return layoutSpec

  # Use all available space
  @newWithUseAll: ->
   return new @()

  setFixedHeight: (aNumber) ->
   # aNumber is taken as the fixed height to use.
   # No proportional part.
   @fixedHeight = aNumber
   @proportionalHeight = null

  setFixedOrMorphHeight: (aNumber) ->
    # aNumber is taken as the fixed height to use.
    # No proportional part.
    if @fixedHeight?
      @fixedHeight = aNumber
    else
      @morph.setHeight aNumber
    @proportionalHeight = null

  setFixedOrMorphWidth: (aNumber) ->
    # aNumber is taken as the fixed width to use.
    # No proportional part.
    if @fixedWidth?
      @fixedWidth = aNumber
    else
      @morph.setWidth aNumber
    @proportionalWidth = null

  setFixedWidth: (aNumber) ->
    # aNumber is taken as the fixed width to use.
    # No proportional part.
    @fixedWidth = aNumber
    @proportionalWidth = null

  setMinorDirectionPadding: (howMuchPadding) ->
    # This sets how padding is done in the secondary direction.
    # For instance, if the owning morph is set in a row,
    # the row will control horizontal layout. But if there
    # is unused vertical space, it will be used according to
    # this parameter. For instance, #top sets the owning morph
    # at the top. Same for #bottom and #center. If the owner is
    # contained in a column, #left, #center or #right should be
    # used. Alternatively, any number between 0.0 and 1.0 can be
    # used.
    #  self new minorDirectionPadding: #center
    #  self new minorDirectionPadding: 0.9

    switch howMuchPadding
      when "#top" then @minorDirectionPadding = 0.0
      when "#left" then @minorDirectionPadding = 0.0
      when "#center" then @minorDirectionPadding = 0.5
      when "#right" then @minorDirectionPadding = 1.0
      when "#bottom" then @minorDirectionPadding = 1.0
      else @minorDirectionPadding = howMuchPadding

  setProportionalHeight: (aNumber) ->
   @setProportionalHeightMinimum(aNumber, 0.0)

  setProportionalHeightMinimum: (aNumberOrNil, otherNumberOrNil) ->
    # Alternatives: same as in #proportionalWidth:minimum:
    # see comment there
    @proportionalHeight = aNumberOrNil
    @fixedHeight = otherNumberOrNil

  setProportionalWidth: (aNumber) ->
    return @setProportionalWidthMinimum aNumber, 0

  setProportionalWidthMinimum: (aNumberOrNil, otherNumberOrNil) ->
    # Alternatives:
    #  - proportionalWidth notNil, fixedWidth notNil ->    Use fraction of available space, take fixedWidth as minimum desired width
    #  - proportionalWidth isNil, fixedWidth isNil   ->    Use current morph width
    #  - proportionalWidth isNil, fixedWidth notNil  ->    Use fixedWidth
    #  - proportionalWidth notNil, fixedWidth isNil  ->    NOT VALID
    @proportionalWidth = aNumberOrNil
    @fixedWidth = otherNumberOrNil

  setProportionalHeight: (aNumberOrNil) ->
   # Alternatives: same as in #proportionalWidth:minimum:, see comment there
   @proportionalHeight = aNumberOrNil

  setProportionalWidth: (aNumberOrNil) ->
    # Alternatives:
    #  - proportionalWidth notNil, fixedWidth notNil ->    Use fraction of available space, take fixedWidth as minimum desired width
    #  - proportionalWidth isNil, fixedWidth isNil   ->    Use current morph width
    #  - proportionalWidth isNil, fixedWidth notNil  ->    Use fixedWidth
    #  - proportionalWidth notNil, fixedWidth isNil  ->    NOT VALID"
    @proportionalWidth = aNumberOrNil

  useMorphHeight: ->
    # Do not attempt to layout height. Use current morph height if at all possible
    @fixedHeight = null
    @proportionalHeight = null

  useMorphWidth: ->
    # Do not attempt to layout width. Use current morph width if at all possible
    @fixedWidth = null
    @proportionalWidth = null

  getFixedHeight: ->
    # If proportional is zero, answer stored fixed extent,
    # or actual morph extent if undefined. (no proportional extent is computed)
    # Otherwise, we do proportional layout, and the stored extent is
    # a minimum extent, so we don't  really a fixed extent.
    if @proportionalHeight?
      return 0
    if not @fixedHeight?
      return @morph.height()

  getFixedWidth: ->
    # If proportional is zero, answer stored fixed extent,
    # or actual morph extent if undefined. (no proportional extent is computed)
    # Otherwise, we do proportional layout, and the stored extent is
    # a minimum extent, so we don't  really a fixed extent.
    if @proportionalWidth?
      return 0
    if not @fixedWidth?
      return @morph.width()

  heightFor: (availableSpace) ->
    # If proportional is zero, answer stored fixed extent,
    # or actual morph extent if undefined.
    # Otherwise, we do proportional layout, and the stored
    # extent is a minimum extent.
    # If there is no minimum extent, it should be set to zero.

    if @proportionalHeight?
      return Math.max( @fixedHeight, Math.round(@proportionalHeight * availableSpace) )
    return @getFixedHeight()

  getFixedHeight: ->
    if not @fixedHeight?
      return 0
    else
      @fixedHeight

  getFixedWidth: ->
    if not @fixedWidth?
      return 0
    else
      @fixedWidth

  getProportionalHeight: ->
    if not @proportionalHeight?
      return 0
    else
      @proportionalHeight

  getProportionalWidth: ->
    if not @proportionalWidth?
      return 0
    else
      @proportionalWidth

  widthFor: (availableSpace) ->
    # If proportional is zero, answer stored fixed extent,
    # or actual morph extent if undefined.
    # Otherwise, we do proportional layout, and the
    # stored extent is a minimum extent.
    # If there is no minimum extent, it should be set to zero.
    if @proportionalWidth?
      return Math.max( @fixedWidth, Math.round(@proportionalWidth * availableSpace) )
    return @getFixedWidth()

  isProportionalHeight: ->
    return @proportionalHeight?

  isProportionalWidth: ->
    return @proportionalWidth?