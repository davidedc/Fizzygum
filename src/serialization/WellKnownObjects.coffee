# WellKnownObjects — the two-way symbolic registry for the handful of collaborators
# that exist (as a singleton) in EVERY Fizzygum world: the world itself, the hand, the
# wallpaper, the widget factory, the bin, the shelf, the preferences bag, and each
# windowed app singleton. See docs/architecture/serialization-duplication-reference.md.
#
# WHY: a serialized widget may legitimately point at one of these (a menu item targets
# world.wallpaper; a button's target is `world`). Such a pointer leaves the serialized
# subtree, so it cannot be a normal in-structure `{"$r": n}` reference — but it is NOT
# an error either, because the same object exists in the destination world. The
# serializer encodes it symbolically as `{"$wk": "<key>"}` and the deserializer re-binds
# the key to the destination world's own singleton. This upgrades the old, information-
# destroying bare "$EXTERNAL" token into a reconstructable link.
#
# DESIGN — LAZY, NOT SNAPSHOTTED. Rather than eagerly populating a key→object map at
# world boot (which is boot-order-fragile: the bin and apps are built after the
# world), keys are resolved against the LIVE `world` on demand. This is not merely
# simpler — it is exactly what a cross-session restore needs: the same key must bind to
# the NEW session's singletons, not to a stale map captured when the file was written.
#
# The per-world singletons are matched BY IDENTITY against the live world, through the one table
# below, so they declare nothing. A `wellKnownKey` class marker is the fallback for a family the
# table cannot list, whose key carries a name: the app singletons (WindowedApp's
# `wellKnownKey: -> "app:" + @constructor.name`).
#
# THE CLASS KEYS. A class, and its own prototype, belong to the PAGE, not to the world: every page
# holding the class has them, and a widget can point at one (a class inspector's subject is a class's
# prototype; an object inspector can be opened on a class function). Such a pointer is named by its
# class, "class:<Name>" or "prototype:<Name>", and bound through classNamed in the loading page -- a
# record of the prototype's members would restore as a fake instance, and its methods have no source
# a file can carry. They are answered BEFORE the singleton table and the marker (classKeyFor), because
# a marker that is a METHOD is read through the prototype chain: a WindowedApp subclass's prototype
# would otherwise answer its app key and load as the app singleton.
#
# A KEY THAT NAMES A CLASS MUST RESOLVE. A class key or an app key naming a class the loading page
# cannot provide is refused (resolve throws, and Deserializer.whyItCanNeverBeRestored refuses the file
# before anything is built, reading the names through Deserializer.classNamesIn), never left undefined:
# the widget holding it would be left with nothing to show, edit or launch (an eager launcher whose app
# is undefined throws on its first click).
class WellKnownObjects

  # THE WELL-KNOWN SINGLETONS: key -> the object it names in the LIVE world, read afresh on every
  # call (the DESIGN above). ONE table for both directions -- keyFor matches an object against it by
  # identity, resolve looks a key up in it -- so a key cannot be written on save and then fail to bind
  # on load. The app singletons are the one family outside it, because their key carries the class
  # name: "app:<ClassName>", answered by resolveApp.
  # ⚠ ONE LINE PER ENTRY, NO COMMENTS INSIDE THE OBJECT: a method body compiles alone (AppCatalog's
  # header says why).
  @_liveSingletons: ->
    "world":         (world if world?)
    "hand":          world?.hand
    "wallpaper":     world?.wallpaper
    "widgetFactory": world?.widgetFactory
    "dataflow":      world?.dataflow
    "bin":           world?.binWdgt
    "shelf":         world?.shelfWdgt
    "preferences":   WorldWdgt.preferencesAndSettings

  # Is `key` one a Fizzygum file can carry: a table key, an app key, or a class key? A key is DATA read
  # out of a file, hence the own-property test (a plain lookup also answers `constructor`, `__proto__`).
  @isKnownKey: (key) ->
    return false unless typeof key is "string"
    Object::hasOwnProperty.call(@_liveSingletons(), key) or @appNameInAppKey(key)? or @classNameInClassKey(key)?

  # A class or a class's own prototype -> its CLASS KEY (the header's), or undefined for any other
  # value. Asked first by keyFor, and by the Serializer before it reads a value as a function or a
  # widget: a Widget-branch prototype is `instanceof Widget`.
  @classKeyFor: (value) ->
    return "class:" + value.name if typeof value is "function" and classNamed(value.name) is value
    return "prototype:" + value.constructor.name if isAClassPrototype value
    undefined

  # The app class name an app key carries ("app:<Name>", naming that app's singleton), or undefined for
  # any other key. A key with no name after its prefix is none: no save writes one. Read, with
  # classNameInClassKey below, by isKnownKey, by resolve, and by the list of the classes a file needs
  # (Deserializer.classNamesIn).
  @appNameInAppKey: (key) ->
    return undefined unless typeof key is "string" and key.indexOf("app:") is 0
    name = key.substring 4
    if name then name else undefined

  # Is `klass` of the kind an app key stands for: a class whose instances a save writes as that very
  # key (keyFor, read on an instance of it)? A load accepts an app key only for such a class -- it
  # accepts exactly what a save writes -- so a key naming a class that is not an app is refused, never
  # `new`-ed in the middle of a restore (a WorldWdgt's constructor makes itself window.world). Asked of
  # the class's own prototype chain, so core names no app-kit class (the part-edges gate); WindowedApp,
  # the base, is of the kind too, and harmless: a stateless config holder. ⚠ It reads the class's LIVE
  # members: a page that edited a class's wellKnownKey is judged by its edit.
  @isAppClass: (klass) ->
    return false unless klass?.prototype?
    @keyFor(Object.create klass.prototype) is "app:" + klass.name

  # The words of a refusal of app keys -- or a launcher's app name -- naming classes that are not apps
  # (isAppClass): the file doors' up-front one (Deserializer.whyItCanNeverBeRestored), resolveApp's (the
  # net) and a launcher's click (AppLauncherWdgt).
  @notAnAppReason: (classNames) ->
    if classNames.length is 1
      "it names " + classNames[0] + " as an app, and that class is not an app"
    else
      "it names " + classNames.join(", ") + " as apps, and those classes are not apps"

  # The class name a class key carries, or undefined for any other key (an app key included: it names
  # an app's singleton, not a class). Read where appNameInAppKey is.
  @classNameInClassKey: (key) ->
    return undefined unless typeof key is "string"
    name = if key.indexOf("class:") is 0
      key.substring 6
    else if key.indexOf("prototype:") is 0
      key.substring 10
    # a key with no name after its prefix is no class key (no save writes one): refused as a key no
    # build writes
    if name then name else undefined

  # live object -> symbolic key, or undefined if the object is not well-known.
  @keyFor: (obj) ->
    return undefined unless obj?
    classKey = @classKeyFor obj
    return classKey if classKey?
    for own key, live of @_liveSingletons()
      return key if live is obj
    # general fallback: a class-declared marker (data string or computed method),
    # e.g. app singletons expose `wellKnownKey: -> "app:" + @constructor.name`. A marker the table
    # does not know would be written into a file that no load can bind: refused here, loudly.
    wk = obj.wellKnownKey
    wk = wk.call obj if typeof wk is "function"
    return undefined unless wk?
    unless @isKnownKey wk
      throw new SerializationError ("an object declares the well-known key '" + wk + "', which WellKnownObjects does not have")
    wk

  # symbolic key -> the live object in the CURRENT world (undefined when that singleton is absent,
  # e.g. a world with no wallpaper yet). A class key resolves to the class, or its prototype, in THIS
  # page, an app key to the app's singleton (resolveApp), and one naming a class the page does not have
  # THROWS, in the words Deserializer.instantiate uses for a record of such a class
  # (SerializationError.forMissingClass): both file doors refuse such a file up front
  # (Deserializer.whyItCanNeverBeRestored), so the throw is the net for every other caller. A key no
  # Fizzygum build writes THROWS too: the deserializer refuses such a file up front
  # (Deserializer._envelopeShapeProblem asks isKnownKey).
  @resolve: (key) ->
    return undefined unless key?
    singletons = @_liveSingletons()
    return singletons[key] if Object::hasOwnProperty.call singletons, key
    appName = @appNameInAppKey key
    return @resolveApp appName if appName?
    className = @classNameInClassKey key
    if className?
      klass = classNamed className
      throw SerializationError.forMissingClass className unless klass?
      return if key.indexOf("prototype:") is 0 then klass.prototype else klass
    throw new SerializationError ("it names the well-known object '" + key + "', which no Fizzygum build has"), direction: "load"

  # Resolve the per-app singleton for a windowed-app class name (e.g. the target of a
  # deserialized desktop launcher). An WindowedApp subclass is a
  # STATELESS config holder — it declares its parts, whether it opens one window, and a
  # launch()/buildWindow() apparatus, but keeps no per-world mutable state (the one window it
  # opens lives in world.appWindows, not on the app object). So a fresh instance is behaviourally identical to
  # the one the original launcher pointed at, and it is safe to `new` during a restore (the
  # subclasses have no explicit constructor — verified). We memoize one instance per class
  # so multiple launchers for the same app share it (matching the desktop's singleton
  # semantics), and because the apps are stateless the cache is safe to keep across loads.
  # The name comes out of a file, so it is resolved by classNamed: an "app:" key naming a native
  # global or an inherited property of window is not a class, and THROWS like any class this page
  # lacks (resolve's header), never `new`-ed; and one naming a class that is not an app (isAppClass)
  # THROWS too, in the file doors' own words.
  @resolveApp: (className) ->
    appClass = classNamed className
    throw SerializationError.forMissingClass className unless appClass?
    throw new SerializationError (WellKnownObjects.notAnAppReason [className]), direction: "load" unless WellKnownObjects.isAppClass appClass
    @_appSingletons ?= {}
    @_appSingletons[className] ?= new appClass
    @_appSingletons[className]
