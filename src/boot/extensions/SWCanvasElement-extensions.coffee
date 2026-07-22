# When the SWCanvas software backend is active, the canvases Fizzygum creates
# via HTMLCanvasElement.createOfPhysicalDimensions are SWCanvasElements, and
# their 2D contexts are SWCanvas's CanvasCompatibleContext2D — NOT the native
# HTMLCanvasElement / CanvasRenderingContext2D / CanvasGradient. So the
# monkey-patches that the other *-extensions.coffee files install on the native
# prototypes never reach SWCanvas's objects.
#
# installSWCanvasExtensions copies the same methods onto SWCanvas's prototypes.
# It is called once from boot() (globalFunctions.coffee) when
# window.FIZZYGUM_USE_SWCANVAS is on, after the whole boot bundle (which includes
# the SWCanvas engine and the native-prototype extensions) has loaded.

# SWCanvas ships bitmap atlases for only Arial / Times / Courier, and its font
# parser throws on the comma-separated stacks Fizzygum uses (e.g.
# "12px Arial, sans-serif"). So map each stack onto one of the three shipped
# families by its generic terminator, and snap the size to the nearest shipped
# 0.5px step (>= 9). This MUST be applied identically to measure and render
# (it is — both go through the context's `font` setter, which we override below)
# so SWCanvas-measure and SWCanvas-render stay self-consistent.
# The shipped family names are exactly "Arial", "Times New Roman", "Courier New"
# (NOT "Times" / "Courier" — those have no metrics/atlases and measureText would
# return null, which is fatal during boot).
# The size range SWCanvas can actually render: it ships bitmap atlases for a
# fixed band of sizes (see vendor-swcanvas-fonts.sh), so any requested size is
# clamped into [MIN, MAX]. MAX matters beyond rendering: a size above it draws
# NO bigger than MAX, so auto-fitting text (StringWdgt's font-size search)
# must not pick a size larger than MAX — otherwise the chosen size, and the
# caret/line height derived from it, run away above what is actually painted
# (the "giant caret, normal-size text" bug). Exposed on window so that search
# can read the cap from its single source of truth here.
SWCANVAS_MIN_FONT_SIZE = 9
SWCANVAS_MAX_FONT_SIZE = 96
window.SWCANVAS_MAX_FONT_SIZE = SWCANVAS_MAX_FONT_SIZE

mapFontStackToSWCanvasFamily = (stack) ->
  s = stack.toLowerCase()
  if s.indexOf("monospace") != -1 or s.indexOf("courier") != -1
    "Courier New"
  else if s.indexOf("serif") != -1 and s.indexOf("sans-serif") == -1
    "Times New Roman"
  else
    "Arial"

normalizeFontForSWCanvas = (cssFont) ->
  return cssFont unless typeof cssFont is "string"
  # Fizzygum emits "[bold ][italic ]<size>px <family-stack>".
  match = cssFont.match /^(.*?)(\d+(?:\.\d+)?)px\s+(.*)$/
  return cssFont unless match?
  prefix = match[1]
  size = parseFloat match[2]
  family = mapFontStackToSWCanvasFamily match[3].trim()
  snapped = Math.round(size * 2) / 2
  snapped = SWCANVAS_MIN_FONT_SIZE if snapped < SWCANVAS_MIN_FONT_SIZE
  snapped = SWCANVAS_MAX_FONT_SIZE if snapped > SWCANVAS_MAX_FONT_SIZE
  styleWeight = ""
  styleWeight += "bold " if /\bbold\b/.test prefix
  styleWeight += "italic " if /\bitalic\b/.test prefix
  styleWeight + snapped + "px " + family

# --- Glyph-atlas loading -----------------------------------------------------
# fillText is always safe: SWCanvas paints placeholder boxes when an atlas is
# cold. After each fillText we make sure the atlas for the current font (and the
# BitmapTextInvariant companion, used for special chars) is loaded; when the
# bytes arrive we repaint so the boxes become real glyphs. swCanvasAtlasPending
# counts in-flight loads — it backs world.anyTextDirty() (the test screenshot
# gate). Atlases not present on disk (e.g. a size we didn't vendor) just fail to
# load and stay as placeholders.
swCanvasAtlasPending = 0       # in-flight atlas loads — backs anyTextDirty()
swCanvasAtlasRequested = {}    # idString -> true (request each atlas once)
swCanvasMissingAtlases = {}    # idString -> true (warn once per missing atlas)
swCanvasRefreshScheduled = false

# When a cold atlas was drawn its glyphs went into a CACHED back buffer as
# placeholder boxes. A plain repaint just re-blits that cache, so once the atlas
# is warm we must reset the immutable-back-buffer cache (forcing the text widgets
# to re-run fillText) and repaint. We batch this across all atlas loads that
# land in the same frame, so the warm-up does a handful of re-renders rather than
# one per atlas. (No loop: once warm, hasAtlas() is true so we never re-request.)
swCanvasScheduleTextRefresh = ->
  return if swCanvasRefreshScheduled
  swCanvasRefreshScheduled = true
  doRefresh = ->
    swCanvasRefreshScheduled = false
    # resetImmutableBackBuffersCache resets the text cache AND bumps the island-buffer epoch (so a
    # rotated/scaled island — a further cache downstream — also rebuilds from the now-warm text, §4.4)
    # AND repaints the world: the full repaint is intrinsic to the reset, done world-side.
    window.world?.resetImmutableBackBuffersCache?()
  if window.requestAnimationFrame?
    window.requestAnimationFrame doRefresh
  else
    setTimeout doRefresh, 16

