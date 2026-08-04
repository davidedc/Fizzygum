# IMMUTABLE — a value object (offset Point + alpha); fields are never written
# after construction. See docs/architecture/immutable-value-classes.md.

class ShadowInfo

  offset: nil
  alpha: 0

  # a shared, immutable value: deep copies keep the reference (see Duplicator)
  keptByReferenceOnDeepCopy: true

  # alpha should be between zero (transparent)
  # and one (fully opaque)
  constructor: (@offset = new Point(7, 7), @alpha = 0.2) ->

  # THE canonical "no shadow" instance, memoized on first use. Deliberately NOT a
  # class-level `@NO_SHADOW: new ShadowInfo …` constant: a class-level initializer
  # runs at ShadowInfo's class-eval and would need Point RIGHT THEN — but the boot
  # dependency scanner only sees `new X` edges in class-level initializers (not in
  # constructor defaults or method bodies), so no ShadowInfo→Point load-order edge
  # exists to guarantee that. The memo needs Point only at first CALL, when the
  # world is fully loaded.
  @noShadow: ->
    @NO_SHADOW ?= new ShadowInfo new Point(0, 0), 0
