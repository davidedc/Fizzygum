# LinearLayoutSpec

# this comment below is needed to figure out dependencies between classes

# This is a port of the LayoutSpec class from
# Cuis Smalltalk (version 4.2-1766)
# Cuis is by Juan Vuletich

# LinearLayoutSpecs are the basis for the layout mechanism.
# Any Morph can be given a LinearLayoutSpec, but in order to honor it,
# its owner must be a LinearLayoutMorph.

# A LinearLayoutSpec specifies how a morph wants to be laid out.
# It can specify either a fixed width or a fraction of some
# available owner width. Same goes for height. If a fraction
# is specified, a minimum extent is also possible.


# Alternatives:
#  - proportionalWidth notNil, fixedWidth notNil ->    Use fraction of available space, take fixedWidth as minimum desired width
#  - proportionalWidth isNil, fixedWidth isNil   ->    Use current morph width
#  - proportionalWidth isNil, fixedWidth notNil    ->    Use fixedWidth
#  - proportionalWidth notNil, fixedWidth isNil    ->    NOT VALID

#Same goes for proportionalHeight and fixedHeight

class LinearLayoutSpec
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  morph: null
  minorDirectionFloat: 0.5 # equivalent to "#center"
  fixedWidth: 0
  fixedHeight: 0
  proportionalWidth: 1.0
  proportionalHeight: 1.0
  category: 'Morphic-Layouts'


  # Just some reasonable defaults, use all available space
  constructor: ->

  @newWithFixedExtent: (aPoint) ->
    @newWithFixedWidthFixedHeight(aPoint.x, aPoint.y)

  @newWithFixedHeight: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setFixedHeight aNumber
   return linearLinearLayoutSpec

  @newWithFixedWidth: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setFixedWidth aNumber
   return linearLinearLayoutSpec

  @newWithFixedWidthFixedHeight: (aNumber, otherNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setFixedWidth aNumber
   linearLinearLayoutSpec.setFixedHeight otherNumber
   return linearLinearLayoutSpec

  @newWithFixedWidthFixedHeightMinorDirectionFloat: (aNumber, otherNumber, aSymbolOrNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setFixedWidth aNumber
   linearLinearLayoutSpec.setFixedHeight otherNumber
   linearLinearLayoutSpec.setMinorDirectionFloat aSymbolOrNumber
   return linearLinearLayoutSpec

  @newWithFixedWidthProportionalHeight: (aNumber, otherNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setFixedWidth aNumber
   linearLinearLayoutSpec.setProportionalHeight otherNumber
   return linearLinearLayoutSpec

  @newWithFixedWidthProportionalHeightMinorDirectionFloat: (aNumber, otherNumber, aSymbolOrNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setFixedWidth aNumber
   linearLinearLayoutSpec.setProportionalHeight otherNumber
   linearLinearLayoutSpec.setMinorDirectionFloat aSymbolOrNumber
   return linearLinearLayoutSpec

  @newWithKeepMorphExtent: ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.useMorphWidth
   linearLinearLayoutSpec.useMorphHeight
   return linearLinearLayoutSpec

  @newWithMorphHeightFixedWidth: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setFixedWidth aNumber
   linearLinearLayoutSpec.useMorphHeight
   return linearLinearLayoutSpec

  @newWithMorphHeightProportionalWidth: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setProportionalWidth aNumber
   linearLinearLayoutSpec.useMorphHeight()
   return linearLinearLayoutSpec

  @newWithMorphWidthFixedHeight: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.useMorphWidth()
   linearLinearLayoutSpec.setFixedHeight aNumber
   return linearLinearLayoutSpec

  @newWithMorphWidthProportionalHeight: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.useMorphWidth()
   linearLinearLayoutSpec.setProportionalHeight aNumber
   return linearLinearLayoutSpec

  # Will use all available width
  @newWithProportionalHeight: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setProportionalHeight aNumber
   return linearLinearLayoutSpec

  # Will use all available height
  @newWithProportionalWidth: (aNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setProportionalWidth aNumber
   return linearLinearLayoutSpec

  @newWithProportionalWidthFixedHeight: (aNumber, otherNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setProportionalWidth aNumber
   linearLinearLayoutSpec.setFixedHeight otherNumber
   return linearLinearLayoutSpec

  @newWithProportionalWidthFixedHeightMinorDirectionFloat: (aNumber, otherNumber, aSymbolOrNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setProportionalWidth aNumber
   linearLinearLayoutSpec.setFixedHeight otherNumber
   linearLinearLayoutSpec.setMinorDirectionFloat aSymbolOrNumber
   return linearLinearLayoutSpec

  @newWithProportionalWidthProportionalHeight: (aNumber, otherNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setProportionalWidth aNumber
   linearLinearLayoutSpec.setProportionalHeight otherNumber
   return linearLinearLayoutSpec

  @newWithProportionalWidthProportionalHeightMinorDirectionFloat: (aNumber, otherNumber, aSymbolOrNumber) ->
   linearLinearLayoutSpec = new @()
   linearLinearLayoutSpec.setProportionalWidth aNumber
   linearLinearLayoutSpec.setProportionalHeight otherNumber
   linearLinearLayoutSpec.setMinorDirectionFloat aSymbolOrNumber
   return linearLinearLayoutSpec

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

  setMinorDirectionFloat: (howMuchFloat) ->
    # This sets how float is done in the secondary direction.
    # For instance, if the owning morph is set in a row,
    # the row will control horizontal layout. But if there
    # is unused vertical space, it will be used according to
    # this parameter. For instance, #top sets the owning morph
    # at the top. Same for #bottom and #center. If the owner is
    # contained in a column, #left, #center or #right should be
    # used. Alternatively, any number between 0.0 and 1.0 can be
    # used.
    #  self new minorDirectionFloat: #center
    #  self new minorDirectionFloat: 0.9

    switch howMuchFloat
      when "#top" then @minorDirectionFloat = 0.0
      when "#left" then @minorDirectionFloat = 0.0
      when "#center" then @minorDirectionFloat = 0.5
      when "#right" then @minorDirectionFloat = 1.0
      when "#bottom" then @minorDirectionFloat = 1.0
      else @minorDirectionFloat = howMuchFloat

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