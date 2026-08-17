# //////////////////////////////////////////////////////////

# some widgets (for example ColorPaletteWdgt
# or SliderWdgt) can control a target
# and they have the same function to attach
# targets. Not worth having this in the
# whole Widget hierarchy, so... ideal use
# of mixins here.

ControllerMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,
      openTargetSelector: ->
        choices = world.plausibleTargetAndDestinationWidgets @
        if choices.length > 0
          menu = new MenuWdgt @, target: @, title: "choose target:"
          #choices.push @world()
          choices.forEach (each) =>
            if !(each.isConnectionPin?())
              menu.addMenuItem (each.toString().replace "Wdgt", "").slice(0, 50) + " ➜", @, "openTargetPropertySelector", closesUnpinnedPopUps: false, arg1: each, representsAWidget: true
        else
          menu = new MenuWdgt @, target: @, title: "no targets available"
        menu.popUpAtHand()

      # ---- THE WIRES ----------------------------------------------------------------------
      # An ordered list of WireSpec, one per relationship I drive (connector plan §P4). It REPLACED the
      # loose @target / @action / @firesPerEvent / @tracksTarget fields, which between them described a
      # single wire in four places and could describe no second one — gap G2: one out-edge ever, no
      # un-wire idiom, fan-out only via the unshipped FanoutWdgt.
      #   ⛔ There is deliberately NO @target/@action compatibility shim. The plan proposed accessors
      # onto @wires[0], and this codebase cannot express one: Class/Mixin emit every member as
      # `prototype.<name> = <expr>` (Class.coffee), so a getter/setter is not writable here at all —
      # there is not one instance accessor in src/. And a shim would state each wire's target twice,
      # which is the drift PinSpec's own header warns about. So every site converted in one pass.
      #   Declared as a PROTOTYPE default of `undefined`, NOT an empty array: a shared array on the
      # prototype would be mutated by whichever controller wired first and seen by every other one.
      # So an unwired widget carries no own `wires` property and serializes byte-for-byte as before —
      # the same own-only-when-set idiom @target/@action followed, and why unwireFrom `delete`s the
      # field rather than leaving an empty array behind.
      wires: undefined

      # THE WIRE VERB — bind me to drive `action` on `theTarget`. Two operands, no holes:
      # this is what a caller building a circuit in code means, and what the menu adapter
      # below reduces to once the dispatcher's slots have been unpacked.
      #   ⭐ It ADDS a wire; it does not replace my wires. That IS the §P4 capability — a controller
      # drives as many things as it is connected to, so fan-out stops needing FanoutWdgt — and it is
      # why the menu item is now "connect to ➜" everywhere and is partnered by "disconnect ➜".
      # Wiring the same target+action twice is a no-op rather than a second edge (WireSpec.describes).
      wireTo: (theTarget, action) ->
        @_addWire theTarget, action
        # reactToTargetConnection is left UNCHANGED across every controller: via _fireConnection it
        # markStale's me (the initial fire), so each keeps its exact on-connect semantics -- a slider/text fires
        # its current value, PaletteWdgt's empty override fires nothing, Example3DPlot recomputes its plot.
        # Non-forced is sufficient (a fresh wire's producer value differs from the target's, so it propagates).
        @reactToTargetConnection?()

      # THE RECIPROCAL WIRE (connector plan §P8): I drive `action` on `theTarget` AND I follow it, so
      # the two stay welded however the property changes. Same binding as wireTo, plus the reverse
      # edge — and with the on-connect push turned around.
      #   ⭐ A TRACKING control does NOT push on connect. That is what tracking MEANS: the target owns
      # the value and I show it, so the initial value flows target → me. Pushing instead is not a
      # nuance, it is a bug with teeth: a scrollbar's thumb starts wherever its constructor left it
      # (a SliderWdgt is born at 50 of 1..100), so a connect-time push scrolls the content to a
      # position nobody asked for — and it lands on the NEXT drain, by which time a panel that had
      # nothing to scroll at construction may well have gained content.
      trackTarget: (theTarget, action) ->
        wire = @_addWire theTarget, action, tracks: true
        # opts only reach a record being CREATED, so say it again for a plain wire being promoted to a
        # tracking one — "also follow what you already drive" is a legitimate thing to ask twice.
        wire.tracks = true
        @_ensureTrackingEdges()
        @reflectTarget()

      # THE THIRD BINDING VERB: declare a wire and move NOTHING. §P8 established that the direction of
      # the on-connect push is part of what a bind MEANS; this is the third answer — no push at all —
      # and it is what a container wiring up chrome it just BUILT means, since it built the two ends
      # consistent and has nothing to announce.
      #   ⚠ Not a nuance for its caller. NumberPromptWdgt's slider drives `takeSliderValue`, whose
      # connector rewrites the entry field's text to the ROUNDED slider value and opens an edit on it.
      # Firing that at construction would round a fractional default away and pop a caret before the
      # prompt is on screen. (Before §P4 this site poked @target/@action directly and so never fired;
      # that silence was incidental then and is stated here.)
      declareWireTo: (theTarget, action) ->
        @_addWire theTarget, action
        return

      # The shared body of the binding verbs: find or make the record, set the legacy
      # <action>IsConnected flag, and mirror the list into the engine index.
      #   A wire IS a dataflow edge (spec §8): the index is derived/disposable (spec §2) and re-declared
      # by the client on load/copy -- here the client is the wire list itself. Declaring EAGERLY here is
      # an optimisation (the edge exists the moment a menu wire is made); _fireConnection re-derives
      # LAZILY too, which is what covers a wire built directly rather than through the menu (the
      # NumberPromptWdgt slider).
      _addWire: (theTarget, action, opts = {}) ->
        @wires ?= []
        wire = @_wireFor theTarget, action
        unless wire?
          wire = new WireSpec theTarget, action, opts
          @wires.push wire
        if theTarget[action + "IsConnected"]?
          theTarget[action + "IsConnected"] = true
        world.dataflow.ensureWireEdges @, @wires
        return wire

      # THE UN-WIRE VERB, which single-slot wiring could not have: drop one relationship and leave the
      # others alone. Its first caller was already in the tree waiting for it — CellWdgt cleared the
      # fields by hand under a comment reading "no un-wire idiom exists in ControllerMixin"; the
      # "disconnect ➜" menu item is the second.
      #   Both halves of a tracking wire go: the forward edge stops being derivable the moment the
      # record leaves the list (ensureWireEdges reconciles), but the reverse one is an edge OUT of the
      # target that only I can revoke, so it is dropped explicitly. Then the record itself dies as a
      # dataflow node, because its menu row subscribed to it.
      unwireFrom: (theTarget, action) ->
        wire = @_wireFor theTarget, action
        return unless wire?
        @wires = (each for each in @wires when each isnt wire)
        delete @wires if @wires.length is 0
        world.dataflow.ensureWireEdges @, @wires
        world.dataflow.removeAnyChangeEdge theTarget, @ if wire.tracks
        world.dataflow.removeAllEdgesOf wire
        return

      # The record for THIS relationship, if I hold it. The identity of a wire is the pair, so
      # re-wiring the same target and action finds the existing record instead of adding a twin.
      _wireFor: (theTarget, action) ->
        return undefined unless @wires?
        for wire in @wires
          return wire if wire.describes theTarget, action
        return undefined

      # Do I drive this widget at all, by any of my wires? The membership question a container asks
      # about the chrome it holds — "is this scrollbar MINE, or one left pointing at another panel?"
      # (ScrollPanelWdgt._reLayoutScrollbars). A SEARCH, not a field comparison, because the answer
      # may live in any of my wires.
      isWiredTo: (theTarget) ->
        return false unless @wires?
        for wire in @wires
          return true if wire.target is theTarget
        return false

      # The wire I FOLLOW, for a control that reflects what it drives (SliderWdgt.reflectTarget).
      # The FIRST one: a slider has one thumb and can only show one value, so tracking a second
      # target would be a display with no way to render it. Nothing builds such a control today.
      _trackingWire: ->
        return undefined unless @wires?
        for wire in @wires
          return wire if wire.tracks
        return undefined

      # THE MENU ADAPTER. Its first two parameters are not mine to choose: a menu/button
      # action is dispatched as
      #   target[action].call target, dataSource, widgetEnv, arg1, arg2   (ButtonWdgt)
      # so the picked target and property necessarily ride slots 3 and 4. That fixed foreign
      # convention is the ONLY reason this signature has leading ignored slots — a caller
      # wiring a circuit in code wants wireTo above, because passing `undefined, undefined`
      # to reach past a dispatcher's slots is exactly the hole R3 names
      # (docs/architecture/constructor-and-parameter-conventions.md).
      setTargetAndActionWithOnesPickedFromMenu: (ignored, ignored2, theTarget, action) ->
        @wireTo theTarget, action

      # A wire's producer marks ITSELF stale -- the ONE onward-fire every controller's updateTarget calls. It
      # derives my producer->target edges from my wire list (ensureWireEdges) and marks me stale; the engine's
      # drain then PULLS my dataflowValue and DELIVERS it along each edge (DataflowEngine._applyWireValue),
      # routing to the target's dedicated _<action>Connector variant when it defines one (the reactive settle
      # lane that JOINS an enclosing settle -- Widget._settleLayoutsAfterOrJoinEnclosingPass / check-layering
      # [P]) and to the public action otherwise (setValue / setInput1 / setColor / ... never open a settle, so
      # the public name is already sound -- census: connection-cascade-settle-fix-plan.md fact 13). A wire's
      # action stays the menu-friendly public name everywhere (menus, <action>IsConnected flags, hard-wired
      # app circuits).
      _fireConnection: (value) ->
        return unless @wires?.length
        # under the engine a wire carries NO value: it only marks me STALE, and the drain PULLS my dataflowValue
        # when it delivers along my edges (spec §3, notifications carry no values). So every controller's
        # updateTarget (`@_fireConnection <myValue>`) is a markStale with no per-controller change; the pushed
        # `value` is ignored outright (the pull is the source of truth) and survives only as the caller's
        # statement of what it thinks it is firing. ONE markStale serves however
        # many wires I hold — the drain walks my out-edges. markStale is echo-suppressed while the engine is
        # applying me (DataflowEngine.markStale). A wire-less widget returns above (no fire).
        #   Derive my edges from the wire list if they aren't declared yet: the NumberPromptWdgt slider is
        # wired by DIRECT construction, never through the menu that declares them -- spec §8 says edges DERIVE
        # from the wires, so make that derivation total. Without this such a wire would markStale with no
        # out-edge and deliver nothing (silently broken prompt).
        # Idempotent for a menu-wired connection (the eager declaration already matches); no-op mid-drain.
        world.dataflow.ensureWireEdges @, @wires
        # ...and, for a TRACKING control, the opposite edges from the same local facts (see below).
        @_ensureTrackingEdges()
        world.dataflow.markStale @
        return

      # ---- tracking: the REVERSE half of a wire (connector plan §P8) -----------------------
      # A wire is ONE-WAY: I drive its `action` on its `target`. A control that must stay WELDED to what
      # it drives — a scrollbar and its content — also has to FOLLOW it when the property changes by any
      # other means. `trackTarget` declares that second, opposite edge: target → me, `firesOnAnyChange`,
      # so my target's markNonValueChange wakes me too. That announcement is the honest one for a
      # property that is not the target's VALUE (a scroll panel has no principal pin at all), and it
      # is why the edge asks to re-read rather than to be handed something.
      #   I never read the delivered value: `reflectTarget` re-reads the pin the tracking wire's own
      # action writes. So a DUPLICATED control — which keeps its wire records and nothing else — tracks
      # exactly what it drives, with no field naming the property a second time.
      #   Since §P4 the flag lives on the WIRE rather than on me, which is where it belongs: tracking is
      # a property of the RELATIONSHIP, so a controller can follow one target while merely driving
      # another. As a prototype default on WireSpec it costs an ordinary wire no own property.
      #
      # Derive the tracking edges from the wire list, exactly the way ensureWireEdges derives the
      # forward ones: the index is derived and disposable (dataflow spec §2) and the client re-declares
      # it, and the client here is me. Idempotent, so it is cheap on every fire and on every re-add —
      # which is what makes a duplicated or re-parented control re-subscribe with no bookkeeping of its
      # own to duplicate or serialize.
      #   Dedup asks the index (hasEdge) rather than keeping a field, as MenuRowsPanelWdgt does. That
      # reads "is there ANY edge target → me", which is the right question here: a target that drove me
      # back would be a two-wire ring, which no caller builds and which §P2 will address explicitly.
      _ensureTrackingEdges: ->
        return unless @wires?
        for wire in @wires when wire.tracks
          continue if world.dataflow.hasEdge wire.target, @
          world.dataflow.addEdge wire.target, @, action: "reflectTarget", firesOnAnyChange: true
        return

      # ---- the connection menu -------------------------------------------------------------
      # The shared "connect a target" block, appended identically by every controller (SliderWdgt,
      # SimpleTextWdgt, PaletteWdgt, FanoutPinWdgt and the patch nodes) right after its `super`: a
      # divider, the "connect to ➜" item, then ONE ROW PER LIVE WIRE.
      #   ⭐ Those rows are the point of §P4. A single-slot controller had nothing to show — its one
      # connection was invisible, and re-targeting silently dropped it. A controller that owns a list
      # can SHOW what it drives, and each row opens that wire's own little menu (policy + disconnect),
      # so wiring is legible and reversible for the first time.
      #   ⛔ ONE label, deliberately, with no isIndexPage fork: "set target" is the name of a
      # SINGLE-SLOT world and would be a false promise here, since the gesture connects *a* target,
      # one of however many I already drive. (StringWdgt keeps its own hand-rolled variant —
      # it guards the whole block behind isIndexPage, so it is deliberately NOT routed through here.)
      # The kind of property this controller can drive is read from `producesPinKind` -- the SAME
      # declaration its openTargetPropertySelector filters the target's pins by, so the tooltip
      # cannot describe a menu other than the one it opens. Taking the kind as an argument here
      # instead would let every controller state it twice, in two unrelated places, and nothing
      # would compare them. A widget that drives any kind names none: the sentence reads
      # "whose property".
      _addTargetConnectionMenuEntries: (menu) ->
        menu.addLine()
        kindWord = if @producesPinKind? and @producesPinKind isnt "any" then @producesPinKind + " " else ""
        menu.addMenuItem "connect to ➜", @, "openTargetSelector", toolTip: ("choose another widget\nwhose " + kindWord + "property\n will be" + " controlled by this one")
        @_addWireMenuEntries menu

      # One row per live wire, each naming what it drives ("a Panel . color") and opening that wire's
      # own menu. Nothing at all when I am unwired, so an unconnected controller's menu is unchanged.
      # Shared with StringWdgt, which builds the rest of its connection block by hand.
      _addWireMenuEntries: (menu) ->
        return unless @wires?
        for wire in @wires
          menu.addMenuItem wire.describeConnection() + " ➜", @, "openWireMenu",
            toolTip: "what this connection does,\nand how to remove it"
            arg1: wire
        return

      # Menu-dispatched (slots 1-2 are the dispatcher's — see setTargetAndActionWithOnesPickedFromMenu):
      # the per-wire menu behind a connection row. Two entries, because a wire has exactly two things a
      # user can do to it — change how it delivers, or cut it.
      openWireMenu: (ignored, ignored2, wire) ->
        menu = new MenuWdgt @, target: @, title: wire.describeConnection()
        label = "fires per event"
        menu.addMenuItem label, @, "toggleFiresPerEventOfWire",
          toolTip: "deliver on every event (a synchronous mini-pass)\ninstead of once per cycle"
          arg1: wire
          # ⭐ the row's source is the WIRE ITSELF, not me: the policy is the wire's own state, and the
          # dataflow node protocol is duck-typed, so a WireSpec can be a node with nothing but a reader
          # (the trick §P5 played for Wallpaper). Two rows for two wires therefore tick independently.
          reflection: MenuRowReflectionSpec.tickWhen wire, "isFiringPerEvent", true, label
        menu.addMenuItem "disconnect", @, "disconnectWire",
          toolTip: "stop driving\n" + wire.describeConnection()
          arg1: wire
        menu.popUpAtHand()

      # ---- firesPerEvent: per-wire delivery policy (dataflow; spec §4/§8) ------------------
      # false (default) = POOLED: ten drag events + a tick in one frame collapse to ONE recompute
      #   batch, drained once per cycle using final values.
      # true = PER-EVENT: a synchronous mini-pass inside each event (side-effects-per-event,
      #   read-your-writes within a frame), at N× the evaluation cost.
      # The flag rides the edge record's opts (WireSpec.edgeOpts). The PER-EVENT lane is still DEFERRED
      # -- delivery POOLS regardless of the flag (the two are screen-indistinguishable, spec §13); the
      # menu toggle stores it against the day the mini-pass lands.
      #   Since §P4 the flag lives on the WIRE (WireSpec.firesPerEvent), which is what the docs always
      # called it: "a per-wire delivery policy". On the controller it could only ever have been one
      # policy for every wire — a fact stated once for relationships that do not share it.
      #
      # Menu-dispatched: flip THIS wire's policy. A plain boolean flip: no layout and no tree mutation,
      # hence no settle (check-layering-clean); nothing visual changes. Then re-declare, because the
      # policy rides the edge record and the index must not disagree with the wire. ANNOUNCE it on the
      # WIRE so every open menu showing that row re-ticks; markNonValueChange, NOT markStale, and now
      # trivially so — a wire is not a value-bearing node at all, so there is nothing it could
      # re-deliver.
      toggleFiresPerEventOfWire: (ignored, ignored2, wire) ->
        wire.firesPerEvent = not wire.firesPerEvent
        world.dataflow.ensureWireEdges @, @wires
        world.dataflow.markNonValueChange wire

      # Menu-dispatched: cut this wire. The un-wire gesture G2 named as missing.
      disconnectWire: (ignored, ignored2, wire) ->
        @unwireFrom wire.target, wire.action

