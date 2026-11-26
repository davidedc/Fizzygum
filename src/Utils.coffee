class Utils

  @isFunction: (toBeChecked) ->
    typeof toBeChecked is "function"

  @isString: (toBeChecked) ->
    typeof toBeChecked is "string" or toBeChecked instanceof String

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
  # ARBITRARY value — an inspector, which is handed whatever the user asked to
  # inspect. Widgets keep answering through their own (often overridden) method. A class's
  # PROTOTYPE is never asked: it carries its class's methods but is no instance, so asking it runs
  # instance code on none (several overrides read state only an instance has, and throw); it is
  # named from its class.
  @colloquialNameOf: (value) ->
    return Utils.derivedColloquialName value if isAClassPrototype value
    value?.colloquialName?() ? Utils.derivedColloquialName value

  # ---- printing a value as code -------------------------------------------------------------
  # THE ONE PRINTER OF VALUES: what a member editor shows of a field (MemberRef.shownText) and what a
  # value's bubble shows (Widget._informOfValue). A value's CODE FORM is CoffeeScript that evaluates to
  # a value EQUAL to it, in both scopes a typed value is evaluated in -- a widget's
  # (Widget.evaluateString) and the page's (Class.applyMemberEdit), where every class is a global. A
  # value class answers for itself (its codeForm, through its own constructor or factory: the METHOD
  # is the authority wherever a value's class has one, as with colloquialName above); these functions
  # answer for the values that carry no method, in the same manner: a number cannot carry one.
  #   Per kind: a number as JavaScript spells it, -0 included (NaN and Infinity are globals); a
  # string in double quotes, escaped by JSON (a quote, a backslash, a line break) with every `#`
  # escaped too, so nothing interpolates -- the one spelling of a string as code, a member's name in
  # an injection's assignment included (Widget.propertyAssignmentSource); true and false; undefined
  # for undefined and null alike (undefined is the one absence value); an array; an object literal
  # for an object whose prototype is Object's; a Date by its time, a Map by its entries, a Set by its
  # elements; a Fizzygum class by its name. NO code form: a widget, a function (its text is its
  # source, MemberRef's business), an object of any other class (a native container's subclass
  # among them: its literal would make the native), an object with no prototype, a class's
  # prototype (no instance), anything holding a value with none, and a cycle.
  #   A FORM INSIDE ANOTHER (an element, an object's value, a Map's or a Set's entry, a call's
  # argument) is parenthesised exactly when it is a CALL -- every object's form but an array's and an
  # object literal's -- since CoffeeScript's implicit call takes whatever follows it as its own
  # arguments: `[new Point 1, 2, new Point 3, 4]` is ONE point, `[(new Point 1, 2), (new Point 3, 4)]`
  # two. The one rule, kept in _nestedFormsOf.

  # The CoffeeScript that evaluates to a value equal to `value`, or undefined where it has none.
  @codeFormOf: (value) ->
    Utils._codeFormOf value, []

  # How a value is shown as text: its code form where it has one, else its printed form -- its own
  # toString (a widget's debug name, a function's compiled text), a String object in quotes, and an
  # object with no prototype, which has no toString of its own, as Object's reads it.
  @printedFormOf: (value) ->
    form = Utils.codeFormOf value
    return form if form?
    return '"' + value + '"' if Utils.isString value
    if Utils.isFunction value.toString then value.toString() else Object::toString.call value

  # A CALL's code form, for a value class's codeForm: the callee, then each argument's form inside it
  # (a call among them parenthesised), or undefined when an argument has none.
  @callFormOf: (callee, args) ->
    Utils._callFormOf callee, args, []

  # `enclosing`: the containers whose forms are being written around `value`; meeting one of them
  # again is a cycle, which no code form spells.
  @_codeFormOf: (value, enclosing) ->
    return "undefined" unless value?
    switch typeof value
      when "number" then (if Object.is value, -0 then "-0" else String value)
      when "string" then JSON.stringify(value).replace /#/g, "\\#"
      when "boolean" then String value
      when "function" then (value.name if classNamed(value.name) is value)
      when "object" then Utils._codeFormOfAnObject value, enclosing
      else undefined

  # An object's code form: its own codeForm where its class has one, else a native's literal or call
  # where it IS that native (its prototype the native's own).
  @_codeFormOfAnObject: (value, enclosing) ->
    return undefined if isAClassPrototype(value) or value in enclosing
    return value.codeForm() if Utils.isFunction value.codeForm
    within = enclosing.concat [value]
    switch Object.getPrototypeOf value
      when Array.prototype
        forms = Utils._nestedFormsOf value, within
        "[" + forms.join(", ") + "]" if forms?
      when Object.prototype then Utils._objectLiteralFormOf value, within
      when Date.prototype then Utils._callFormOf "new Date", [value.getTime()], within
      when Map.prototype then Utils._callFormOf "new Map", [Array.from value], within
      when Set.prototype then Utils._callFormOf "new Set", [Array.from value], within
      else undefined

  # An object literal: each own key's string form, then its value's form. An own "__proto__" key has
  # none, since a literal's `"__proto__": v` sets the object's prototype instead of a key.
  @_objectLiteralFormOf: (value, enclosing) ->
    keys = Object.keys value
    return undefined if "__proto__" in keys
    forms = Utils._nestedFormsOf (value[key] for key in keys), enclosing
    return undefined unless forms?
    "{" + (Utils._codeFormOf(key, enclosing) + ": " + forms[i] for key, i in keys).join(", ") + "}"

  @_callFormOf: (callee, args, enclosing) ->
    forms = Utils._nestedFormsOf args, enclosing
    callee + " " + forms.join(", ") if forms?

  # The forms of `values` as they stand inside another form, a call parenthesised (the rule above),
  # or undefined when one of them has none.
  @_nestedFormsOf: (values, enclosing) ->
    forms = []
    for each in values
      form = Utils._codeFormOf each, enclosing
      return undefined unless form?
      isACall = each? and typeof each is "object" and Object.getPrototypeOf(each) not in [Array.prototype, Object.prototype]
      forms.push if isACall then "(" + form + ")" else form
    forms