# Note (don't spam): an atlas we didn't vendor. Useful to inventory which
# families/sizes Fizzygum actually needs.
swCanvasLogMissingAtlas = (idString) ->
  return if swCanvasMissingAtlases[idString]
  swCanvasMissingAtlases[idString] = true
  console.warn "Fizzygum/SWCanvas: no atlas for '#{idString}' (not vendored?) — text stays as placeholders"

swCanvasEnsureAtlasForFont = (coreFont, density) ->
  return unless coreFont? and coreFont.fontFamily? and window.SWCanvas?
  raw = window.SWCanvas.fonts._raw
  return unless raw?.FontProperties? and raw?.BitmapText?
  FontProperties = raw.FontProperties
  bitmapText = raw.BitmapText
  d = density or ceilPixelRatio
  size = coreFont.fontSize
  primaryId = new FontProperties(d, coreFont.fontFamily, (coreFont.style or "normal"), (coreFont.weight or "normal"), size).idString
  invariantId = new FontProperties(d, "BitmapTextInvariant", "normal", "normal", size).idString
  for idString in [primaryId, invariantId]
    continue if bitmapText.hasAtlas idString
    continue if swCanvasAtlasRequested[idString]
    swCanvasAtlasRequested[idString] = true
    swCanvasAtlasPending++
    do (idString) ->
      onSettled = ->
        swCanvasAtlasPending-- if swCanvasAtlasPending > 0
      # isFileProtocol is NOT auto-detected by BitmapText (defaults to false) —
      # we must pass it, else it loads the .webp image directly, which the
      # browser blocks over file://. Over file:// the loader injects the wrapped
      # atlas-*-webp.js <script> instead.
      isFileProtocol = window.location? and window.location.protocol is "file:"
      bitmapText.loadFont(idString, {isFileProtocol: isFileProtocol}).then(
        ->
          onSettled()
          # loadFont resolves even when the atlas file is missing (the loader
          # treats a 404 as "use placeholders"), so gate the refresh on hasAtlas.
          if bitmapText.hasAtlas idString
            swCanvasScheduleTextRefresh()
          else
            swCanvasLogMissingAtlas idString
        , (err) ->
          onSettled()
          swCanvasLogMissingAtlas idString
      )
  return

swCanvasAnyTextDirty = ->
  swCanvasAtlasPending > 0

# Expose for WorldWdgt.anyTextDirty() / the SystemTest screenshot settle-gate.
window.swCanvasAnyTextDirty = swCanvasAnyTextDirty

installSWCanvasExtensions = ->
  return unless window.SWCanvas?

  # A throwaway 1x1 canvas just to reach the prototypes.
  probeCanvas = window.SWCanvas.createCanvas 1, 1
  swContext = probeCanvas.getContext "2d"

  # --- CanvasRenderingContext2D extensions (see
  #     CanvasRenderingContext2D-extensions.coffee). The bodies use @scale /
  #     @beginPath / @moveTo / @lineTo / @closePath / @clip and the global
  #     ceilPixelRatio — all present/valid on the SWCanvas context.
  swContextProto = Object.getPrototypeOf swContext
  if CanvasRenderingContext2D?
    swContextProto.clipToRectangle = CanvasRenderingContext2D::clipToRectangle
    swContextProto.rebuildDerivedValue = CanvasRenderingContext2D::rebuildDerivedValue
  # SWCanvas-specific useLogicalPixelsUntilRestore: besides the ceilPixelRatio
  # scale (as the native one does), pin the text atlas density to ceilPixelRatio
  # so glyphs use the density-matched atlas and hit the fast direct-blit path.
  # textPixelDensity is snapshotted by save()/restore(), so it reverts with the
  # scale on restore().
  swContextProto.useLogicalPixelsUntilRestore = ->
    @textPixelDensity = ceilPixelRatio if @textPixelDensity?
    @scale ceilPixelRatio, ceilPixelRatio

  # Ensure the atlas for whatever font was just drawn gets loaded (placeholder
  # boxes -> real glyphs on arrival). Wrap fillText at the one choke point.
  originalFillText = swContextProto.fillText
  if originalFillText?
    swContextProto.fillText = (text, x, y, maxWidth) ->
      result = originalFillText.call @, text, x, y, maxWidth
      try
        swCanvasEnsureAtlasForFont @_core?._font, @_core?._textPixelDensity
      catch err
      result

  # Override the `font` setter so EVERY `ctx.font = "..."` (back buffers AND the
  # world text-measurement context) is normalized to a single shipped family +
  # snapped size before reaching SWCanvas's parser. This is the one choke point
  # that catches all text, with no edits in the widgets.
  fontDescriptor = Object.getOwnPropertyDescriptor swContextProto, "font"
  if fontDescriptor?.set? and fontDescriptor?.get?
    originalFontSetter = fontDescriptor.set
    Object.defineProperty swContextProto, "font",
      configurable: true
      enumerable: fontDescriptor.enumerable
      get: fontDescriptor.get
      set: (value) ->
        originalFontSetter.call @, normalizeFontForSWCanvas value

  # --- SWCanvasElement needs Fizzygum's HTMLCanvasElement deepCopy (it does not
  #     inherit the native one). The body re-creates a clone via the factory
  #     (which yields an SWCanvasElement here), drawImages this into it, and
  #     serializes via @toDataURL() — all supported on SWCanvasElement.
  swCanvasElementProto = Object.getPrototypeOf probeCanvas
  if HTMLCanvasElement?
    swCanvasElementProto.deepCopy = HTMLCanvasElement::deepCopy

  # --- SWCanvas gradients need the nil-returning deepCopy too, so that the
  #     DeepCopier can walk past them (gradients are re-created on demand).
  if CanvasGradient?
    swGradientProto = Object.getPrototypeOf swContext.createLinearGradient 0, 0, 1, 1
    swGradientProto.deepCopy = CanvasGradient::deepCopy

  return
