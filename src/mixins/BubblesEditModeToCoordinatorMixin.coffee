# Bubbles the pencil/eye edit-mode toggle UP to an editing-coordinating parent.
# The injected enable/disable CORE asks its parent
# `coordinatesDragsDropsAndEditingForChildren?()` (the capability query that replaced
# the old `instanceof` type-tests -- type-test-elimination campaign; Widget defines a
# base enableDragsDropsAndEditing, so a bare `@parent.enableDragsDropsAndEditing?()`
# would bubble to ANY parent, the query keeps it to the coordinator) and, when the
# parent is a coordinator it did not itself trigger, relays the toggle to it;
# otherwise it does the local Widget work via super.
# Only the CORES (_enable/_disableDragsDropsAndEditingNoSettle) are injected here:
# each consumer's public enable/disableDragsDropsAndEditing wrappers are the
# canonical settle-wraps and dispatch straight back to these -- they stay where they
# are today (on ViewportWdgt for the scroll-panel consumer, on the two
# Stretchables themselves).
# The consumers sit on unrelated branches (ViewportWdgt / PanelWdgt / Widget) and
# the behaviour must BE each class's own core override (the settle machinery
# dispatches to the _...NoSettle cores polymorphically), so injection is the right
# tool (docs/architecture/mixins.md §1).
BubblesEditModeToCoordinatorMixin =
  # class properties here:
  # none

  # instance properties to follow:
  onceAddedClassProperties: (fromClass) ->
    @addInstanceProperties fromClass,

    # ⭐ THESE TWO CORES ARE THE ONLY READERS OF `triggeringWidget` IN THE TREE — the one use is the
    # `@parent != triggeringWidget` test just below, which stops the toggle bouncing back to whoever
    # raised it. Every OTHER core in the family — Widget's, FrameWdgt's, ViewportWdgt's — takes no
    # such parameter, so a value handed to one of those would simply be dropped. Hence: pass it in
    # from a public wrapper that has one (the two Stretchables, and Widget.editButtonPressedFromFrameBar,
    # which supplies a real widget), let the fallback below stand in for a menu click that has no
    # triggering widget, and `super()` WITHOUT it, because every core this can reach takes none.
    _enableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
      if !triggeringWidget? then triggeringWidget = @
      if @dragsDropsAndEditingEnabled
        return
      @parent?.showEditModeInBar?()
      if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
        @parent._enableDragsDropsAndEditingNoSettle @
      else
        super()

    _disableDragsDropsAndEditingNoSettle: (triggeringWidget) ->
      if !triggeringWidget? then triggeringWidget = @
      if !@dragsDropsAndEditingEnabled
        return
      @parent?.showViewModeInBar?()
      if @parent? and @parent != triggeringWidget and @parent.coordinatesDragsDropsAndEditingForChildren?()
        @parent._disableDragsDropsAndEditingNoSettle @
      else
        super()
