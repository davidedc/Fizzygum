# IMMUTABLE

class Color

  # "how can these constants be initialised when the Color class
  # is still being defined?" - you ask
  # Thanks for the question - there is a mechanism in Class
  # that looks for these kinds of pre-definition initialisations
  # and handles them by postponing them to after the class is defined

  # if you want values like these instead: aliceblue: "0xfff0f8ff"
  # then search for CoulourLiterals in LiveCodeLab repo
  @ALICEBLUE:            Color.createConstant 0xf0,0xf8,0xff
  @ANTIQUEWHITE:         Color.createConstant 0xfa,0xeb,0xd7
  @AQUA:                 Color.createConstant 0x00,0xff,0xff
  @AQUAMARINE:           Color.createConstant 0x7f,0xff,0xd4
  @AZURE:                Color.createConstant 0xf0,0xff,0xff
  @BEIGE:                Color.createConstant 0xf5,0xf5,0xdc
  @BISQUE:               Color.createConstant 0xff,0xe4,0xc4
  @BLACK:                Color.createConstant 0x00,0x00,0x00
  @BLANCHEDALMOND:       Color.createConstant 0xff,0xeb,0xcd
  @BLUE:                 Color.createConstant 0x00,0x00,0xff
  @BLUEVIOLET:           Color.createConstant 0x8a,0x2b,0xe2
  @BROWN:                Color.createConstant 0xa5,0x2a,0x2a
  @BURLYWOOD:            Color.createConstant 0xde,0xb8,0x87
  @CADETBLUE:            Color.createConstant 0x5f,0x9e,0xa0
  @CHARTREUSE:           Color.createConstant 0x7f,0xff,0x00
  @CHOCOLATE:            Color.createConstant 0xd2,0x69,0x1e
  @CORAL:                Color.createConstant 0xff,0x7f,0x50
  @CORNFLOWERBLUE:       Color.createConstant 0x64,0x95,0xed
  @CORNSILK:             Color.createConstant 0xff,0xf8,0xdc
  @CRIMSON:              Color.createConstant 0xdc,0x14,0x3c
  @CYAN:                 Color.createConstant 0x00,0xff,0xff
  @DARKBLUE:             Color.createConstant 0x00,0x00,0x8b
  @DARKCYAN:             Color.createConstant 0x00,0x8b,0x8b
  @DARKGOLDENROD:        Color.createConstant 0xb8,0x86,0x0b
  @DARKGRAY:             Color.createConstant 0xa9,0xa9,0xa9
  @DARKGREY:             Color.createConstant 0xa9,0xa9,0xa9
  @DARKGREEN:            Color.createConstant 0x00,0x64,0x00
  @DARKKHAKI:            Color.createConstant 0xbd,0xb7,0x6b
  @DARKMAGENTA:          Color.createConstant 0x8b,0x00,0x8b
  @DARKOLIVEGREEN:       Color.createConstant 0x55,0x6b,0x2f
  @DARKORANGE:           Color.createConstant 0xff,0x8c,0x00
  @DARKORCHID:           Color.createConstant 0x99,0x32,0xcc
  @DARKRED:              Color.createConstant 0x8b,0x00,0x00
  @DARKSALMON:           Color.createConstant 0xe9,0x96,0x7a
  @DARKSEAGREEN:         Color.createConstant 0x8f,0xbc,0x8f
  @DARKSLATEBLUE:        Color.createConstant 0x48,0x3d,0x8b
  @DARKSLATEGRAY:        Color.createConstant 0x2f,0x4f,0x4f
  @DARKSLATEGREY:        Color.createConstant 0x2f,0x4f,0x4f
  @DARKTURQUOISE:        Color.createConstant 0x00,0xce,0xd1
  @DARKVIOLET:           Color.createConstant 0x94,0x00,0xd3
  @DEEPPINK:             Color.createConstant 0xff,0x14,0x93
  @DEEPSKYBLUE:          Color.createConstant 0x00,0xbf,0xff
  @DIMGRAY:              Color.createConstant 0x69,0x69,0x69
  @DIMGREY:              Color.createConstant 0x69,0x69,0x69
  @DODGERBLUE:           Color.createConstant 0x1e,0x90,0xff
  @FIREBRICK:            Color.createConstant 0xb2,0x22,0x22
  @FLORALWHITE:          Color.createConstant 0xff,0xfa,0xf0
  @FORESTGREEN:          Color.createConstant 0x22,0x8b,0x22
  @FUCHSIA:              Color.createConstant 0xff,0x00,0xff
  @GAINSBORO:            Color.createConstant 0xdc,0xdc,0xdc
  @GHOSTWHITE:           Color.createConstant 0xf8,0xf8,0xff
  @GOLD:                 Color.createConstant 0xff,0xd7,0x00
  @GOLDENROD:            Color.createConstant 0xda,0xa5,0x20
  @GRAY:                 Color.createConstant 0x80,0x80,0x80
  @GREY:                 Color.createConstant 0x80,0x80,0x80
  @GREEN:                Color.createConstant 0x00,0x80,0x00
  @GREENYELLOW:          Color.createConstant 0xad,0xff,0x2f
  @HONEYDEW:             Color.createConstant 0xf0,0xff,0xf0
  @HOTPINK:              Color.createConstant 0xff,0x69,0xb4
  @INDIANRED:            Color.createConstant 0xcd,0x5c,0x5c
  @INDIGO:               Color.createConstant 0x4b,0x00,0x82
  @IVORY:                Color.createConstant 0xff,0xff,0xf0
  @KHAKI:                Color.createConstant 0xf0,0xe6,0x8c
  @LAVENDER:             Color.createConstant 0xe6,0xe6,0xfa
  @LAVENDERBLUSH:        Color.createConstant 0xff,0xf0,0xf5
  @LAWNGREEN:            Color.createConstant 0x7c,0xfc,0x00
  @LEMONCHIFFON:         Color.createConstant 0xff,0xfa,0xcd
  @LIGHTBLUE:            Color.createConstant 0xad,0xd8,0xe6
  @LIGHTCORAL:           Color.createConstant 0xf0,0x80,0x80
  @LIGHTCYAN:            Color.createConstant 0xe0,0xff,0xff
  @LIGHTGOLDENRODYELLOW: Color.createConstant 0xfa,0xfa,0xd2
  @LIGHTGREY:            Color.createConstant 0xd3,0xd3,0xd3
  @LIGHTGRAY:            Color.createConstant 0xd3,0xd3,0xd3
  @LIGHTGREEN:           Color.createConstant 0x90,0xee,0x90
  @LIGHTPINK:            Color.createConstant 0xff,0xb6,0xc1
  @LIGHTSALMON:          Color.createConstant 0xff,0xa0,0x7a
  @LIGHTSEAGREEN:        Color.createConstant 0x20,0xb2,0xaa
  @LIGHTSKYBLUE:         Color.createConstant 0x87,0xce,0xfa
  @LIGHTSLATEGRAY:       Color.createConstant 0x77,0x88,0x99
  @LIGHTSLATEGREY:       Color.createConstant 0x77,0x88,0x99
  @LIGHTSTEELBLUE:       Color.createConstant 0xb0,0xc4,0xde
  @LIGHTYELLOW:          Color.createConstant 0xff,0xff,0xe0
  @LIME:                 Color.createConstant 0x00,0xff,0x00
  @LIMEGREEN:            Color.createConstant 0x32,0xcd,0x32
  @LINEN:                Color.createConstant 0xfa,0xf0,0xe6
  @MAGENTA:              Color.createConstant 0xff,0x00,0xff
  @MINTCREAM:            Color.createConstant 0xf5,0xff,0xfa
  @MISTYROSE:            Color.createConstant 0xff,0xe4,0xe1
  @MOCCASIN:             Color.createConstant 0xff,0xe4,0xb5
  @NAVAJOWHITE:          Color.createConstant 0xff,0xde,0xad
  @NAVY:                 Color.createConstant 0x00,0x00,0x80
  @OLDLACE:              Color.createConstant 0xfd,0xf5,0xe6
  @OLIVE:                Color.createConstant 0x80,0x80,0x00
  @OLIVEDRAB:            Color.createConstant 0x6b,0x8e,0x23
  @ORANGE:               Color.createConstant 0xff,0xa5,0x00
  @ORANGERED:            Color.createConstant 0xff,0x45,0x00
  @ORCHID:               Color.createConstant 0xda,0x70,0xd6
  @PALEGOLDENROD:        Color.createConstant 0xee,0xe8,0xaa
  @PALEGREEN:            Color.createConstant 0x98,0xfb,0x98
  @PALETURQUOISE:        Color.createConstant 0xaf,0xee,0xee
  @PALEVIOLETRED:        Color.createConstant 0xd8,0x70,0x93
  @PAPAYAWHIP:           Color.createConstant 0xff,0xef,0xd5
  @PEACHPUFF:            Color.createConstant 0xff,0xda,0xb9
  @PERU:                 Color.createConstant 0xcd,0x85,0x3f
  @PINK:                 Color.createConstant 0xff,0xc0,0xcb
  @PLUM:                 Color.createConstant 0xdd,0xa0,0xdd
  @POWDERBLUE:           Color.createConstant 0xb0,0xe0,0xe6
  @PURPLE:               Color.createConstant 0x80,0x00,0x80
  @RED:                  Color.createConstant 0xff,0x00,0x00
  @ROSYBROWN:            Color.createConstant 0xbc,0x8f,0x8f
  @ROYALBLUE:            Color.createConstant 0x41,0x69,0xe1
  @SADDLEBROWN:          Color.createConstant 0x8b,0x45,0x13
  @SALMON:               Color.createConstant 0xfa,0x80,0x72
  @SANDYBROWN:           Color.createConstant 0xf4,0xa4,0x60
  @SEAGREEN:             Color.createConstant 0x2e,0x8b,0x57
  @SEASHELL:             Color.createConstant 0xff,0xf5,0xee
  @SIENNA:               Color.createConstant 0xa0,0x52,0x2d
  @SILVER:               Color.createConstant 0xc0,0xc0,0xc0
  @SKYBLUE:              Color.createConstant 0x87,0xce,0xeb
  @SLATEBLUE:            Color.createConstant 0x6a,0x5a,0xcd
  @SLATEGRAY:            Color.createConstant 0x70,0x80,0x90
  @SLATEGREY:            Color.createConstant 0x70,0x80,0x90
  @SNOW:                 Color.createConstant 0xff,0xfa,0xfa
  @SPRINGGREEN:          Color.createConstant 0x00,0xff,0x7f
  @STEELBLUE:            Color.createConstant 0x46,0x82,0xb4
  @TAN:                  Color.createConstant 0xd2,0xb4,0x8c
  @TEAL:                 Color.createConstant 0x00,0x80,0x80
  @THISTLE:              Color.createConstant 0xd8,0xbf,0xd8
  @TOMATO:               Color.createConstant 0xff,0x63,0x47
  @TURQUOISE:            Color.createConstant 0x40,0xe0,0xd0
  @VIOLET:               Color.createConstant 0xee,0x82,0xee
  @WHEAT:                Color.createConstant 0xf5,0xde,0xb3
  @WHITE:                Color.createConstant 0xff,0xff,0xff
  @WHITESMOKE:           Color.createConstant 0xf5,0xf5,0xf5
  @YELLOW:               Color.createConstant 0xff,0xff,0x00
  @YELLOWGREEN:          Color.createConstant 0x9a,0xcd,0x32

  @TRANSPARENT:          Color.createConstant 0,0,0,0

  # anglecolor is a special
  # color that tells the engine to use the
  # normal material.
  # It would be tempting to set it to a numeric value such as
  # 1 unit higher than then any max 32 bit integer, but it's such a special
  # case that it's OK to use a non-integer.
  # TODO this is not an actual Color, breaks equality, can we do something else?
  @ANGLECOLOR:           "angleColor"

  @_cache: new LRUCache 300, 1000*60*60*24

  # permanent intern table for the named constants above: unlike @_cache (an LRU that
  # evicts and expires), an entry here is canonical for the whole session, so asking
  # @create for a constant's rgba values keeps returning THE constant instance (e.g.
  # Color.BLACK) no matter how many other colors get minted in between.
  @_permanent: {}

  # params as in the HTML rgba() function
  # https://www.w3schools.com/cssref/func_rgba.asp
  _r: undefined # intensity of red as an integer between 0 and 255
  _g: undefined # intensity of green as an integer between 0 and 255
  _b: undefined # intensity of blue as an integer between 0 and 255
  _a: undefined # opacity as a number between 0.0 (fully transparent) and 1.0 (fully opaque)

  _derived_String: undefined

  # all values are optional, just (r, g, b) is fine
  # this should ONLY be used from the static factories
  # the reason being that from the static factories you can
  # go through a cache so you try to keep only ONE instance
  # of each color, say, BLACK, in the system.
  constructor: (@_r = 0, @_g = 0, @_b = 0, @_a = 1) ->
    @_r = Math.round(@_r)
    @_g = Math.round(@_g)
    @_b = Math.round(@_b)

  # static factory - this is the one that should be used all the
  # times - caches constructed colors, since they are immutable
  # see https://stackoverflow.com/questions/929021/what-are-static-factory-methods
  @create: (r = 0, g = 0, b = 0, a = 1) ->
    r = Math.round r
    g = Math.round g
    b = Math.round b

    cacheKey = r + "," + g + "," + b + "," + a
    permanentEntry = @_permanent[cacheKey]
    return permanentEntry if permanentEntry?
    cacheEntry = @_cache.get cacheKey
    if !cacheEntry?
      cacheEntry = new @ r, g, b, a
      @_cache.set cacheKey, cacheEntry
    return cacheEntry

  # the permanent twin of @create, used by the named constants above: interns the color
  # in @_permanent (never evicted), keeping it THE canonical instance for its rgba
  # values however much the LRU churns. The key is derived from the constructed color's
  # own (rounded) fields so it always matches @create's key computation.
  @createConstant: (r = 0, g = 0, b = 0, a = 1) ->
    theColor = @create r, g, b, a
    @_permanent[theColor._r + "," + theColor._g + "," + theColor._b + "," + theColor._a] = theColor
    theColor

  # immutable + cached: routes through the shared @constructor.create factory (never
  # bare `new`, which would bypass the cache and the immutable-color dedupe)
  bluerBy: (howMuchMoreBlue) ->
    @constructor.create @_r, @_g, (@_b+howMuchMoreBlue), @_a
  
  # Color string representation: e.g. 'rgba(255,165,0,1)'
  toString: ->
    if !@_derived_String
      if @_a == 1
        @_derived_String = "rgb(" + Math.round(@_r) + "," + Math.round(@_g) + "," + Math.round(@_b) + ")"
      else
        @_derived_String = "rgba(" + Math.round(@_r) + "," + Math.round(@_g) + "," + Math.round(@_b) + "," + @_a + ")"
    return @_derived_String


  # Color comparison:
  equals: (aColor) ->
    @==aColor or (aColor and @_r == aColor._r and @_g == aColor._g and @_b == aColor._b and @_a == aColor._a)

  # Sum of absolute per-channel (RGB) differences to another colour — a cheap colour "distance" for
  # TOLERANCE comparisons where exact equality is too strict (e.g. a SystemTest checking a pick / blend
  # landed NEAR an expected colour, robust to sub-pixel float rounding). Alpha is ignored (the opaque
  # case). Public so a macro can read colour closeness without touching the private _r/_g/_b channels.
  channelDistanceTo: (aColor) ->
    Math.abs(@_r - aColor._r) + Math.abs(@_g - aColor._g) + Math.abs(@_b - aColor._b)

  # Am I fully see-through? Public for the same reason as channelDistanceTo: the alpha channel is
  # private, and the question gets asked from outside — a pixel READ that comes back fully
  # transparent generally means the sample point was off the buffer, not that anything was picked.
  isFullyTransparent: ->
    @_a == 0

  # Me as HSL: [hue 0..360, saturation 0..1, lightness 0..1], the standard sRGB conversion — i.e.
  # the exact inverse of the `hsl(h,s%,l%)` spelling. Public, and here rather than at its caller,
  # because reaching into _r/_g/_b from outside is precisely what channelDistanceTo above exists to
  # avoid; the palettes are the callers (ColorPaletteWdgt inverts its own hue x lightness field,
  # GrayPaletteWdgt only asks "is this achromatic?", i.e. saturation 0).
  #   An achromatic color has no hue and answers 0 — the conventional choice, and the one under
  # which black and white round-trip through hsl(0,100%,0%) / hsl(0,100%,100%).
  #   EXACTNESS, which the palette inverse leans on: a color spelled hsl(h,100%,l) always has
  # either min = 0 (l <= 50%) or max = 255 (l >= 50%) EVEN AFTER the browser rounds the channels to
  # integers, so its saturation here comes back as exactly 1 — no tolerance needed to recognise a
  # color as one of a fully-saturated field's own pixels.
  hueSaturationLightness: ->
    r = @_r / 255
    g = @_g / 255
    b = @_b / 255
    max = Math.max r, g, b
    min = Math.min r, g, b
    lightness = (max + min) / 2
    return [0, 0, lightness] if max == min
    delta = max - min
    saturation = if lightness > 0.5 then delta / (2 - max - min) else delta / (max + min)
    # The wrap on the red sextant is spelled out rather than written `%% 6`: CoffeeScript compiles
    # that operator into a `modulo` HELPER FUNCTION, and the meta-system strips the leading `var`
    # block (where helpers land) out of every member it compiles — Class._removeHelperFunctions —
    # so a `%%` in a class member becomes a call to something that does not exist. It survives the
    # build's syntax gate, because it is not a parse error.
    if max == r
      sextant = (g - b) / delta
      sextant += 6 if sextant < 0
    else if max == g
      sextant = (b - r) / delta + 2
    else
      sextant = (r - g) / delta + 4
    [sextant * 60, saturation, lightness]


  # Color mixing (dataflow spec §9.5 — the value-class method algebra a spreadsheet formula operates
  # with). Answer a NEW color that is this color blended with `otherColor`, `proportion` being THIS
  # color's weight: proportion = 1 ⇒ this color unchanged, 0 ⇒ otherColor, 0.5 ⇒ halfway. ALL FOUR
  # channels (r, g, b AND alpha) are linearly interpolated — a plain lerp, no channel special-cased
  # (the old "ignore alpha" comment contradicted the code; for the opaque colors spreadsheets use it
  # is moot anyway, so the general lerp wins and comment+code now agree). Immutable + cached: routes
  # through the shared @constructor.create factory (never bare `new`, which would bypass the cache and
  # the immutable-color dedupe). No longer homepage-excluded — it backs lighter/darker and the `mix`
  # formula helper, so it ships.
  mixed: (proportion, otherColor) ->
    frac1 = Math.min Math.max(proportion, 0), 1
    frac2 = 1 - frac1
    @constructor.create(
      @_r * frac1 + otherColor._r * frac2
      @_g * frac1 + otherColor._g * frac2
      @_b * frac1 + otherColor._b * frac2
      @_a * frac1 + otherColor._a * frac2)

  # A lighter shade: mix `amount` (0..1) of the way toward WHITE (0 ⇒ unchanged, 1 ⇒ white). A new
  # (cached) color — this one is never mutated.
  lighter: (amount = 0.5) ->
    @mixed 1 - amount, Color.WHITE

  # A darker shade: mix `amount` (0..1) of the way toward BLACK (0 ⇒ unchanged, 1 ⇒ black).
  darker: (amount = 0.5) ->
    @mixed 1 - amount, Color.BLACK

  # Spreadsheet presenter (dataflow spec §9.4): a cell whose value is a Color displays as a solid
  # swatch. Answer a fresh RectangleWdgt filled with this color; the sheet mounts it in the cell's
  # rect. Presentation knowledge lives HERE, on the value's class (live-editable via the meta system),
  # so the sheet asks the value how to present itself and never hard-codes "a Color is a swatch".
  # Immutability respected: setColor stores the shared color, it does not mutate it.
  cellPresenter: ->
    swatch = new RectangleWdgt
    swatch.setColor @
    swatch

  # Colors are immutable and cached (see @create): a deep COPY therefore returns the
  # SAME object rather than cloning it. The Duplicator consults this per-class shell
  # hook (Duplicator._shellFor), gets @ back, and its content-clone pass then only
  # self-assigns @'s own primitives, a no-op. Serialization is separate: it emits a
  # compact {class:"Color", rgba:[...]} record restored through @create — see
  # src/serialization/ and docs/architecture/serialization-duplication-reference.md §6.
  getEmptyObjectOfSameTypeAsThisOne: ->
    return @
