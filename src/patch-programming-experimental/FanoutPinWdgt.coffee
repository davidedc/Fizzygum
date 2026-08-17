class FanoutPinWdgt extends Widget

  @augmentWith ControllerMixin

  inputValue: undefined

  # I forward whatever I was handed, so I can drive a target pin of ANY kind -- my target-property
  # menu offers all of them, and my set-target tooltip names no kind. Both read this one field.
  producesPinKind: "any"

  constructor: (@color) ->
    super
    @appearance = new FanoutPinAppearance @

  # Role query (replaces `x instanceof FanoutPinWdgt` filters): "am I a patch-graph connection pin?" --
  # a structural sub-part of a Fanout, not a standalone targetable widget. Used to exclude pins from the
  # target-chooser menu (Container/ControllerMixin) and to route fanout input to pin children (FanoutWdgt).
  # True here only; dispatched via ?() so nothing lands on Widget. (type-test-elimination campaign)
  isConnectionPin: ->
    true

  setInput: (newvalue, ignored) ->
    @inputValue = newvalue
    @updateTarget()

  pins: -> super().concat [ new PinSpec "bang!", "any", set: "bang" ]


  # the bang makes the node fire the current output value
  bang: (newvalue) ->
    # a bang is a FORCE-fire (spec §8): mark stale+forced so it propagates despite the equal-value cutoff.
    world.dataflow.markStale @, true
    return


  updateTarget: ->
    @_fireConnection @inputValue
    return

  # 6b node protocol: a pin's fired value is @inputValue (not the Widget.exportedValue chrome text).
  dataflowValue: -> @inputValue

  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    @_addTargetConnectionMenuEntries menu


  reactToTargetConnection: ->
    @parent.updateTarget()
