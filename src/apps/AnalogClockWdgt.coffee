class AnalogClockWdgt extends Widget

  hoursHandAngle: 0
  minutesHandAngle: 0
  secondsHandAngle: 0
  dateLastTicked: undefined
  # tick with the world's cycle clock rather than my own: every clock on screen
  # advances its second hand on the same frame
  synchronisedStepping: undefined
  # my carrier-owned corner knob — the layoutSpec I hand my parent at add() time
  # (the pattern LayoutSpec.coffee names, alongside HandleWdgt.cornerSpec)
  cornerSpec: undefined

  constructor: ->

    @fps = 1
    @synchronisedStepping = true
    # you could be constructing this widget at boot,
    # in which case you just put a mock a date here
    @dateLastTicked = WorldWdgt.dateOfCurrentCycleStart or new Date
    world.steppingWdgts.add @

    super()
    @appearance = new AnalogClockAppearance @
    @_applyExtent new Point 200, 200
    # my corner KNOB (carrier-owned, like HandleWdgt.cornerSpec): top-right of the desktop, in at
    # the theme's clock insets (Theme's desktopClockRightInset / desktopClockTopInset, the draft's
    # spot), ZERO size declared -- the corner pass places me by my own extent, it never sizes me.
    # Only createDesktop ARMS it (explicitly, at add) -- deliberately NOT via
    # defaultLayoutSpecWhenAddedTo, which would re-anchor on every user re-drop; inert everywhere
    # else a clock lives (windows, demos).
    theme = WorldWdgt.theme
    @cornerSpec = new CornerInternalLayoutSpec 'topRight', 0, 0, new Point theme.desktopClockRightInset, theme.desktopClockTopInset
    return


  widthWithoutSpacing: ->
    Math.min @width(), @height()

  _resizeToWithoutSpacing: ->
    @_applyExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @_contentStackSpec.canSetHeightFreely = false
    # FIXED (grow 0): the clock keeps its own square size as window content; it does NOT
    # stretch to fill a larger (e.g. nested) window. This makes its width CONVERGENCE-INDEPENDENT:
    # at grow 0, getWidthInStack = min(desiredWidth, availW) -- no term samples the stack width,
    # so the clock never depends on a container width sampled at capture time (the old
    # proportional model's snapshot, deleted by U1 -- see
    # docs/archive/sizing-model-unification-plan.md §9.5). The clock's square aspect is
    # preserved by _setWidthSizeHeightAccordingly.
    @_contentStackSpec.grow = 0

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_applyExtent new Point newWidth, newWidth
    @height()  # Path B: hand the (square) height back so a container needn't read it off me. See Widget.

  # §4.1 pure measure: the clock is square, so its preferred height equals the width
  # (mirrors _setWidthSizeHeightAccordingly above). No mutation, no seam.
  preferredExtentForWidth: (availW) ->
    new Point availW, availW


  step: ->
    @dateLastTicked = WorldWdgt.dateOfCurrentCycleStart
    @_changed()

  # HAND DRAWING, public on purpose: these are the live-edit demo target (an inspector edit of one
  # of them takes effect on my next repaint). AnalogClockAppearance calls each with the context in
  # DEVICE pixels, its origin on my face's centre, and squareDim the side of my face's square in
  # device pixels. Every size here is in units of the draft's 120-unit face, which
  # AnalogClockAppearance.pixelsForUnits turns into device pixels at that side.
  #   A hand is one stroke from its tail, behind the centre, to its tip, at its angle (0 at
  # 12 o'clock, growing clockwise), in its colour. Its width is a whole number of device pixels of
  # squareDim's parity, so it sits symmetrically about the centre whichever way it points, and each
  # of its ends lies a whole number of device pixels from the centre along each axis, so a hand on an
  # axis is exactly axis-aligned. A hand 4 device pixels wide or more has round caps; a thinner one
  # has butt caps: SWCanvas draws a round cap that thin as a square extension, while it draws a butt
  # line (its direct line rasterizer) exactly the stroke's width in every axis direction, a 1 px
  # one included.
  _drawHand: (context, squareDim, angle, widthUnits, lengthUnits, tailUnits, color) ->
    width = @appearance.pixelsForUnits squareDim, widthUnits, 1
    tip = lengthUnits * squareDim / 120
    tail = tailUnits * squareDim / 120
    sine = Math.sin angle
    cosine = Math.cos angle
    context.save()
    context.strokeStyle = color.toString()
    context.lineWidth = width
    context.lineCap = if width >= 4 then "round" else "butt"
    context.strokeLine (Math.round -tail * sine), (Math.round tail * cosine), (Math.round tip * sine), (Math.round -tip * cosine)
    context.restore()

  drawHoursHand: (context, squareDim) ->
    @_drawHand context, squareDim, @hoursHandAngle, 6, 22, 0, WorldWdgt.theme.clockHourHand

  drawMinutesHand: (context, squareDim) ->
    @_drawHand context, squareDim, @minutesHandAngle, 4, 32, 0, WorldWdgt.theme.clockMinuteHand

  drawSecondsHand: (context, squareDim) ->
    @_drawHand context, squareDim, @secondsHandAngle, 2, 36, 8, WorldWdgt.theme.clockSecondHand

  # the centre dot over the hands' junction: a disc 8 units across, at least 4 device pixels on an
  # even side and 3 on an odd one (as the face's marks). The pixel rule never decreases as the units
  # grow, so the dot is never narrower than the hour hand's 6 units: it covers every hand's end at
  # the centre, the hour hand's round cap included.
  drawDotInMiddleOfFace: (context, squareDim) ->
    context.save()
    context.fillStyle = WorldWdgt.theme.clockCentreDot.toString()
    context.fillCircle 0, 0, (@appearance.pixelsForUnits squareDim, 8, 3) / 2
    context.restore()

