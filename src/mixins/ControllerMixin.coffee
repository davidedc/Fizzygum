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
          menu = new MenuWdgt @, false, @, true, true, "choose target:"
          #choices.push @world()
          choices.forEach (each) =>
            if !(each.isConnectionPin?())
              menu.addMenuItem (each.toString().replace "Wdgt", "").slice(0, 50) + " ➜", false, @, "openTargetPropertySelector", nil, nil, nil, nil, nil, each, nil, true
        else
          menu = new MenuWdgt @, false, @, true, true, "no targets available"
        menu.popUpAtHand()

      setTargetAndActionWithOnesPickedFromMenu: (ignored, ignored2, theTarget, each) ->
        @target = theTarget
        @action = each
        if @target[@action + "IsConnected"]?
          @target[@action + "IsConnected"] = true
        # a wire IS a dataflow edge (spec §8): declare producer(me) -> target in the engine index, with the
        # action + the Phase-6a firesPerEvent policy riding the edge record (ensureWireEdge drops my single old
        # out-edge first on a re-wire). The index is derived/disposable (spec §2), re-declared by the client on
        # load/copy -- here the client is the wire itself. Declaring EAGERLY here is an optimisation (the edge
        # exists the moment a menu wire is made); _fireConnection re-derives it LAZILY too, which is what covers
        # the wires that never reach this method (direct @target/@action assignment -- scrollbars, prompt sliders).
        world.dataflow.ensureWireEdge @, @target, {action: @action, firesPerEvent: @firesPerEvent}
        # reactToTargetConnection is left UNCHANGED across every controller: via _fireConnection it
        # markStale's me (the initial fire), so each keeps its exact on-connect semantics -- a slider/text fires
        # its current value, PaletteWdgt's empty override fires nothing, Example3DPlot recomputes its plot.
        # Non-forced is sufficient (a fresh wire's producer value differs from the target's, so it propagates).
        @reactToTargetConnection?()

      # A wire's producer marks ITSELF stale -- the ONE onward-fire every controller's updateTarget calls. It
      # derives the producer->target edge from @target/@action (ensureWireEdge) and marks me stale; the engine's
      # drain then PULLS my dataflowValue and DELIVERS it to @target (DataflowEngine._applyWireValue), routing to
      # the target's dedicated _<action>Connector variant when it defines one (the reactive settle lane that
      # JOINS an enclosing settle -- Widget._settleLayoutsAfterOrJoinEnclosingPass / check-layering [P]) and to
      # the public @action otherwise (setValue / setInput1 / setColor / ... never open a settle, so the public
      # name is already sound -- census: connection-cascade-settle-fix-plan.md fact 13). @action stays the
      # menu-friendly public name everywhere (menus, <action>IsConnected flags, hard-wired app circuits).
      _fireConnection: (value, argumentToAction = nil) ->
        return unless @target? and @action and @action != ""
        # under the engine a wire carries NO value: it only marks me STALE, and the drain PULLS my dataflowValue
        # when it delivers along my edge (spec §3, notifications carry no values). So every controller's
        # updateTarget (`@_fireConnection <myValue>`) is a markStale with no per-controller change; the pushed
        # value/argumentToAction are ignored (the pull is the source of truth). markStale is echo-suppressed
        # while the engine is applying me (DataflowEngine.markStale). A wire-less widget returns above (no fire).
        #   Derive my edge from @target/@action if it isn't declared yet: a scrollbar (ScrollPanelWdgt) or a
        # prompt slider (PromptWdgt) wires by DIRECT @target/@action assignment, never through the menu that
        # declares the edge -- spec §8 says edges DERIVE from @target/@action, so make that derivation total.
        # Without this such a wire would markStale with no out-edge and deliver nothing (silently broken scroll).
        # Idempotent for a menu-wired connection (the eager declaration already matches); no-op mid-drain.
        world.dataflow.ensureWireEdge @, @target, {action: @action, firesPerEvent: @firesPerEvent}
        world.dataflow.markStale @
        return

      # ---- firesPerEvent: per-wire delivery policy (dataflow; spec §4/§8) ------------------
      # false (default) = POOLED: ten drag events + a tick in one frame collapse to ONE recompute
      #   batch, drained once per cycle using final values.
      # true = PER-EVENT: a synchronous mini-pass inside each event (side-effects-per-event,
      #   read-your-writes within a frame), at N× the evaluation cost.
      # The flag rides the edge record's opts (ensureWireEdge). The PER-EVENT lane is still DEFERRED
      # -- delivery POOLS regardless of the flag (the two are screen-indistinguishable, spec §13); the
      # menu toggle stores it against the day the mini-pass lands. Declared as a PROTOTYPE default (not
      # assigned per instance), so an untoggled wire carries NO own `firesPerEvent` property and
      # serializes byte-for-byte as before -- the same own-only-when-set idiom as @target / @action.
      firesPerEvent: false

      # Flip the per-wire delivery policy (the "✓ fires per event" menu toggle). A plain boolean flip:
      # no layout and no tree mutation, hence no settle (check-layering-clean); nothing visual changes.
      toggleFiresPerEvent: ->
        @firesPerEvent = not @firesPerEvent

      # The shared connection-menu entry: every controller (SliderWdgt, StringWdgt, the patch nodes, …)
      # calls this right after its own "connect to ➜" / "set target" item, so the toggle lives in one
      # place. Shown only once a target is wired (firesPerEvent is a property OF a wire); a leading ✓
      # reflects the current state (String::tick — matched in tests by the "fires per event" substring).
      addFiresPerEventMenuEntry: (menu) ->
        return unless @target?
        label = "fires per event"
        menu.addMenuItem (if @firesPerEvent then label.tick() else label), true, @, "toggleFiresPerEvent", "deliver on every event (a synchronous mini-pass)\ninstead of once per cycle"

