class Utils

  @isFunction: (toBeChecked) ->
    typeof toBeChecked is "function"

  @isString: (toBeChecked) ->
    typeof toBeChecked is "string" or toBeChecked instanceof String

  @isObject: (toBeChecked) ->
    toBeChecked? and (typeof toBeChecked is "object" or toBeChecked instanceof Object)

  @runningInMobileSafari: ->
    (/iPad|iPhone/.test navigator.platform) or (navigator.platform == 'MacIntel' && navigator.maxTouchPoints > 1)

  # ---- naming an arbitrary value ------------------------------------------------------------
  # A colloquial name is a KIND, never a value: "spreadsheet", "slider", "number". Widgets answer
  # `colloquialName()` and ~50 classes OVERRIDE it, several with something only that object knows
  # (a transform frame answers its sole content's name, a shortcut its referent's, a console
  # composes one) — so the METHOD stays the authority wherever there is one. These two functions
  # exist for the caller that holds a value which may not be a widget at all, where asking it for
  # a method is a category error: a number cannot carry one, so naming it is a service's job.

  # The name a value gets from its CLASS alone: `Widget.colloquialName`'s BASE answer, and the
  # whole answer for anything that is not a widget (a Number, a Point, a plain object).
  @derivedColloquialName: (value) ->
    bareName = (value?.constructor?.name ? "").replace /(Wdgt|Morph)$/, ""
    # nothing usable to derive from: an object made with a null prototype, or an anonymous class
    return "object" if bareName == ""
    # split camelCase humps, keeping a run of capitals together as ONE word ("HTMLBox" -> "html
    # box", not "h t m l box"). A digit stays glued to its word and a digit-then-capital is not a
    # hump, so "3D" splits wrongly — the three classes that hit it state their name instead.
    spaced = bareName.replace(/([a-z0-9])([A-Z])/g, "$1 $2").replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2")
    spaced.toLowerCase()

  # ASK the value; derive only when it cannot answer. This is the form for a caller holding an
  # ARBITRARY value — today the object inspector, which is handed whatever the user asked to
  # inspect. Widgets keep answering through their own (often overridden) method.
  @colloquialNameOf: (value) ->
    value?.colloquialName?() ? Utils.derivedColloquialName value
