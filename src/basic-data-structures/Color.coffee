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
  @ALICEBLUE:            new Color 0xf0,0xf8,0xff
  @ANTIQUEWHITE:         new Color 0xfa,0xeb,0xd7
  @AQUA:                 new Color 0x00,0xff,0xff
  @AQUAMARINE:           new Color 0x7f,0xff,0xd4
  @AZURE:                new Color 0xf0,0xff,0xff
  @BEIGE:                new Color 0xf5,0xf5,0xdc
  @BISQUE:               new Color 0xff,0xe4,0xc4
  @BLACK:                new Color 0x00,0x00,0x00
  @BLANCHEDALMOND:       new Color 0xff,0xeb,0xcd
  @BLUE:                 new Color 0x00,0x00,0xff
  @BLUEVIOLET:           new Color 0x8a,0x2b,0xe2
  @BROWN:                new Color 0xa5,0x2a,0x2a
  @BURLYWOOD:            new Color 0xde,0xb8,0x87
  @CADETBLUE:            new Color 0x5f,0x9e,0xa0
  @CHARTREUSE:           new Color 0x7f,0xff,0x00
  @CHOCOLATE:            new Color 0xd2,0x69,0x1e
  @CORAL:                new Color 0xff,0x7f,0x50
  @CORNFLOWERBLUE:       new Color 0x64,0x95,0xed
  @CORNSILK:             new Color 0xff,0xf8,0xdc
  @CRIMSON:              new Color 0xdc,0x14,0x3c
  @CYAN:                 new Color 0x00,0xff,0xff
  @DARKBLUE:             new Color 0x00,0x00,0x8b
  @DARKCYAN:             new Color 0x00,0x8b,0x8b
  @DARKGOLDENROD:        new Color 0xb8,0x86,0x0b
  @DARKGRAY:             new Color 0xa9,0xa9,0xa9
  @DARKGREY:             new Color 0xa9,0xa9,0xa9
  @DARKGREEN:            new Color 0x00,0x64,0x00
  @DARKKHAKI:            new Color 0xbd,0xb7,0x6b
  @DARKMAGENTA:          new Color 0x8b,0x00,0x8b
  @DARKOLIVEGREEN:       new Color 0x55,0x6b,0x2f
  @DARKORANGE:           new Color 0xff,0x8c,0x00
  @DARKORCHID:           new Color 0x99,0x32,0xcc
  @DARKRED:              new Color 0x8b,0x00,0x00
  @DARKSALMON:           new Color 0xe9,0x96,0x7a
  @DARKSEAGREEN:         new Color 0x8f,0xbc,0x8f
  @DARKSLATEBLUE:        new Color 0x48,0x3d,0x8b
  @DARKSLATEGRAY:        new Color 0x2f,0x4f,0x4f
  @DARKSLATEGREY:        new Color 0x2f,0x4f,0x4f
  @DARKTURQUOISE:        new Color 0x00,0xce,0xd1
  @DARKVIOLET:           new Color 0x94,0x00,0xd3
  @DEEPPINK:             new Color 0xff,0x14,0x93
  @DEEPSKYBLUE:          new Color 0x00,0xbf,0xff
  @DIMGRAY:              new Color 0x69,0x69,0x69
  @DIMGREY:              new Color 0x69,0x69,0x69
  @DODGERBLUE:           new Color 0x1e,0x90,0xff
  @FIREBRICK:            new Color 0xb2,0x22,0x22
  @FLORALWHITE:          new Color 0xff,0xfa,0xf0
  @FORESTGREEN:          new Color 0x22,0x8b,0x22
  @FUCHSIA:              new Color 0xff,0x00,0xff
  @GAINSBORO:            new Color 0xdc,0xdc,0xdc
  @GHOSTWHITE:           new Color 0xf8,0xf8,0xff
  @GOLD:                 new Color 0xff,0xd7,0x00
  @GOLDENROD:            new Color 0xda,0xa5,0x20
  @GRAY:                 new Color 0x80,0x80,0x80
  @GREY:                 new Color 0x80,0x80,0x80
  @GREEN:                new Color 0x00,0x80,0x00
  @GREENYELLOW:          new Color 0xad,0xff,0x2f
  @HONEYDEW:             new Color 0xf0,0xff,0xf0
  @HOTPINK:              new Color 0xff,0x69,0xb4
  @INDIANRED:            new Color 0xcd,0x5c,0x5c
  @INDIGO:               new Color 0x4b,0x00,0x82
  @IVORY:                new Color 0xff,0xff,0xf0
  @KHAKI:                new Color 0xf0,0xe6,0x8c
  @LAVENDER:             new Color 0xe6,0xe6,0xfa
  @LAVENDERBLUSH:        new Color 0xff,0xf0,0xf5
  @LAWNGREEN:            new Color 0x7c,0xfc,0x00
  @LEMONCHIFFON:         new Color 0xff,0xfa,0xcd
  @LIGHTBLUE:            new Color 0xad,0xd8,0xe6
  @LIGHTCORAL:           new Color 0xf0,0x80,0x80
  @LIGHTCYAN:            new Color 0xe0,0xff,0xff
  @LIGHTGOLDENRODYELLOW: new Color 0xfa,0xfa,0xd2
  @LIGHTGREY:            new Color 0xd3,0xd3,0xd3
  @LIGHTGRAY:            new Color 0xd3,0xd3,0xd3
  @LIGHTGREEN:           new Color 0x90,0xee,0x90
  @LIGHTPINK:            new Color 0xff,0xb6,0xc1
  @LIGHTSALMON:          new Color 0xff,0xa0,0x7a
  @LIGHTSEAGREEN:        new Color 0x20,0xb2,0xaa
  @LIGHTSKYBLUE:         new Color 0x87,0xce,0xfa
  @LIGHTSLATEGRAY:       new Color 0x77,0x88,0x99
  @LIGHTSLATEGREY:       new Color 0x77,0x88,0x99
  @LIGHTSTEELBLUE:       new Color 0xb0,0xc4,0xde
  @LIGHTYELLOW:          new Color 0xff,0xff,0xe0
  @LIME:                 new Color 0x00,0xff,0x00
  @LIMEGREEN:            new Color 0x32,0xcd,0x32
  @LINEN:                new Color 0xfa,0xf0,0xe6
  @MINTCREAM:            new Color 0xf5,0xff,0xfa
  @MISTYROSE:            new Color 0xff,0xe4,0xe1
  @MOCCASIN:             new Color 0xff,0xe4,0xb5
  @NAVAJOWHITE:          new Color 0xff,0xde,0xad
  @NAVY:                 new Color 0x00,0x00,0x80
  @OLDLACE:              new Color 0xfd,0xf5,0xe6
  @OLIVE:                new Color 0x80,0x80,0x00
  @OLIVEDRAB:            new Color 0x6b,0x8e,0x23
  @ORANGE:               new Color 0xff,0xa5,0x00
  @ORANGERED:            new Color 0xff,0x45,0x00
  @ORCHID:               new Color 0xda,0x70,0xd6
  @PALEGOLDENROD:        new Color 0xee,0xe8,0xaa
  @PALEGREEN:            new Color 0x98,0xfb,0x98
  @PALETURQUOISE:        new Color 0xaf,0xee,0xee
  @PALEVIOLETRED:        new Color 0xd8,0x70,0x93
  @PAPAYAWHIP:           new Color 0xff,0xef,0xd5
  @PEACHPUFF:            new Color 0xff,0xda,0xb9
  @PERU:                 new Color 0xcd,0x85,0x3f
  @PINK:                 new Color 0xff,0xc0,0xcb
  @PLUM:                 new Color 0xdd,0xa0,0xdd
  @POWDERBLUE:           new Color 0xb0,0xe0,0xe6
  @PURPLE:               new Color 0x80,0x00,0x80
  @RED:                  new Color 0xff,0x00,0x00
  @ROSYBROWN:            new Color 0xbc,0x8f,0x8f
  @ROYALBLUE:            new Color 0x41,0x69,0xe1
  @SADDLEBROWN:          new Color 0x8b,0x45,0x13
  @SALMON:               new Color 0xfa,0x80,0x72
  @SANDYBROWN:           new Color 0xf4,0xa4,0x60
  @SEAGREEN:             new Color 0x2e,0x8b,0x57
  @SEASHELL:             new Color 0xff,0xf5,0xee
  @SIENNA:               new Color 0xa0,0x52,0x2d
  @SILVER:               new Color 0xc0,0xc0,0xc0
  @SKYBLUE:              new Color 0x87,0xce,0xeb
  @SLATEBLUE:            new Color 0x6a,0x5a,0xcd
  @SLATEGRAY:            new Color 0x70,0x80,0x90
  @SLATEGREY:            new Color 0x70,0x80,0x90
  @SNOW:                 new Color 0xff,0xfa,0xfa
  @SPRINGGREEN:          new Color 0x00,0xff,0x7f
  @STEELBLUE:            new Color 0x46,0x82,0xb4
  @TAN:                  new Color 0xd2,0xb4,0x8c
  @TEAL:                 new Color 0x00,0x80,0x80
  @THISTLE:              new Color 0xd8,0xbf,0xd8
  @TOMATO:               new Color 0xff,0x63,0x47
  @TURQUOISE:            new Color 0x40,0xe0,0xd0
  @VIOLET:               new Color 0xee,0x82,0xee
  @WHEAT:                new Color 0xf5,0xde,0xb3
  @WHITE:                new Color 0xff,0xff,0xff
  @WHITESMOKE:           new Color 0xf5,0xf5,0xf5
  @YELLOW:               new Color 0xff,0xff,0x00
  @YELLOWGREEN:          new Color 0x9a,0xcd,0x32

  @TRANSPARENT:          new Color 0,0,0,0

  # anglecolor is a special
  # color that tells the engine to use the
  # normal material.
  # It would be tempting to set it to a numeric value such as
  # 1 unit higher than then any max 32 bit integer, but it's such a special
  # case that it's OK to use a non-integer.
  # TODO this is not an actual Color, breaks equality, can we do something else?
  @ANGLECOLOR:           "angleColor"


  # TODO
  @AVAILABLE_LITERALS_NAMES: []

  @_cache: nil


  # params as in the HTML rgba() function
  # https://www.w3schools.com/cssref/func_rgba.asp
  _r: nil # intensity of red as an integer between 0 and 255
  _g: nil # intensity of green as an integer between 0 and 255
  _b: nil # intensity of blue as an integer between 0 and 255
  _a: nil # opacity as a number between 0.0 (fully transparent) and 1.0 (fully opaque)

  # all values are optional, just (r, g, b) is fine
  constructor: (@_r = 0, @_g = 0, @_b = 0, @_a = 1) ->
    @_r = Math.round(@_r)
    @_g = Math.round(@_g)
    @_b = Math.round(@_b)

  # draft code to cache constructed colors since they are immutable
  #@create: (r = 0, g = 0, b = 0, a = 1) ->
  #  if !@_cache then @_cache = new LRUCache 300, 1000*60*60*24
  #  cacheKey = Math.round(r) + "," + Math.round(g) + "," + Math.round(b) + "," + a
  #  cachedColor = @_cache.get cacheKey
  #  cacheEntry = new @ r, g, b, a
  #  @_cache.set cacheKey, cacheEntry
  #  return cacheEntry

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
