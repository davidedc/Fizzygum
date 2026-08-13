# StretchLayoutSpec

# The fifth member of the per-child LayoutSpec family: the proportional placement RECORD
# a child carries inside a fractional-consuming holder (StretchablePanelWdgt: full
# proportional re-lay; the WorldWdgt desktop: position-only reflow on browser resize).
#
# Unlike its four siblings this spec does NOT own the child's placement (`ownsPlacement`
# false — the family base declares true): it is FOLLOWER memory. The child's actual
# geometry stays authoritative — the user moves/resizes the child freely (it stays
# free-floating in every Widget.isFreeFloating sense while carrying me), and the record
# TRAILS the gestures through the framework's record moments; the holder reads it only at
# its OWN re-lay, to re-derive the child's place proportionally at the new holder size.
#
# EDGE encoding (not position+extent): the four fractions are the child's EDGES in the
# holder's box, and imposed extents are DERIVED from independently rounded edges
# (grantedBoundsWithin) — so two children recorded abutting share the same edge fraction
# and round identically at EVERY holder size: seams/overlaps are unrepresentable. Same
# round-the-boundary idiom as StackLayoutEngine's placement loop.
#
# The record LAW (stretch-fractional auto-bookkeeping arc, measured): edges are recorded
# at INTENT moments — the world's fill drain when the child enters a holder, and the F6
# re-record family (drop / duplicate / file-load / app re-home / spawnNextTo-of-stored /
# uncollapse / handle-release) — and never re-derived from imposed integers (rounding
# drift). `provisional` is the ONE sanctioned overwrite gate: the stretch arrange's
# pre-placement heal marks its guess provisional, and the fill drain re-derives
# provisional records ONCE at builder-final geometry, recording them.
#
# LIFECYCLE is per ATTACHMENT (the family's per-class lifecycle law): created at record
# moments and armed as the child's ACTIVE layoutSpec, cleared by grab/reparent like any
# active spec — re-entry into a holder derives a fresh record. It serializes/duplicates
# with the child like every spec.
class StretchLayoutSpec extends LayoutSpec

  leftFraction: undefined
  topFraction: undefined
  rightFraction: undefined
  bottomFraction: undefined

  # the child was deliberately placed sticking out of its holder: the desktop's reflow
  # then skips its keep-within clamp, so the widget stays outside on purpose
  wasPositionedSlightlyOutsidePanel: false

  # true = a pre-placement guess (the stretch arrange's heal); recorded specs are never
  # overwritten by the fill drain (the fill-only law) — provisional ones are, once
  provisional: false

  isStretchElement: ->
    true

  # I FOLLOW the child, I don't place it between the holder's re-lays — the child stays
  # free-floating (user-movable, non-climbing) while carrying me. See the family base.
  ownsPlacement: ->
    false

  # Record the figure's CURRENT edges in its holder. Called only from the framework's
  # record moments (the world drains, the F6 recorder, the stretch arrange's heal) —
  # never from feature code.
  recordFor: (fig, provisional = false) ->
    holder = fig.parent.bounds
    @leftFraction = (fig.left() - holder.left()) / holder.width()
    @topFraction = (fig.top() - holder.top()) / holder.height()
    @rightFraction = (fig.right() - holder.left()) / holder.width()
    @bottomFraction = (fig.bottom() - holder.top()) / holder.height()
    @wasPositionedSlightlyOutsidePanel = !holder.containsRectangle fig.bounds
    @provisional = provisional
    return

  # The child's integer target box at holder size `holderBounds` — each edge rounded
  # independently, so abutting children (equal edge fractions) share every rounded
  # boundary. PURE: inputs are spec fields + the granted holder bounds, never laid-out
  # pixels (the engine rulebook's no-read-backs rule).
  grantedBoundsWithin: (holderBounds) ->
    new Rectangle \
      holderBounds.left() + Math.round(@leftFraction * holderBounds.width()),
      holderBounds.top() + Math.round(@topFraction * holderBounds.height()),
      holderBounds.left() + Math.round(@rightFraction * holderBounds.width()),
      holderBounds.top() + Math.round(@bottomFraction * holderBounds.height())
