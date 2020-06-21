class Color

  @augmentWith DeepCopierMixin

  # if you want values like these instead: aliceblue: "0xfff0f8ff"
  # then search for CoulourLiterals in LiveCodeLab repo
  @byName_aliceblue:            [0xf0,0xf8,0xff]
  @byName_antiquewhite:         [0xfa,0xeb,0xd7]
  @byName_aqua:                 [0x00,0xff,0xff]
  @byName_aquamarine:           [0x7f,0xff,0xd4]
  @byName_azure:                [0xf0,0xff,0xff]
  @byName_beige:                [0xf5,0xf5,0xdc]
  @byName_bisque:               [0xff,0xe4,0xc4]
  @byName_black:                [0x00,0x00,0x00]
  @byName_blanchedalmond:       [0xff,0xeb,0xcd]
  @byName_blue:                 [0x00,0x00,0xff]
  @byName_blueviolet:           [0x8a,0x2b,0xe2]
  @byName_brown:                [0xa5,0x2a,0x2a]
  @byName_burlywood:            [0xde,0xb8,0x87]
  @byName_cadetblue:            [0x5f,0x9e,0xa0]
  @byName_chartreuse:           [0x7f,0xff,0x00]
  @byName_chocolate:            [0xd2,0x69,0x1e]
  @byName_coral:                [0xff,0x7f,0x50]
  @byName_cornflowerblue:       [0x64,0x95,0xed]
  @byName_cornsilk:             [0xff,0xf8,0xdc]
  @byName_crimson:              [0xdc,0x14,0x3c]
  @byName_cyan:                 [0x00,0xff,0xff]
  @byName_darkblue:             [0x00,0x00,0x8b]
  @byName_darkcyan:             [0x00,0x8b,0x8b]
  @byName_darkgoldenrod:        [0xb8,0x86,0x0b]
  @byName_darkgray:             [0xa9,0xa9,0xa9]
  @byName_darkgrey:             [0xa9,0xa9,0xa9]
  @byName_darkgreen:            [0x00,0x64,0x00]
  @byName_darkkhaki:            [0xbd,0xb7,0x6b]
  @byName_darkmagenta:          [0x8b,0x00,0x8b]
  @byName_darkolivegreen:       [0x55,0x6b,0x2f]
  @byName_darkorange:           [0xff,0x8c,0x00]
  @byName_darkorchid:           [0x99,0x32,0xcc]
  @byName_darkred:              [0x8b,0x00,0x00]
  @byName_darksalmon:           [0xe9,0x96,0x7a]
  @byName_darkseagreen:         [0x8f,0xbc,0x8f]
  @byName_darkslateblue:        [0x48,0x3d,0x8b]
  @byName_darkslategray:        [0x2f,0x4f,0x4f]
  @byName_darkslategrey:        [0x2f,0x4f,0x4f]
  @byName_darkturquoise:        [0x00,0xce,0xd1]
  @byName_darkviolet:           [0x94,0x00,0xd3]
  @byName_deeppink:             [0xff,0x14,0x93]
  @byName_deepskyblue:          [0x00,0xbf,0xff]
  @byName_dimgray:              [0x69,0x69,0x69]
  @byName_dimgrey:              [0x69,0x69,0x69]
  @byName_dodgerblue:           [0x1e,0x90,0xff]
  @byName_firebrick:            [0xb2,0x22,0x22]
  @byName_floralwhite:          [0xff,0xfa,0xf0]
  @byName_forestgreen:          [0x22,0x8b,0x22]
  @byName_fuchsia:              [0xff,0x00,0xff]
  @byName_gainsboro:            [0xdc,0xdc,0xdc]
  @byName_ghostwhite:           [0xf8,0xf8,0xff]
  @byName_gold:                 [0xff,0xd7,0x00]
  @byName_goldenrod:            [0xda,0xa5,0x20]
  @byName_gray:                 [0x80,0x80,0x80]
  @byName_grey:                 [0x80,0x80,0x80]
  @byName_green:                [0x00,0x80,0x00]
  @byName_greenyellow:          [0xad,0xff,0x2f]
  @byName_honeydew:             [0xf0,0xff,0xf0]
  @byName_hotpink:              [0xff,0x69,0xb4]
  @byName_indianred:            [0xcd,0x5c,0x5c]
  @byName_indigo:               [0x4b,0x00,0x82]
  @byName_ivory:                [0xff,0xff,0xf0]
  @byName_khaki:                [0xf0,0xe6,0x8c]
  @byName_lavender:             [0xe6,0xe6,0xfa]
  @byName_lavenderblush:        [0xff,0xf0,0xf5]
  @byName_lawngreen:            [0x7c,0xfc,0x00]
  @byName_lemonchiffon:         [0xff,0xfa,0xcd]
  @byName_lightblue:            [0xad,0xd8,0xe6]
  @byName_lightcoral:           [0xf0,0x80,0x80]
  @byName_lightcyan:            [0xe0,0xff,0xff]
  @byName_lightgoldenrodyellow: [0xfa,0xfa,0xd2]
  @byName_lightgrey:            [0xd3,0xd3,0xd3]
  @byName_lightgray:            [0xd3,0xd3,0xd3]
  @byName_lightgreen:           [0x90,0xee,0x90]
  @byName_lightpink:            [0xff,0xb6,0xc1]
  @byName_lightsalmon:          [0xff,0xa0,0x7a]
  @byName_lightseagreen:        [0x20,0xb2,0xaa]
  @byName_lightskyblue:         [0x87,0xce,0xfa]
  @byName_lightslategray:       [0x77,0x88,0x99]
  @byName_lightslategrey:       [0x77,0x88,0x99]
  @byName_lightsteelblue:       [0xb0,0xc4,0xde]
  @byName_lightyellow:          [0xff,0xff,0xe0]
  @byName_lime:                 [0x00,0xff,0x00]
  @byName_limegreen:            [0x32,0xcd,0x32]
  @byName_linen:                [0xfa,0xf0,0xe6]
  @byName_mintcream:            [0xf5,0xff,0xfa]
  @byName_mistyrose:            [0xff,0xe4,0xe1]
  @byName_moccasin:             [0xff,0xe4,0xb5]
  @byName_navajowhite:          [0xff,0xde,0xad]
  @byName_navy:                 [0x00,0x00,0x80]
  @byName_oldlace:              [0xfd,0xf5,0xe6]
  @byName_olive:                [0x80,0x80,0x00]
  @byName_olivedrab:            [0x6b,0x8e,0x23]
  @byName_orange:               [0xff,0xa5,0x00]
  @byName_orangered:            [0xff,0x45,0x00]
  @byName_orchid:               [0xda,0x70,0xd6]
  @byName_palegoldenrod:        [0xee,0xe8,0xaa]
  @byName_palegreen:            [0x98,0xfb,0x98]
  @byName_paleturquoise:        [0xaf,0xee,0xee]
  @byName_palevioletred:        [0xd8,0x70,0x93]
  @byName_papayawhip:           [0xff,0xef,0xd5]
  @byName_peachpuff:            [0xff,0xda,0xb9]
  @byName_peru:                 [0xcd,0x85,0x3f]
  @byName_pink:                 [0xff,0xc0,0xcb]
  @byName_plum:                 [0xdd,0xa0,0xdd]
  @byName_powderblue:           [0xb0,0xe0,0xe6]
  @byName_purple:               [0x80,0x00,0x80]
  @byName_red:                  [0xff,0x00,0x00]
  @byName_rosybrown:            [0xbc,0x8f,0x8f]
  @byName_royalblue:            [0x41,0x69,0xe1]
  @byName_saddlebrown:          [0x8b,0x45,0x13]
  @byName_salmon:               [0xfa,0x80,0x72]
  @byName_sandybrown:           [0xf4,0xa4,0x60]
  @byName_seagreen:             [0x2e,0x8b,0x57]
  @byName_seashell:             [0xff,0xf5,0xee]
  @byName_sienna:               [0xa0,0x52,0x2d]
  @byName_silver:               [0xc0,0xc0,0xc0]
  @byName_skyblue:              [0x87,0xce,0xeb]
  @byName_slateblue:            [0x6a,0x5a,0xcd]
  @byName_slategray:            [0x70,0x80,0x90]
  @byName_slategrey:            [0x70,0x80,0x90]
  @byName_snow:                 [0xff,0xfa,0xfa]
  @byName_springgreen:          [0x00,0xff,0x7f]
  @byName_steelblue:            [0x46,0x82,0xb4]
  @byName_tan:                  [0xd2,0xb4,0x8c]
  @byName_teal:                 [0x00,0x80,0x80]
  @byName_thistle:              [0xd8,0xbf,0xd8]
  @byName_tomato:               [0xff,0x63,0x47]
  @byName_turquoise:            [0x40,0xe0,0xd0]
  @byName_violet:               [0xee,0x82,0xee]
  @byName_wheat:                [0xf5,0xde,0xb3]
  @byName_white:                [0xff,0xff,0xff]
  @byName_whitesmoke:           [0xf5,0xf5,0xf5]
  @byName_yellow:               [0xff,0xff,0x00]
  @byName_yellowgreen:          [0x9a,0xcd,0x32]
  # anglecolor is a special
  # color that tells the engine to use the
  # normal material.
  # It would be tempting to set it to a numeric value such as
  # 1 unit higher than then any max 32 bit integer, but it's such a special
  # case that it's OK to use a non-integer.
  @byName_angleColor:           "angleColor"

  a: nil
  r: nil
  g: nil
  b: nil

  constructor: (@r = 0, @g = 0, @b = 0, a) ->
    # all values are optional, just (r, g, b) is fine
    @a = a or ((if (a is 0) then 0 else 1))
  
  # Color string representation: e.g. 'rgba(255,165,0,1)'
  toString: ->
    "rgba(" + Math.round(@r) + "," + Math.round(@g) + "," + Math.round(@b) + "," + @a + ")"


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
  
  # Color copying:
  copy: ->
    new @constructor @r, @g, @b, @a
  
  # Color comparison:
  eq: (aColor) ->
    # ==
    aColor and @r is aColor.r and @g is aColor.g and @b is aColor.b
  
  
  # »>> this part is excluded from the fizzygum homepage build
  # currently unused
  # Color conversion (hsv):
  hsv: ->
    # ignore alpha
    rr = @r / 255
    gg = @g / 255
    bb = @b / 255
    max = Math.max rr, gg, bb
    min = Math.min rr, gg, bb
    h = max
    v = max
    d = max - min
    s = (if max is 0 then 0 else d / max)
    if max is min
      h = 0
    else
      switch max
        when rr
          h = (gg - bb) / d + (if gg < bb then 6 else 0)
        when gg
          h = (bb - rr) / d + 2
        when bb
          h = (rr - gg) / d + 4
      h /= 6
    [h, s, v]
  
  # currently unused
  @fromHsv: (h, s, v) ->
    # ignore alpha
    # h, s and v are to be within [0, 1]
    i = Math.floor(h * 6)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    switch i % 6
      when 0
        r = v
        g = t
        b = p
      when 1
        r = q
        g = v
        b = p
      when 2
        r = p
        g = v
        b = t
      when 3
        r = p
        g = q
        b = v
      when 4
        r = t
        g = p
        b = v
      when 5
        r = v
        g = p
        b = q
    r *= 255
    g *= 255
    b *= 255
    new @constructor r, g, b
  
  
  # Color mixing:
  # currently unused
  mixed: (proportion, otherColor) ->
    # answer a copy of this color mixed with another color, ignore alpha
    frac1 = Math.min Math.max(proportion, 0), 1
    frac2 = 1 - frac1
    new @constructor(
      @r * frac1 + otherColor.r * frac2,
      @g * frac1 + otherColor.g * frac2,
      @b * frac1 + otherColor.b * frac2)
  
  # currently unused
  darker: (percent) ->
    # return an rgb-interpolated darker copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new @constructor 0, 0, 0
  
  # currently unused
  lighter: (percent) ->
    # return an rgb-interpolated lighter copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new @constructor 255, 255, 255
  
  # this part is excluded from the fizzygum homepage build <<«

  @transparent: ->
    return new @ 0,0,0,0

