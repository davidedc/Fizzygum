# IMMUTABLE

class Color

  @augmentWith DeepCopierMixin

  # "how can these constants be initialised when the Color class
  # is still being defined?" - you ask
  # Thanks for the question - there is a mechanism in Class
  # that looks for these kinds of pre-definition initialisations
  # and handles them by postponing them to after the class is defined

  # if you want values like these instead: aliceblue: "0xfff0f8ff"
  # then search for CoulourLiterals in LiveCodeLab repo
  @ALICEBLUE:            Color.create 0xf0,0xf8,0xff
  @ANTIQUEWHITE:         Color.create 0xfa,0xeb,0xd7
  @AQUA:                 Color.create 0x00,0xff,0xff
  @AQUAMARINE:           Color.create 0x7f,0xff,0xd4
  @AZURE:                Color.create 0xf0,0xff,0xff
  @BEIGE:                Color.create 0xf5,0xf5,0xdc
  @BISQUE:               Color.create 0xff,0xe4,0xc4
  @BLACK:                Color.create 0x00,0x00,0x00
  @BLANCHEDALMOND:       Color.create 0xff,0xeb,0xcd
  @BLUE:                 Color.create 0x00,0x00,0xff
  @BLUEVIOLET:           Color.create 0x8a,0x2b,0xe2
  @BROWN:                Color.create 0xa5,0x2a,0x2a
  @BURLYWOOD:            Color.create 0xde,0xb8,0x87
  @CADETBLUE:            Color.create 0x5f,0x9e,0xa0
  @CHARTREUSE:           Color.create 0x7f,0xff,0x00
  @CHOCOLATE:            Color.create 0xd2,0x69,0x1e
  @CORAL:                Color.create 0xff,0x7f,0x50
  @CORNFLOWERBLUE:       Color.create 0x64,0x95,0xed
  @CORNSILK:             Color.create 0xff,0xf8,0xdc
  @CRIMSON:              Color.create 0xdc,0x14,0x3c
  @CYAN:                 Color.create 0x00,0xff,0xff
  @DARKBLUE:             Color.create 0x00,0x00,0x8b
  @DARKCYAN:             Color.create 0x00,0x8b,0x8b
  @DARKGOLDENROD:        Color.create 0xb8,0x86,0x0b
  @DARKGRAY:             Color.create 0xa9,0xa9,0xa9
  @DARKGREY:             Color.create 0xa9,0xa9,0xa9
  @DARKGREEN:            Color.create 0x00,0x64,0x00
  @DARKKHAKI:            Color.create 0xbd,0xb7,0x6b
  @DARKMAGENTA:          Color.create 0x8b,0x00,0x8b
  @DARKOLIVEGREEN:       Color.create 0x55,0x6b,0x2f
  @DARKORANGE:           Color.create 0xff,0x8c,0x00
  @DARKORCHID:           Color.create 0x99,0x32,0xcc
  @DARKRED:              Color.create 0x8b,0x00,0x00
  @DARKSALMON:           Color.create 0xe9,0x96,0x7a
  @DARKSEAGREEN:         Color.create 0x8f,0xbc,0x8f
  @DARKSLATEBLUE:        Color.create 0x48,0x3d,0x8b
  @DARKSLATEGRAY:        Color.create 0x2f,0x4f,0x4f
  @DARKSLATEGREY:        Color.create 0x2f,0x4f,0x4f
  @DARKTURQUOISE:        Color.create 0x00,0xce,0xd1
  @DARKVIOLET:           Color.create 0x94,0x00,0xd3
  @DEEPPINK:             Color.create 0xff,0x14,0x93
  @DEEPSKYBLUE:          Color.create 0x00,0xbf,0xff
  @DIMGRAY:              Color.create 0x69,0x69,0x69
  @DIMGREY:              Color.create 0x69,0x69,0x69
  @DODGERBLUE:           Color.create 0x1e,0x90,0xff
  @FIREBRICK:            Color.create 0xb2,0x22,0x22
  @FLORALWHITE:          Color.create 0xff,0xfa,0xf0
  @FORESTGREEN:          Color.create 0x22,0x8b,0x22
  @FUCHSIA:              Color.create 0xff,0x00,0xff
  @GAINSBORO:            Color.create 0xdc,0xdc,0xdc
  @GHOSTWHITE:           Color.create 0xf8,0xf8,0xff
  @GOLD:                 Color.create 0xff,0xd7,0x00
  @GOLDENROD:            Color.create 0xda,0xa5,0x20
  @GRAY:                 Color.create 0x80,0x80,0x80
  @GREY:                 Color.create 0x80,0x80,0x80
  @GREEN:                Color.create 0x00,0x80,0x00
  @GREENYELLOW:          Color.create 0xad,0xff,0x2f
  @HONEYDEW:             Color.create 0xf0,0xff,0xf0
  @HOTPINK:              Color.create 0xff,0x69,0xb4
  @INDIANRED:            Color.create 0xcd,0x5c,0x5c
  @INDIGO:               Color.create 0x4b,0x00,0x82
  @IVORY:                Color.create 0xff,0xff,0xf0
  @KHAKI:                Color.create 0xf0,0xe6,0x8c
  @LAVENDER:             Color.create 0xe6,0xe6,0xfa
  @LAVENDERBLUSH:        Color.create 0xff,0xf0,0xf5
  @LAWNGREEN:            Color.create 0x7c,0xfc,0x00
  @LEMONCHIFFON:         Color.create 0xff,0xfa,0xcd
  @LIGHTBLUE:            Color.create 0xad,0xd8,0xe6
  @LIGHTCORAL:           Color.create 0xf0,0x80,0x80
  @LIGHTCYAN:            Color.create 0xe0,0xff,0xff
  @LIGHTGOLDENRODYELLOW: Color.create 0xfa,0xfa,0xd2
  @LIGHTGREY:            Color.create 0xd3,0xd3,0xd3
  @LIGHTGRAY:            Color.create 0xd3,0xd3,0xd3
  @LIGHTGREEN:           Color.create 0x90,0xee,0x90
  @LIGHTPINK:            Color.create 0xff,0xb6,0xc1
  @LIGHTSALMON:          Color.create 0xff,0xa0,0x7a
  @LIGHTSEAGREEN:        Color.create 0x20,0xb2,0xaa
  @LIGHTSKYBLUE:         Color.create 0x87,0xce,0xfa
  @LIGHTSLATEGRAY:       Color.create 0x77,0x88,0x99
  @LIGHTSLATEGREY:       Color.create 0x77,0x88,0x99
  @LIGHTSTEELBLUE:       Color.create 0xb0,0xc4,0xde
  @LIGHTYELLOW:          Color.create 0xff,0xff,0xe0
  @LIME:                 Color.create 0x00,0xff,0x00
  @LIMEGREEN:            Color.create 0x32,0xcd,0x32
  @LINEN:                Color.create 0xfa,0xf0,0xe6
  @MINTCREAM:            Color.create 0xf5,0xff,0xfa
  @MISTYROSE:            Color.create 0xff,0xe4,0xe1
  @MOCCASIN:             Color.create 0xff,0xe4,0xb5
  @NAVAJOWHITE:          Color.create 0xff,0xde,0xad
  @NAVY:                 Color.create 0x00,0x00,0x80
  @OLDLACE:              Color.create 0xfd,0xf5,0xe6
  @OLIVE:                Color.create 0x80,0x80,0x00
  @OLIVEDRAB:            Color.create 0x6b,0x8e,0x23
  @ORANGE:               Color.create 0xff,0xa5,0x00
  @ORANGERED:            Color.create 0xff,0x45,0x00
  @ORCHID:               Color.create 0xda,0x70,0xd6
  @PALEGOLDENROD:        Color.create 0xee,0xe8,0xaa
  @PALEGREEN:            Color.create 0x98,0xfb,0x98
  @PALETURQUOISE:        Color.create 0xaf,0xee,0xee
  @PALEVIOLETRED:        Color.create 0xd8,0x70,0x93
  @PAPAYAWHIP:           Color.create 0xff,0xef,0xd5
  @PEACHPUFF:            Color.create 0xff,0xda,0xb9
  @PERU:                 Color.create 0xcd,0x85,0x3f
  @PINK:                 Color.create 0xff,0xc0,0xcb
  @PLUM:                 Color.create 0xdd,0xa0,0xdd
  @POWDERBLUE:           Color.create 0xb0,0xe0,0xe6
  @PURPLE:               Color.create 0x80,0x00,0x80
  @RED:                  Color.create 0xff,0x00,0x00
  @ROSYBROWN:            Color.create 0xbc,0x8f,0x8f
  @ROYALBLUE:            Color.create 0x41,0x69,0xe1
  @SADDLEBROWN:          Color.create 0x8b,0x45,0x13
  @SALMON:               Color.create 0xfa,0x80,0x72
  @SANDYBROWN:           Color.create 0xf4,0xa4,0x60
  @SEAGREEN:             Color.create 0x2e,0x8b,0x57
  @SEASHELL:             Color.create 0xff,0xf5,0xee
  @SIENNA:               Color.create 0xa0,0x52,0x2d
  @SILVER:               Color.create 0xc0,0xc0,0xc0
  @SKYBLUE:              Color.create 0x87,0xce,0xeb
  @SLATEBLUE:            Color.create 0x6a,0x5a,0xcd
  @SLATEGRAY:            Color.create 0x70,0x80,0x90
  @SLATEGREY:            Color.create 0x70,0x80,0x90
  @SNOW:                 Color.create 0xff,0xfa,0xfa
  @SPRINGGREEN:          Color.create 0x00,0xff,0x7f
  @STEELBLUE:            Color.create 0x46,0x82,0xb4
  @TAN:                  Color.create 0xd2,0xb4,0x8c
  @TEAL:                 Color.create 0x00,0x80,0x80
  @THISTLE:              Color.create 0xd8,0xbf,0xd8
  @TOMATO:               Color.create 0xff,0x63,0x47
  @TURQUOISE:            Color.create 0x40,0xe0,0xd0
  @VIOLET:               Color.create 0xee,0x82,0xee
  @WHEAT:                Color.create 0xf5,0xde,0xb3
  @WHITE:                Color.create 0xff,0xff,0xff
  @WHITESMOKE:           Color.create 0xf5,0xf5,0xf5
  @YELLOW:               Color.create 0xff,0xff,0x00
  @YELLOWGREEN:          Color.create 0x9a,0xcd,0x32

  @TRANSPARENT:          Color.create 0,0,0,0

  # anglecolor is a special
  # color that tells the engine to use the
  # normal material.
  # It would be tempting to set it to a numeric value such as
  # 1 unit higher than then any max 32 bit integer, but it's such a special
  # case that it's OK to use a non-integer.
  # TODO this is not an actual Color, breaks equality, can we do something else?
  @ANGLECOLOR:           "angleColor"

  @_cache: new LRUCache 300, 1000*60*60*24

  # params as in the HTML rgba() function
  # https://www.w3schools.com/cssref/func_rgba.asp
  _r: nil # intensity of red as an integer between 0 and 255
  _g: nil # intensity of green as an integer between 0 and 255
  _b: nil # intensity of blue as an integer between 0 and 255
  _a: nil # opacity as a number between 0.0 (fully transparent) and 1.0 (fully opaque)

  # all values are optional, just (r, g, b) is fine
  # this should ONLY be used from the "synthetic" constructors
  # the reason being that from the "synthetic" constructors you can
  # go through a cache so you try to keep only ONE instance
  # of each color, say, BLACK, in the system.
  constructor: (@_r = 0, @_g = 0, @_b = 0, @_a = 1) ->
    @_r = Math.round(@_r)
    @_g = Math.round(@_g)
    @_b = Math.round(@_b)

  # synthetic constructor - this is the one that should be used all the
  # times - caches constructed colors, since they are immutable
  @create: (r = 0, g = 0, b = 0, a = 1) ->
    r = Math.round r
    g = Math.round g
    b = Math.round b

    cacheKey = r + "," + g + "," + b + "," + a
    cacheEntry = @_cache.get cacheKey
    if !cacheEntry?
      cacheEntry = new @ r, g, b, a
      @_cache.set cacheKey, cacheEntry
    return cacheEntry

  bluerBy: (howMuchMoreBlue) ->
    new @constructor @_r, @_g, (@_b+howMuchMoreBlue), @_a
  
  # Color string representation: e.g. 'rgba(255,165,0,1)'
  toString: ->
    "rgba(" + Math.round(@_r) + "," + Math.round(@_g) + "," + Math.round(@_b) + "," + @_a + ")"


  # »>> this part is excluded from the fizzygum homepage build
  # currently unused. Also: duplicated function
  prepareBeforeSerialization: ->
    @className = @constructor.name
    @classVersion = "0.0.1"
    @serializerVersion = "0.0.1"
    for property of @
      if @[property]?
        if typeof @[property] == 'object'
          if !@[property].className?
            if @[property].prepareBeforeSerialization?
              @[property].prepareBeforeSerialization()
  # this part is excluded from the fizzygum homepage build <<«
  
  # Color comparison:
  equals: (aColor) ->
    @==aColor or (aColor and @_r == aColor._r and @_g == aColor._g and @_b == aColor._b and @_a == aColor._a)
  
  
  # »>> this part is excluded from the fizzygum homepage build
  
  # Color mixing:
  # currently unused
  mixed: (proportion, otherColor) ->
    # answer a copy of this color mixed with another color, ignore alpha
    frac1 = Math.min Math.max(proportion, 0), 1
    frac2 = 1 - frac1
    new @constructor(
      @_r * frac1 + otherColor._r * frac2
      @_g * frac1 + otherColor._g * frac2
      @_b * frac1 + otherColor._b * frac2
      @_a * frac1 + otherColor._a * frac2)
  
  # currently unused
  darker: (percent) ->
    # return an rgb-interpolated darker copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, @constructor.BLACK
  
  # currently unused
  lighter: (percent) ->
    # return an rgb-interpolated lighter copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, @constructor.WHITE
  
  # this part is excluded from the fizzygum homepage build <<«
