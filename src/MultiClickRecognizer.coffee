# Remembers one multi-click candidate for ActivePointerWdgt.processPointerUp: the widget a
# recent click landed on, that click's position, and the EVENT-TIME (never wall-clock) it was
# armed at. Three of these live on the hand — one for double-click (clickCount 2), one for
# triple-click (clickCount 3), replacing six hand-mirrored fields, and the record of a gesture
# whose click ACTED for the whole of it (no click count: it folds nothing, its later clicks are
# consumed — ActivePointerWdgt.noteClickActsForItsGesture).
#
# Recognition is a same-widget match within a proximity radius; the EVENT-TIME window is
# applied separately by the caller's forget gate (isStale), keeping that the SINGLE
# deterministic, load-immune forget the multi-click algorithm relies on (see
# ActivePointerWdgt.processPointerUp and memory multiclick-event-time-forget). A gesture's
# record is matched by those two measures alone, never by its widget (continuedBy).
#
# A plain state-holder: no settling, no layout, and never serialized/duplicated (it lives on
# the well-known hand, whose fields are never snapshotted — see Serializer / serialization
# reference §11). Created per-instance in ActivePointerWdgt's constructor — it holds mutable
# state, so it must NOT be a shared prototype object.

class MultiClickRecognizer

  constructor: (@clickCount) ->
    @wdgt = undefined
    @position = undefined
    @armedAtEventTime = undefined

  arm: (wdgt, position, eventTime) ->
    @wdgt = wdgt
    @position = position
    @armedAtEventTime = eventTime

  forget: ->
    @wdgt = undefined
    @position = undefined
    @armedAtEventTime = undefined

  # Has this candidate gone stale? True when it was armed more than windowMs of EVENT time
  # before the click now being processed — it belongs to a previous gesture and must be
  # dropped before matching. Mirrors the exact gate the two inline blocks used.
  isStale: (eventTime, windowMs) ->
    @wdgt? and @armedAtEventTime? and eventTime? and
      (eventTime - @armedAtEventTime) > windowMs

  # Does a click on `wdgt` at `position` complete this multi-click? Same remembered widget,
  # within proximityPx of where the candidate was armed. (The EVENT-TIME window is applied
  # separately via isStale, exactly as the original inline recognition did.)
  recognizes: (wdgt, position, proximityPx) ->
    @wdgt == wdgt and (@position.distanceTo position) < proximityPx

  # Does a click at `position`, made at `eventTime`, CONTINUE the gesture that armed me, WHATEVER
  # widget it lands on? I am armed, not stale (isStale: within windowMs of EVENT time), and the click
  # is within proximityPx of where I was armed: the two measures recognizes and its forget gate fold a
  # double click by, without the widget. Asked of the record of a gesture that has acted, at each
  # press and each release (ActivePointerWdgt._pointerContinuesAnActedGesture), whose act may have laid
  # a window of its own over the widget its click landed on. A pure function of the event stream:
  # event times and positions only.
  continuedBy: (position, eventTime, windowMs, proximityPx) ->
    @wdgt? and !(@isStale eventTime, windowMs) and (@position.distanceTo position) < proximityPx
