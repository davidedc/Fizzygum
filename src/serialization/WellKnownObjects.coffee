# WellKnownObjects — the two-way symbolic registry for the handful of collaborators
# that exist (as a singleton) in EVERY Fizzygum world: the world itself, the hand, the
# wallpaper, the widget factory, the bin, the preferences bag, and each windowed
# app singleton. See docs/architecture/serialization-duplication-reference.md.
#
# WHY: a serialized widget may legitimately point at one of these (a menu item targets
# world.wallpaper; a button's target is `world`). Such a pointer leaves the serialized
# subtree, so it cannot be a normal in-structure `{"$r": n}` reference — but it is NOT
# an error either, because the same object exists in the destination world. The
# serializer encodes it symbolically as `{"$wk": "<key>"}` and the deserializer re-binds
# the key to the destination world's own singleton. This upgrades the old, information-
# destroying bare "$EXTERNAL" token (DeepCopierMixin) into a reconstructable link.
#
# DESIGN — LAZY, NOT SNAPSHOTTED. Rather than eagerly populating a key→object map at
# world boot (which is boot-order-fragile: the bin and apps are built after the
# world), keys are resolved against the LIVE `world` on demand. This is not merely
# simpler — it is exactly what a cross-session restore needs: the same key must bind to
# the NEW session's singletons, not to a stale map captured when the file was written.
#
# The `wellKnownKey` marker on the collaborator classes (Wallpaper, WidgetFactory,
# IconicDesktopSystemWindowedApp) documents intent and is the general fallback for
# keyFor; the per-world singletons are matched primarily by identity against the live
# world, so keyFor is robust even where no marker is declared.
class WellKnownObjects

  # live object -> symbolic key, or nil if the object is not well-known.
  @keyFor: (obj) ->
    return nil unless obj?
    if world?
      return "world"         if obj is world
      return "hand"          if obj is world.hand
      return "wallpaper"     if obj is world.wallpaper
      return "widgetFactory" if obj is world.widgetFactory
      return "dataflow"      if obj is world.dataflow
      return "bin"      if obj is world.binWdgt
    return "preferences"     if obj is WorldWdgt.preferencesAndSettings
    # general fallback: a class-declared marker (data string or computed method),
    # e.g. app singletons expose `wellKnownKey: -> "app:" + @constructor.name`.
    wk = obj.wellKnownKey
    wk = wk.call obj if typeof wk is "function"
    return wk if wk?
    nil

  # symbolic key -> the live object in the CURRENT world, or nil if the key is unknown
  # (an unknown key is the deserializer's cue to raise a rich error).
  @resolve: (key) ->
    return nil unless key?
    switch key
      when "world"         then world
      when "hand"          then world?.hand
      when "wallpaper"     then world?.wallpaper
      when "widgetFactory" then world?.widgetFactory
      when "dataflow"      then world?.dataflow
      when "bin"      then world?.binWdgt
      when "preferences"   then WorldWdgt.preferencesAndSettings
      else
        if key.indexOf("app:") is 0
          @resolveApp key.substring 4
        else
          nil

  # Resolve the per-app singleton for a windowed-app class name (e.g. the target of a
  # deserialized desktop launcher). An IconicDesktopSystemWindowedApp subclass is a
  # STATELESS config holder — it declares a title/icon/slot and a launch()/buildWindow()
  # apparatus, but keeps no per-world mutable state (the one window it opens lives on
  # world[@slot], not on the app object). So a fresh instance is behaviourally identical to
  # the one the original launcher pointed at, and it is safe to `new` during a restore (the
  # subclasses have no explicit constructor — verified). We memoize one instance per class
  # so multiple launchers for the same app share it (matching the desktop's singleton
  # semantics), and because the apps are stateless the cache is safe to keep across loads.
  @resolveApp: (className) ->
    appClass = window[className]
    return nil unless appClass?
    @_appSingletons ?= {}
    @_appSingletons[className] ?= new appClass
    @_appSingletons[className]
