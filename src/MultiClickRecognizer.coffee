# Remembers one multi-click candidate for ActivePointerWdgt.processMouseUp: the widget a
# recent click landed on, that click's position, and the EVENT-TIME (never wall-clock) it was
# armed at. Two of these live on the hand — one for double-click (clickCount 2), one for
# triple-click (clickCount 3) — replacing six hand-mirrored fields.
#
# Recognition is a same-widget match within a proximity radius; the EVENT-TIME window is
# applied separately by the caller's forget gate (isStale), keeping that the SINGLE
# deterministic, load-immune forget the multi-click algorithm relies on (see
# ActivePointerWdgt.processMouseUp and memory multiclick-event-time-forget).
#
# A plain state-holder: no settling, no layout, and never serialized/duplicated (it lives on
# the well-known hand, whose fields are never snapshotted — see Serializer / serialization
# reference §11). Created per-instance in ActivePointerWdgt's constructor — it holds mutable
# state, so it must NOT be a shared prototype object.

class MultiClickRecognizer

  constructor: (@clickCount) ->
    @wdgt = nil
    @position = nil
    @armedAtEventTime = nil

  arm: (wdgt, position, eventTime) ->
    @wdgt = wdgt
    @position = position
    @armedAtEventTime = eventTime

  forget: ->
    @wdgt = nil
    @position = nil
    @armedAtEventTime = nil

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
