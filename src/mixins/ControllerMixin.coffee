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

      # The shared body of the binding verbs: find or make the record, and mirror the list into the
      # engine index.
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
          # a new wire can make its target REACHABLE — storage liveness follows wires
          # (graph-edges plan §4.3) — so mark the membership chokepoint. O(1), drains once
          # per cycle.
          world.noteStorageMembershipMayHaveChanged()
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
        # the cut wire may have been what kept its target reachable — storage liveness
        # follows wires (graph-edges plan §4.3) — so mark the membership chokepoint.
        world.noteStorageMembershipMayHaveChanged()
        return

      # THE UN-WIRE VERB's death-driven sibling: drop every wire whose TARGET is destroyed,
      # with unwireFrom's full hygiene. Sever-at-death (DataflowEngine.severWiresIntoDyingNode)
      # prunes these eagerly through the engine's reverse index, but that index is derived
      # LAZILY — a restored controller declares its edges on first fire — so a target destroyed
      # before my edges were ever declared leaves a record death could not see. Healing at the
      # same funnel that derives the edges (_fireConnection) makes the invariant total: no wire
      # record outlives its target, so no derivation can re-declare an edge onto a corpse and
      # nothing can deliver into one.
      _pruneWiresOntoDestroyedTargets: ->
        return unless @wires?
        for wire in @wires.slice() when wire.target?.destroyed
          # public-call-sanctioned: unwireFrom is THE one un-wire verb and is settle-neutral
          # (pure list + engine-index bookkeeping, no geometry); duplicating its hygiene here
          # would state the un-wire protocol twice.
          @unwireFrom wire.target, wire.action
        return

      # My declared wires, as FLOW edges (Widget.graphEdgesOut -- the three-edge model,
      # docs/archive/graph-edges-and-lifecycle-plan.md §4.2). The SERIALIZED truth, not the engine's
      # derived records: the index also carries consumer-declared firesOnAnyChange subscriptions
      # (a menu tracking a text) that are nobody's declared relationship and confer nothing
      # (decision G5 there).
      graphEdgesOut: ->
        edges = super()
        if @wires?
          edges.push {kind: 'flow', to: wire.target} for wire in @wires
        edges

      # ---- THE BIND GESTURE (connector plan §P2) --------------------------------------------
      # A BIND IS TWO ORDINARY WIRES — mine onto you, yours onto me — and nothing else. There is no
      # bind record, no bind edge and no bind flag: "these two are bound" is a QUESTION asked of the
      # two wire lists and answered fresh every time (_isTwoWayWire below). One consequence is worth
      # stating, because it is the proof the model is honest rather than a shortcut: a pair someone
      # wires by hand in two separate "connect to ➜" gestures IS bound, and reads as bound. The
      # gesture saves clicks and picks the pins correctly; it does not create a different kind of
      # thing.
      #   ⭐ IT BINDS VALUE TO VALUE, and can bind nothing else. A wire delivers its producer's
      # PRINCIPAL value (DataflowEngine.pullValue → Widget.dataflowValue), so a return wire aimed at
      # any other pin would carry a quantity its producer does not own. That is not a restriction to
      # lift later — the engine has exactly two production granularities, and this is the NODE one
      # ("a node has exactly ONE value"). The PIN one is the tracking wire (trackTarget, §P8), whose
      # reverse half asks its consumer to RE-READ rather than handing it a value.
      #   ⭐ Which is also what makes the offer honest. A widget with a read/write principal pin AND
      # these verbs is precisely a widget that ANNOUNCES when its value changes, so both halves of
      # the bind are live. Nothing on a PinSpec declares "I announce", so binding an arbitrary pin
      # could promise a reverse direction that silently never fires.
      bindTo: (theTarget) ->
        # PRECEDENCE (plan §8 q3): the side whose menu opened the gesture is the source of truth, so
        # I push my value and the return wire moves nothing. declareWireTo is what makes that exact —
        # with two pushes the later one would simply win, which is an accident, not a rule.
        @wireTo theTarget, theTarget.principalPin().setterName
        theTarget.declareWireTo @, @principalPin().setterName
        return

      # Can I be bound at all? Only if my own value is both readable and writable: the forward wire
      # READS it and the return wire WRITES it. A widget whose value is COMPUTED — a patch node's
      # output, a fanout's input — declares no principal pin and so never offers this, which is
      # right: there is nothing to write back into.
      #   Public because it is asked of a candidate TARGET as well as of myself.
      canBind: ->
        pin = @principalPin()
        return pin?.setterName? and pin?.getterName?

      # Can I bind to THIS widget? Four conditions, one per thing that must be true for BOTH wires to
      # be real: neither of us is the other, each of us owns a read/write value, it can hold a wire
      # back (a capability probe, not a class test — widget-citizenship), and each principal pin
      # accepts the kind the other produces. The kind is checked twice because a bind is two wires and
      # each one has to be acceptable to the pin it writes.
      _canBindTo: (theTarget) ->
        return false if theTarget is @
        return false unless @canBind()
        return false unless theTarget.declareWireTo? and theTarget.canBind?()
        return false unless theTarget.principalPin().acceptsKind @producesPinKind
        return false unless @principalPin().acceptsKind theTarget.producesPinKind
        return true

      # Is this wire TWO-WAY — does the relationship it describes carry values in both directions?
      # Two shapes answer yes, and they are the engine's two production granularities:
      #   • a TRACKING wire (§P8): I drive its pin and re-read that same pin. Its reverse half is a
      #     firesOnAnyChange edge I declared, not a record the target holds.
      #   • a BOUND pair (§P2): the target holds a wire back onto MY principal pin.
      # Derived, never stored. A fact stated twice will disagree (PinSpec's header), and here the
      # drift is reachable in one gesture: duplicate half of a bound pair and the copy drives the
      # original while nothing drives the copy. Asked fresh, its row says ➜ and tells the truth with
      # no bookkeeping to duplicate, serialize or forget.
      _isTwoWayWire: (wire) ->
        return true if wire.tracks
        return false unless @canBind()
        return true if wire.target.isWiredToActionOf? @, @principalPin().setterName
        return false

      # Do I hold a wire driving `action` on `theTarget`? The PUBLIC sibling of _wireFor, and it
      # exists because this is a question another widget asks ME — "do you drive me back?" — which is
      # how a bind is recognised without either side recording that it is bound. Reaching into
      # _wireFor across objects is exactly what the [U] call-separation rule forbids.
      isWiredToActionOf: (theTarget, action) ->
        return (@_wireFor theTarget, action)?

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
      #   target[action].call target, theButton, subject, arg1, arg2   (ButtonWdgt)
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
      # action stays the menu-friendly public name everywhere (menus, hard-wired app circuits).
      _fireConnection: (value) ->
        # heal before deriving: a wire whose target DIED must neither re-declare its edge nor
        # count as "I have wires" (see _pruneWiresOntoDestroyedTargets).
        @_pruneWiresOntoDestroyedTargets()
        # ⭐ TWO JOBS, and the wire check belongs to only ONE of them. DELIVERING needs wires;
        # ANNOUNCING does not — a widget can be WATCHED by something it does not drive (a
        # firesOnAnyChange re-reader, §P8), which is exactly a FOLLOWER's situation. While the
        # announcement was a side effect of the delivery, removing the delivery removed it too, so an
        # unwired controller changed its value in total silence and nothing tracking it ever learned.
        # That is the hole `PinSpec.announces` would otherwise have had to describe on four pins
        # instead of being true of them.
        #   markNonValueChange rather than markStale, and here the two are behaviourally IDENTICAL: with
        # no wires there is no wire EDGE, so the only out-edges I can have are the re-reading ones, and
        # both verbs wake those. What differs is the cost of saying it to nobody — markNonValueChange
        # returns before pooling anything unless someone re-reads me, and these callers are plain
        # setters that run on every keystroke and are almost never watched.
        unless @wires?.length
          world.dataflow.markNonValueChange @
          return
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
      #   Dedup asks the index (hasEdge) rather than keeping a field of my own. That
      # reads "is there ANY edge target → me", which is the right question here: a target that drove me
      # back would be a two-wire ring, which no caller builds and which §P2 will address explicitly.
      _ensureTrackingEdges: ->
        return unless @wires?
        for wire in @wires when wire.tracks
          continue if world.dataflow.hasEdge wire.target, @
          world.dataflow.addEdge wire.target, @, action: "reflectTarget", firesOnAnyChange: true
        return

      # ---- THE FOLLOW GESTURE (connector plan §P2 residue) --------------------------------
      # PIN granularity's answer to `bind ⇄`, and it is not a second chooser: the wire the gesture
      # needs ALREADY EXISTS. "connect to ➔" offers every drivable pin, so a slider can already be
      # wired onto a scroll frame's `scroll y` today — what it cannot do is FOLLOW it. So the gesture
      # is a promotion of a wire you are already looking at, and it lands in that wire's own menu
      # beside "fires per event", costing the enclosing menu no row at all.
      #   ⭐ `trackTarget` was built to be its verb before it had one: its own note reads "say it
      # again for a plain wire being promoted to a tracking one — 'also follow what you already
      # drive' is a legitimate thing to ask twice". This is that caller.
      #   ⛔ What it is NOT is `bind ⇄` with a wider filter. §P2 restricted itself to principal ⇄
      # principal because at NODE granularity the precondition is equivalent to a checkable one; at
      # PIN granularity that equivalence breaks, so the precondition has to be ASKED, which is what
      # the three conditions below do.
      #
      # Can this wire also carry values BACK? Three things must hold, and each is asked of the party
      # that owns the answer:
      #   • I can only SHOW one value, so a second tracking wire would be a display with no way to
      #     render it (_trackingWire takes the first). One follow at a time.
      #   • the pin must be READABLE — there is nothing to re-read otherwise — and it must ANNOUNCE,
      #     or the re-read never happens and the follower goes quietly stale. Both are declared on
      #     the PinSpec, and `announces` exists for exactly this question.
      #   • I must be able to render THAT pin, which only I know (SliderWdgt._canReflectPin). A
      #     controller that declares no answer follows nothing, which is why the row is absent from
      #     every controller but the slider today.
      _canTrackWire: (wire) ->
        alreadyTracking = @_trackingWire()
        return false if alreadyTracking? and alreadyTracking isnt wire
        pin = wire.target.pinDrivenBy? wire.action
        return false unless pin?.getterName? and pin.announces
        return false unless @_canReflectPin?
        return @_canReflectPin wire.target, pin

      # Menu-dispatched (slots 1-2 are the dispatcher's — see setTargetAndActionWithOnesPickedFromMenu):
      # promote this wire to a tracking one, or demote it back to one-way.
      #   Promotion goes through the PUBLIC verb, so it takes the initial value FROM the target the
      # way every tracking bind does — the thumb jumps to where the content already is rather than
      # scrolling the content to where the thumb happened to be.
      #   Demotion revokes the reverse edge explicitly, exactly as unwireFrom does: the forward edge
      # is derived from the wire list and reconciles itself, but the re-reading one is an edge OUT of
      # the target that only I can revoke.
      # ANNOUNCE on the WIRE so every open menu showing the row re-ticks (a wire is not a
      # value-bearing node, so markNonValueChange is the only honest mark — see
      # toggleFiresPerEventOfWire).
      toggleTrackingOfWire: (ignored, ignored2, wire) ->
        if wire.tracks
          wire.tracks = false
          world.dataflow.removeAnyChangeEdge wire.target, @
        else
          @trackTarget wire.target, wire.action
        world.dataflow.markNonValueChange wire

      # ---- the connection menu -------------------------------------------------------------
      # The shared "connect a target" block, appended identically by every controller (SliderWdgt,
      # SimpleTextWdgt, PaletteWdgt, FanoutPinWdgt and the patch nodes) right after its `super`: a
      # divider, the "connect ➜" gesture submenu, then ONE ROW PER LIVE WIRE.
      #   ⭐ Those rows are the point of §P4. A single-slot controller had nothing to show — its one
      # connection was invisible, and re-targeting silently dropped it. A controller that owns a list
      # can SHOW what it drives, and each row opens that wire's own little menu (policy + disconnect),
      # so wiring is legible and reversible for the first time.
      #   ⛔ NO isIndexPage label fork: "set target" is the name of a SINGLE-SLOT world and would be a
      # false promise here, since the gesture connects *a* target, one of however many I already
      # drive. (StringWdgt keeps its own hand-rolled variant — it guards the whole block behind
      # isIndexPage, so it is deliberately NOT routed through here.)
      #   ⭐ The GESTURES are grouped behind one submenu row, and the live wires are not. That split is
      # the meaning of the two halves: "connect ➜" opens the things I can DO, while a wire row is a
      # thing that IS — a status line you read, and cut from where you read it.
      #   Grouping also costs the enclosing menu ZERO rows for the second gesture, and that thrift is
      # still worth keeping even though an over-tall pop-up now SCROLLS its rows rather than putting
      # them out of reach: a `SimpleTextWdgt` inside a scroll panel builds a merged menu of about full
      # height, so every top-level row this block adds is one the reader has to scroll past. Rows are
      # affordable here; free they are not. (The third gesture, "follows it too", costs nothing at
      # all — it lives in the wire's own menu, one level further down.)
      _addTargetConnectionMenuEntries: (menu) ->
        menu.addLine()
        menu.addMenuItem "connect ➜", @, "openConnectionGestureMenu", toolTip: "connect this widget\nto another one"
        @_addWireMenuEntries menu

      # The two ways to relate myself to another widget, one level down. They belong together: both
      # answer "which widget, and how", and they differ only in how many directions the relationship
      # carries values.
      #   The kind of property this controller can drive is read from `producesPinKind` -- the SAME
      # declaration its openTargetPropertySelector filters the target's pins by, so the tooltip
      # cannot describe a menu other than the one it opens. Taking the kind as an argument here
      # instead would let every controller state it twice, in two unrelated places, and nothing
      # would compare them. A widget that drives any kind names none: the sentence reads
      # "whose property".
      #   ⭐ `bind ⇄` appears only when there is something to bind to: the same rule `canBind` applies
      # to the SUBJECT, applied to the WORLD. The asymmetry with the always-offered "connect to ➜" is
      # earned rather than sloppy — almost anything has a drivable pin, so connecting is nearly always
      # possible, whereas binding needs the OTHER side to own a value of a matching kind, which is
      # rare and rarer still among the widgets I overlap. An item that is nearly always a dead end is
      # worse than no item. Asking here rather than in the enclosing menu also means the candidate
      # walk runs on a CLICK, not on every context menu a controller opens.
      openConnectionGestureMenu: ->
        menu = new MenuWdgt @, target: @, title: "connect:"
        kindWord = if @producesPinKind? and @producesPinKind isnt "any" then @producesPinKind + " " else ""
        menu.addMenuItem "connect to ➜", @, "openTargetSelector", toolTip: ("choose another widget\nwhose " + kindWord + "property\n will be" + " controlled by this one")
        if @canBind() and @_bindableTargets().length > 0
          menu.addMenuItem "bind ⇄", @, "openBindSelector", toolTip: "keep this widget's value\nand another's in step,\nboth ways"
        menu.popUpAtHand()

      # The bind target chooser. "connect to ➜" lists every plausible widget and filters PROPERTIES in
      # the menu after it; a bind has no property step — both pins are forced — so the filtering has
      # to happen HERE instead. A widget that cannot be bound therefore never appears, rather than
      # appearing and then having nothing to offer.
      # The widgets I could bind to right now: the same overlap-based candidate walk "connect to ➜"
      # uses, narrowed by the four conditions above. Asked TWICE per gesture — once to decide whether
      # to offer the item at all, once when the chooser opens — deliberately, rather than caching the
      # first answer on me: the world can change between building a menu and clicking its row, and a
      # stale list would offer a target that has moved away or died.
      _bindableTargets: ->
        each for each in world.plausibleTargetAndDestinationWidgets @ when @_canBindTo each

      openBindSelector: ->
        choices = @_bindableTargets()
        # the empty branch is not dead: the item is only offered when this list was non-empty, but
        # that was at menu-BUILD time, and a target can be dragged away or destroyed before the click.
        if choices.length > 0
          menu = new MenuWdgt @, target: @, title: "bind with:"
          # ⚠ TERMINAL, so it closes the pop-ups — unlike openTargetSelector's twin, which passes
          # closesUnpinnedPopUps: false because ITS click opens a second menu (the property chooser)
          # that has to stack on a chooser still standing underneath. Picking a bind target completes
          # the gesture, so leaving the cascade open would strand a menu with nothing left to do.
          choices.forEach (each) =>
            menu.addMenuItem (each.toString().replace "Wdgt", "").slice(0, 50) + " ⇄", @, "bindToOnePickedFromMenu", arg1: each, representsAWidget: true
        else
          menu = new MenuWdgt @, target: @, title: "nothing to bind with"
        menu.popUpAtHand()

      # Menu-dispatched (slots 1-2 are the dispatcher's — see setTargetAndActionWithOnesPickedFromMenu).
      bindToOnePickedFromMenu: (ignored, ignored2, theTarget) ->
        @bindTo theTarget

      # One row per live wire, each naming what it drives ("a Panel . color") and opening that wire's
      # own menu. Nothing at all when I am unwired, so an unconnected controller's menu is unchanged.
      # Shared with StringWdgt, which builds the rest of its connection block by hand.
      #   The ARROW is the whole reading of the relationship's direction: ➜ for a wire that only
      # drives, ⇄ for one that also carries values back — a tracking wire or half of a bound pair.
      # Derived per row at open time, so a menu never shows a direction that has stopped being true.
      _addWireMenuEntries: (menu) ->
        return unless @wires?
        for wire in @wires
          arrow = if @_isTwoWayWire wire then " ⇄" else " ➜"
          menu.addMenuItem wire.describeConnection() + arrow, @, "openWireMenu",
            toolTip: "what this connection does,\nand how to remove it"
            arg1: wire
        return

      # Menu-dispatched (slots 1-2 are the dispatcher's — see setTargetAndActionWithOnesPickedFromMenu):
      # the per-wire menu behind a connection row. Three entries at most: change how it delivers,
      # make it two-way, or cut it. The middle one appears only when the relationship can really
      # carry values back (_canTrackWire) — the same rule `bind ⇄` follows, and for the same reason:
      # an item that is nearly always a dead end is worse than no item.
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
        if @_canTrackWire wire
          followLabel = "follows it too"
          menu.addMenuItem followLabel, @, "toggleTrackingOfWire",
            toolTip: "also FOLLOW this property,\nso the two stay in step\nhowever either one moves"
            arg1: wire
            # ticks off the WIRE, like the row above: tracking is a property of the relationship
            reflection: MenuRowReflectionSpec.tickWhen wire, "isTracking", true, followLabel
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
      #   ⭐ A TWO-WAY relationship ends in BOTH directions, because that is the relationship the row
      # named. Cutting only my half would leave a wire that still reads as a connection from the
      # OTHER widget's menu and cannot be seen at all from this one. A tracking wire already behaves
      # this way — unwireFrom revokes the reverse edge it declared — so this is the same rule reaching
      # the other kind of two-way wire, not a second rule.
      #   The reciprocal call is unconditional and needs no guard: unwireFrom returns at once when
      # there is no such record, so a one-way wire simply loses its one half. It also cannot recur —
      # it is unwireFrom being called, not disconnectWire.
      disconnectWire: (ignored, ignored2, wire) ->
        theTarget = wire.target
        myPin = @principalPin()
        @unwireFrom theTarget, wire.action
        theTarget.unwireFrom? @, myPin.setterName if myPin?.setterName?

