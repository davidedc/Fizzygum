# Colors //////////////////////////////////////////////////////////////

class Color

  # This "colourNamesValues" data
  # structure is only used to create
  # all the CSS color literals, like
  #   Color.red
  # This creation of constants
  # is done in WoldMorph, since
  # it's the first morph to be
  # created.
  # In pure theory we'd like these
  # constants to be created by a piece
  # of code at the end of the file, just
  # after the class definition,
  # unfortunately we can't add it there
  # as the source in this file is
  # appended as a further static variable
  # in this class, so we can't
  # "close" the class by adding code
  # that it's supposed to be outside its
  # definition.
  @colourNamesValues =
    aliceblue:            [0xf0,0xf8,0xff]
    antiquewhite:         [0xfa,0xeb,0xd7]
    aqua:                 [0x00,0xff,0xff]
    aquamarine:           [0x7f,0xff,0xd4]
    azure:                [0xf0,0xff,0xff]
    beige:                [0xf5,0xf5,0xdc]
    bisque:               [0xff,0xe4,0xc4]
    black:                [0x00,0x00,0x00]
    blanchedalmond:       [0xff,0xeb,0xcd]
    blue:                 [0x00,0x00,0xff]
    blueviolet:           [0x8a,0x2b,0xe2]
    brown:                [0xa5,0x2a,0x2a]
    burlywood:            [0xde,0xb8,0x87]
    cadetblue:            [0x5f,0x9e,0xa0]
    chartreuse:           [0x7f,0xff,0x00]
    chocolate:            [0xd2,0x69,0x1e]
    coral:                [0xff,0x7f,0x50]
    cornflowerblue:       [0x64,0x95,0xed]
    cornsilk:             [0xff,0xf8,0xdc]
    crimson:              [0xdc,0x14,0x3c]
    cyan:                 [0x00,0xff,0xff]
    darkblue:             [0x00,0x00,0x8b]
    darkcyan:             [0x00,0x8b,0x8b]
    darkgoldenrod:        [0xb8,0x86,0x0b]
    darkgray:             [0xa9,0xa9,0xa9]
    darkgrey:             [0xa9,0xa9,0xa9]
    darkgreen:            [0x00,0x64,0x00]
    darkkhaki:            [0xbd,0xb7,0x6b]
    darkmagenta:          [0x8b,0x00,0x8b]
    darkolivegreen:       [0x55,0x6b,0x2f]
    darkorange:           [0xff,0x8c,0x00]
    darkorchid:           [0x99,0x32,0xcc]
    darkred:              [0x8b,0x00,0x00]
    darksalmon:           [0xe9,0x96,0x7a]
    darkseagreen:         [0x8f,0xbc,0x8f]
    darkslateblue:        [0x48,0x3d,0x8b]
    darkslategray:        [0x2f,0x4f,0x4f]
    darkslategrey:        [0x2f,0x4f,0x4f]
    darkturquoise:        [0x00,0xce,0xd1]
    darkviolet:           [0x94,0x00,0xd3]
    deeppink:             [0xff,0x14,0x93]
    deepskyblue:          [0x00,0xbf,0xff]
    dimgray:              [0x69,0x69,0x69]
    dimgrey:              [0x69,0x69,0x69]
    dodgerblue:           [0x1e,0x90,0xff]
    firebrick:            [0xb2,0x22,0x22]
    floralwhite:          [0xff,0xfa,0xf0]
    forestgreen:          [0x22,0x8b,0x22]
    fuchsia:              [0xff,0x00,0xff]
    gainsboro:            [0xdc,0xdc,0xdc]
    ghostwhite:           [0xf8,0xf8,0xff]
    gold:                 [0xff,0xd7,0x00]
    goldenrod:            [0xda,0xa5,0x20]
    gray:                 [0x80,0x80,0x80]
    grey:                 [0x80,0x80,0x80]
    green:                [0x00,0x80,0x00]
    greenyellow:          [0xad,0xff,0x2f]
    honeydew:             [0xf0,0xff,0xf0]
    hotpink:              [0xff,0x69,0xb4]
    indianred:            [0xcd,0x5c,0x5c]
    indigo:               [0x4b,0x00,0x82]
    ivory:                [0xff,0xff,0xf0]
    khaki:                [0xf0,0xe6,0x8c]
    lavender:             [0xe6,0xe6,0xfa]
    lavenderblush:        [0xff,0xf0,0xf5]
    lawngreen:            [0x7c,0xfc,0x00]
    lemonchiffon:         [0xff,0xfa,0xcd]
    lightblue:            [0xad,0xd8,0xe6]
    lightcoral:           [0xf0,0x80,0x80]
    lightcyan:            [0xe0,0xff,0xff]
    lightgoldenrodyellow: [0xfa,0xfa,0xd2]
    lightgrey:            [0xd3,0xd3,0xd3]
    lightgray:            [0xd3,0xd3,0xd3]
    lightgreen:           [0x90,0xee,0x90]
    lightpink:            [0xff,0xb6,0xc1]
    lightsalmon:          [0xff,0xa0,0x7a]
    lightseagreen:        [0x20,0xb2,0xaa]
    lightskyblue:         [0x87,0xce,0xfa]
    lightslategray:       [0x77,0x88,0x99]
    lightslategrey:       [0x77,0x88,0x99]
    lightsteelblue:       [0xb0,0xc4,0xde]
    lightyellow:          [0xff,0xff,0xe0]
    lime:                 [0x00,0xff,0x00]
    limegreen:            [0x32,0xcd,0x32]
    linen:                [0xfa,0xf0,0xe6]
    mintcream:            [0xf5,0xff,0xfa]
    mistyrose:            [0xff,0xe4,0xe1]
    moccasin:             [0xff,0xe4,0xb5]
    navajowhite:          [0xff,0xde,0xad]
    navy:                 [0x00,0x00,0x80]
    oldlace:              [0xfd,0xf5,0xe6]
    olive:                [0x80,0x80,0x00]
    olivedrab:            [0x6b,0x8e,0x23]
    orange:               [0xff,0xa5,0x00]
    orangered:            [0xff,0x45,0x00]
    orchid:               [0xda,0x70,0xd6]
    palegoldenrod:        [0xee,0xe8,0xaa]
    palegreen:            [0x98,0xfb,0x98]
    paleturquoise:        [0xaf,0xee,0xee]
    palevioletred:        [0xd8,0x70,0x93]
    papayawhip:           [0xff,0xef,0xd5]
    peachpuff:            [0xff,0xda,0xb9]
    peru:                 [0xcd,0x85,0x3f]
    pink:                 [0xff,0xc0,0xcb]
    plum:                 [0xdd,0xa0,0xdd]
    powderblue:           [0xb0,0xe0,0xe6]
    purple:               [0x80,0x00,0x80]
    red:                  [0xff,0x00,0x00]
    rosybrown:            [0xbc,0x8f,0x8f]
    royalblue:            [0x41,0x69,0xe1]
    saddlebrown:          [0x8b,0x45,0x13]
    salmon:               [0xfa,0x80,0x72]
    sandybrown:           [0xf4,0xa4,0x60]
    seagreen:             [0x2e,0x8b,0x57]
    seashell:             [0xff,0xf5,0xee]
    sienna:               [0xa0,0x52,0x2d]
    silver:               [0xc0,0xc0,0xc0]
    skyblue:              [0x87,0xce,0xeb]
    slateblue:            [0x6a,0x5a,0xcd]
    slategray:            [0x70,0x80,0x90]
    slategrey:            [0x70,0x80,0x90]
    snow:                 [0xff,0xfa,0xfa]
    springgreen:          [0x00,0xff,0x7f]
    steelblue:            [0x46,0x82,0xb4]
    tan:                  [0xd2,0xb4,0x8c]
    teal:                 [0x00,0x80,0x80]
    thistle:              [0xd8,0xbf,0xd8]
    tomato:               [0xff,0x63,0x47]
    turquoise:            [0x40,0xe0,0xd0]
    violet:               [0xee,0x82,0xee]
    wheat:                [0xf5,0xde,0xb3]
    white:                [0xff,0xff,0xff]
    whitesmoke:           [0xf5,0xf5,0xf5]
    yellow:               [0xff,0xff,0x00]
    yellowgreen:          [0x9a,0xcd,0x32]

  a: null
  r: null
  g: null
  b: null

  constructor: (@r = 0, @g = 0, @b = 0, a) ->
    # all values are optional, just (r, g, b) is fine
    @a = a or ((if (a is 0) then 0 else 1))
  
  # Color string representation: e.g. 'rgba(255,165,0,1)'
  toString: ->
    "rgba(" + Math.round(@r) + "," + Math.round(@g) + "," + Math.round(@b) + "," + @a + ")"
  
  # Color copying:
  copy: ->
    new Color(@r, @g, @b, @a)
  
  # Color comparison:
  eq: (aColor) ->
    # ==
    aColor and @r is aColor.r and @g is aColor.g and @b is aColor.b
  
  
  # Color conversion (hsv):
  hsv: ->
    # ignore alpha
    rr = @r / 255
    gg = @g / 255
    bb = @b / 255
    max = Math.max(rr, gg, bb)
    min = Math.min(rr, gg, bb)
    h = max
    s = max
    v = max
    d = max - min
    s = (if max is 0 then 0 else d / max)
    if max is min
      h = 0
    else
      switch max
        when rr
          h = (gg - bb) / d + ((if gg < bb then 6 else 0))
        when gg
          h = (bb - rr) / d + 2
        when bb
          h = (rr - gg) / d + 4
      h /= 6
    [h, s, v]
  
  set_hsv: (h, s, v) ->
    # ignore alpha
    # h, s and v are to be within [0, 1]
    i = Math.floor(h * 6)
    f = h * 6 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    switch i % 6
      when 0
        @r = v
        @g = t
        @b = p
      when 1
        @r = q
        @g = v
        @b = p
      when 2
        @r = p
        @g = v
        @b = t
      when 3
        @r = p
        @g = q
        @b = v
      when 4
        @r = t
        @g = p
        @b = v
      when 5
        @r = v
        @g = p
        @b = q
    @r *= 255
    @g *= 255
    @b *= 255
  
  
  # Color mixing:
  mixed: (proportion, otherColor) ->
    # answer a copy of this color mixed with another color, ignore alpha
    frac1 = Math.min(Math.max(proportion, 0), 1)
    frac2 = 1 - frac1
    new Color(
      @r * frac1 + otherColor.r * frac2,
      @g * frac1 + otherColor.g * frac2,
      @b * frac1 + otherColor.b * frac2)
  
  darker: (percent) ->
    # return an rgb-interpolated darker copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new Color(0, 0, 0)
  
  lighter: (percent) ->
    # return an rgb-interpolated lighter copy of me, ignore alpha
    fract = 0.8333
    fract = (100 - percent) / 100  if percent
    @mixed fract, new Color(255, 255, 255)
  
  dansDarker: ->
    # return an hsv-interpolated darker copy of me, ignore alpha
    hsv = @hsv()
    result = new Color()
    vv = Math.max(hsv[2] - 0.16, 0)
    result.set_hsv hsv[0], hsv[1], vv
    result

  @transparent: ->
    return new Color(0,0,0,0)

