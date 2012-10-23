# Colors //////////////////////////////////////////////////////////////

class Color

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
    # ignore alpha, h, s and v are to be within [0, 1]
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
