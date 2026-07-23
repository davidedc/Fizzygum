# The SHELF: the world's off-tree resting place for widgets that are CLOSED but
# still REACHABLE -- through a shortcut chain or a world field (the simulated
# disk). Its twin is the bin (BinWdgt), which holds the LOST ones; the standing
# invariant is: everything on the shelf is reachable, everything in the bin is
# lost, at all times (kept true eagerly by the storage sort, see
# docs/archive/bin-shelf-eager-sorting-plan.md).
#
# I am a pure backing store: no opener, no icon, no window path, no view. I am
# never on the tree and never painted -- residents are re-homed out of me by
# their revival paths (shortcut click, app launch) exactly as they are out of
# the bin.
class ShelfWdgt extends PanelWdgt

  colloquialName: ->
    "Shelf"

  # a closed-but-reachable widget comes to rest here. A core: called only from
  # close()'s private chain (the save-close path) and the storage sorter's
  # drain, inside their settle batches. Unlike the bin's scatter (a view,
  # arranged for people), I hold residents directly and wherever they land --
  # position on a never-viewed store carries no meaning.
  _addRestingWidgetNoSettle: (w) ->
    @_addNoSettle w

  # is w currently resting on the shelf? Same look-through as BinWdgt.holds: a
  # tilted/scaled or explicitly-islanded widget is re-homed AS ITS FIGURE (w's
  # parent is then the island), so classify against w's REAL container through
  # any sole-content island wrap.
  holds: (w) ->
    p = w._parentThroughIslands()
    p? and p == @

  # NOT homepage-excluded: the snapshot-load teardown
  # (WorldWdgt._teardownForSnapshotLoadNoSettle) ships in --homepage and
  # empties the storage containers through this.
  empty: ->
    @fullDestroyChildren()
