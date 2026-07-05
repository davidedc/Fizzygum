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
        @connectionsCalculationToken = world.makeNewConnectionsCalculationToken()
        # 6b -- a wire IS a dataflow edge (spec §8): declare producer(me) -> target in the engine index, with
        # the action + the Phase-6a firesPerEvent policy riding the edge record. Re-wiring drops my single old
        # out-edge first. The index is derived/disposable (spec §2), re-declared by the client on load/copy --
        # here the client is the wire itself, re-declaring on every (re)connection.
        if world.dataflowWiresEnabled
          world.dataflow.removeOutgoingEdgesOf @
          world.dataflow.addEdge @, @target, {action: @action, firesPerEvent: @firesPerEvent}
        # reactToTargetConnection is left UNCHANGED across every controller: via the gated _fireConnection it
        # markStale's me (the initial fire), so each keeps its exact on-connect semantics -- a slider/text fires
        # its current value, PaletteWdgt's empty override fires nothing, Example3DPlot recomputes its plot.
        # Non-forced is sufficient (a fresh wire's producer value differs from the target's, so it propagates).
        @reactToTargetConnection?()

      # The ONE reactive-connection dispatch: fire @action on @target with `value` (+ the optional per-connection
      # argument), routing to the target's dedicated _<action>Connector variant when it defines one (the reactive
      # settle lane that JOINS an enclosing settle -- Widget._settleLayoutsAfterOrJoinEnclosingPass /
      # check-layering [P]) and to the public @action otherwise (setValue / setInput1 / setColor / ... never open
      # a settle, so the public name is already sound -- census: connection-cascade-settle-fix-plan.md fact 13).
      # Resolving HERE -- not at the call sites -- keeps @action the menu-friendly public name everywhere
      # (menus, <action>IsConnected flags, hard-wired app circuits) and gives the routing a single home.
      _fireConnection: (value, argumentToAction = nil) ->
        return unless @target? and @action and @action != ""
        # 6b -- under the engine a wire carries NO value: it only marks me STALE, and the drain PULLS my
        # dataflowValue when it delivers along my edge (spec §3, notifications carry no values). So every
        # controller's updateTarget (`@_fireConnection <myValue>`) becomes a markStale with no per-controller
        # change; the pushed value/argumentToAction are ignored (the pull is the source of truth). markStale is
        # echo-suppressed while the engine is applying me (DataflowEngine.markStale). A wire-less widget still
        # returns above, matching legacy (no target = no fire).
        if world.dataflowWiresEnabled
          world.dataflow.markStale @
          return
        connectorName = "_#{@action}Connector"
        actionToCall = if @target[connectorName]? then connectorName else @action
        @target[actionToCall].call @target, value, argumentToAction, @connectionsCalculationToken

      # ---- firesPerEvent: per-wire delivery policy (dataflow migration; spec §4/§8, ----
      # ---- implementation-plan Phase 6a) --------------------------------------------------
      # false (default) = POOLED: under the engine, ten drag events + a tick in one frame collapse
      #   to ONE recompute batch, drained once per cycle using final values.
      # true = PER-EVENT: a synchronous mini-pass inside each event (side-effects-per-event,
      #   read-your-writes within a frame), at N× the evaluation cost.
      # In Phase 6a this is DARK: the flag is stored and toggled from the menu, but nothing READS it
      # yet -- legacy _fireConnection delivery still runs unchanged, so pixels are unaffected. Phase 6b
      # (engine delivery behind world.dataflowWiresEnabled) reads it when it declares the edge, letting
      # it ride the edge record's opts. Declared as a PROTOTYPE default (not assigned per instance),
      # so an untoggled wire carries NO own `firesPerEvent` property and serializes byte-for-byte as
      # before -- the same own-only-when-set idiom as @target / @action.
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

