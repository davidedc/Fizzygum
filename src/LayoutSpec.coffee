# LayoutSpec
# ...just giving some convenient names to constants/singletons

class LayoutSpec

  # if a widget is attached as "free floating" it means that its extent
  # either does not depend on the extent of its parent or, if it does depend
  # on the extent of its parent, it's the parent's responsibility to
  # update its extend in its _reLayout method.
  # In other words, the layouting system doesn't handle it specifically,
  # rather the parent has to take care of it.
  # TODO this should be split into two constants, one for the
  # "ATTACHEDAS_CONSTANTSIZE" (I would assume very rarely used), and one for the
  # "ATTACHEDAS_CUSTOM_SIZED_BY_PARENT" case (default),
  # so it's clearer what it means.
  @ATTACHEDAS_FREEFLOATING: 100000
  @ATTACHEDAS_VERTICAL_STACK_ELEMENT: 100002
  @ATTACHEDAS_FRAME_CONTENT: 100003

  @ATTACHEDAS_STACK_HORIZONTAL_VERTICALALIGNMENTS_UNDEFINED: 100004

  


  @ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT: 100014
  @ATTACHEDAS_CORNER_INTERNAL_TOPLEFT: 100015
  @ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT: 100016
  @ATTACHEDAS_CORNER_INTERNAL_RIGHT: 100017
  @ATTACHEDAS_CORNER_INTERNAL_BOTTOM: 100018

  # TRUE iff `spec` is one of the five corner/edge-internal attachment specs above -- a
  # child placed by base Widget._reLayout's corner pass (handles etc.). ONE home for the
  # five-way test Widget._reLayout used to write out twice.
  @isCornerOrEdgeInternal: (spec) ->
    spec == @ATTACHEDAS_CORNER_INTERNAL_TOPRIGHT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_TOPLEFT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_BOTTOMRIGHT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_RIGHT or
    spec == @ATTACHEDAS_CORNER_INTERNAL_BOTTOM


  # »>> this part is excluded from the fizzygum homepage build
  # TODO
  # These should go in a separate constants class,
  # maybe "LayoutSpreadibilityConsts", because the
  # ones above are (two) enums, these below are constants
  # (in enums, the actual value of the enum is not used)
  @SPREADABILITY_HANDLES: 1
  @SPREADABILITY_NONE: 10
  @SPREADABILITY_MEDIUM: 1000
  @SPREADABILITY_SPACERS: 100000000
  # this part is excluded from the fizzygum homepage build <<«
