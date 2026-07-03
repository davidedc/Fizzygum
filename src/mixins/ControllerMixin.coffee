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
        connectorName = "_#{@action}Connector"
        actionToCall = if @target[connectorName]? then connectorName else @action
        @target[actionToCall].call @target, value, argumentToAction, @connectionsCalculationToken

