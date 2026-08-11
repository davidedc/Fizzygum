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
# bytes arrive we repaint so the boxes become real glyphs. Atlases not present on
# disk (e.g. a size we didn't vendor) just fail to load and stay as placeholders.
#
# TWO states make text un-settled, and anyTextDirty() reports BOTH (see
# swCanvasAnyTextDirty): an atlas still in flight (swCanvasAtlasPending), AND an
# atlas that has landed but whose placeholder-clearing repaint has not been applied
# yet (swCanvasRefreshScheduled — the refresh is deferred to a rAF). Reporting only
# the first would make the predicate LIE for that in-between window: the counter is
# already 0 while the screen still shows placeholder boxes, and — because those boxes
# sit in a cached back buffer that re-blits identically — that half-warm render is
# perfectly STABLE frame to frame, so a convergence-based capture happily converges on
# it. That is exactly how the serialization rig's pixelParity went bistable
# (Fizzygum-tests/DETERMINISM.md §2c, flake B, 2026-07-28).
swCanvasAtlasPending = 0          # in-flight atlas loads              — backs anyTextDirty()
swCanvasRefreshScheduled = false  # landed, repaint not applied yet    — backs anyTextDirty()
swCanvasAtlasRequested = {}       # idString -> true (request each atlas once)
swCanvasMissingAtlases = {}       # idString -> true (warn once per missing atlas)

# --- Surgical cold-glyph attribution -----------------------------------------
# WHO drew cold placeholders is recorded AT THE DRAW: SWCanvas's fillText RETURNS
# the per-draw status, and the paint loop maintains world.paintingWidget — so the
# atlas-warm refresh can repaint exactly the affected widgets instead of the whole
# world. Only NO_ATLAS (code 3) is recorded: a pending/possible load will cure it.
# PARTIAL_ATLAS (code 4 — chars missing from a LOADED atlas, e.g. the menu arrow
# glyph at 12px) is deliberately NOT recorded: no load will change it, and
# recording it would keep the pending set non-empty forever. Cache entries SET
# into the immutable-back-buffer cache while the cold window is open are suspected
# poisoned (they may embed placeholder pixels, and entries are shared content-keyed
# across widgets, so a kept entry would re-blit placeholders on the next hit) and
# are recorded for eviction — over-capture only costs a rebuild on the next hit.
# A cold draw OUTSIDE any widget paint cannot be attributed and falls back to the
# whole-world reset for that batch. A never-vendored atlas's widgets re-record on
# each repaint and drain only when atlas arrivals stop (bounded: arrivals are
# front-loaded; the repaints are idempotent).
swCanvasColdGlyphWidgets = []      # widgets that drew NO_ATLAS placeholders since the last refresh
swCanvasPoisonedCacheKeys = []     # immutable-back-buffer cache keys set during the cold window
swCanvasColdGlyphUnattributed = false
swCanvasPoisonedKeyRecorderOn = false

swCanvasColdWindowOpen = ->
  swCanvasAtlasPending > 0 or swCanvasRefreshScheduled or
    swCanvasColdGlyphWidgets.length > 0 or swCanvasColdGlyphUnattributed

swCanvasInstallPoisonedKeyRecorder = ->
  return if swCanvasPoisonedKeyRecorderOn
  cache = window.world?.cacheForImmutableBackBuffers
  return unless cache?
  swCanvasPoisonedKeyRecorderOn = true
  # instance wrap, serialization-safe: the world is deliberately not a table record,
  # so its caches (and this closure) never meet the serializer's walker
  originalCacheSet = cache.set
  cache.set = (key, value, onDispose) ->
    if swCanvasColdWindowOpen()
      swCanvasPoisonedCacheKeys.push key if swCanvasPoisonedCacheKeys.indexOf(key) == -1
    originalCacheSet.call @, key, value, onDispose
  # A cache HIT on a poisoned entry poisons the CONSUMER too: entries are shared
  # content-keyed across widgets, and a widget REBUILT mid-cold-window (layout churn
  # recreates e.g. axis labels) blits the poisoned entry WITHOUT any fillText — no
  # cold draw fires for it, and the originally-recorded instance may be detached by
  # refresh time. Recording at the hit closes that hole; a hit outside any widget
  # paint falls back to the whole-world reset like an unattributed draw.
  originalCacheGet = cache.get
  cache.get = (key) ->
    hit = originalCacheGet.call @, key
    if hit? and swCanvasPoisonedCacheKeys.indexOf(key) != -1
      w = window.world?.paintingWidget
      if w?
        swCanvasColdGlyphWidgets.push w if swCanvasColdGlyphWidgets.indexOf(w) == -1
      else
        swCanvasColdGlyphUnattributed = true
    hit

swCanvasRecordColdGlyphDraw = ->
  w = window.world?.paintingWidget
  if w?
    swCanvasColdGlyphWidgets.push w if swCanvasColdGlyphWidgets.indexOf(w) == -1
  else
    swCanvasColdGlyphUnattributed = true
  swCanvasInstallPoisonedKeyRecorder()

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
    try
      # Surgical path: evict exactly the suspected-poisoned cache entries and repaint
      # exactly the widgets that drew cold placeholders (through their shadow owners;
      # the island-buffer epoch stays put — each widget's own damage deposits into its
      # island buffer through the exact flesh-out lanes). The whole-world reset remains
      # the fallback when a cold draw could not be attributed to a painting widget.
      # An arrival with NOTHING recorded needs NO repaint at all: the recorder was live
      # from before the first draw, so no screen pixel or cache entry can hold this
      # atlas's placeholders (e.g. the load was triggered by a flagged calibration probe).
      if swCanvasColdGlyphUnattributed or not window.world?.noteColdGlyphRegionsWarm?
        window.world?.resetImmutableBackBuffersCache?()
      else if swCanvasColdGlyphWidgets.length > 0
        window.world.noteColdGlyphRegionsWarm swCanvasColdGlyphWidgets, swCanvasPoisonedCacheKeys
      swCanvasColdGlyphWidgets = []
      swCanvasPoisonedCacheKeys = []
      swCanvasColdGlyphUnattributed = false
    finally
      # Cleared only AFTER the reset is applied, so anyTextDirty() stays true for the WHOLE window in
      # which the screen may still be showing placeholder boxes. In a `finally` because this flag now
      # gates every screenshot: leaving it stuck true would hang the gates rather than surface the
      # error. (Both steps are synchronous, so no second refresh can be scheduled in between and lost.)
      swCanvasRefreshScheduled = false
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
  swCanvasAtlasPending > 0 or swCanvasRefreshScheduled

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
        # NO_ATLAS placeholders: record WHO drew them (see the surgical
        # cold-glyph attribution block above) so the warm-up refresh can
        # repaint exactly the affected widgets. Calibration probes rasterise
        # into throwaway canvases (pixels never reach the screen) and are
        # flagged out of the recording.
        if result?.status?.code == 3 and not @isFizzygumCalibrationProbe
          swCanvasRecordColdGlyphDraw()
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

  # (duplication of SWCanvas canvases and gradients needs no prototype patches
  # here: the Duplicator engine recognises both duck-typed — NativeValueKinds —
  # and clones them through its own per-type handlers.)

  return
