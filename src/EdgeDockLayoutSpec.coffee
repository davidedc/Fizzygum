# EdgeDockLayoutSpec

# The sixth member of the per-child LayoutSpec family: the spec a DOCKED frame carries — the
# host's statement that this child lives against one of its four edges, as a band spanning that
# edge (program ruling C12). Docking is a PLACEMENT, not a kind of widget: the very same frame
# that sits in a slot floats on the desktop the moment it is dragged out, because leaving the
# slot is exactly dropping this spec.
#
# `side` is which edge I take — 'top' | 'left' | 'right' | 'bottom'. An edge holds every frame
# docked at it, side by side from the host's edge inward, the latest nearest the content (the host
# keeps each side's list, FrameWdgt.dockedFrames, and places the bands by it); a dock never
# displaces a band already there. What the band grants my PAYLOAD across the edge (the band adds
# its own chrome on top of it, so the payload gets the extent it asked for) is
# `thicknessGrantedTo`: the payload's own `dockThickness` when it declares one (a toolbar's,
# derived from the theme's grid dials at every measure, at the depth in cells I record for a
# payload that arrived from somewhere, `depthInCells`, else at its own depth), else `thickness`,
# the payload's cross extent as it arrived. Either way it is a PURE number the host's chrome
# measures read (never a laid-out extent), which is why what the payload arrived with -- a count
# of cells, or an extent -- is recorded here rather than measured off the band each pass.
# `engaged` is the HOST's mode switch, per band (`engagedUnder`): a host showing its content in view
# mode puts away a band whose payload is there for editing (a toolbar), which takes that band's
# layout contribution to zero, and any other band (a docked document, a band whose payload left)
# stands in both modes — visibility then FOLLOWS the spec, never the other way round (visibility is
# never a layout input).
# `broughtByContent` records who made this attachment: the host, docking its content's toolbar (at
# its birth, its rebuild, or its "Toolbar" row: FrameWdgt._buildDockedToolbarNoSettle), or a
# person's drop; a content change retires only the bands its content brought, and every band a
# person docked stays.
#
# I OWN my carrier's placement (the family default): the host places the band, so a docked frame
# is not free-floating, and everything that turns on that predicate follows for free — no close
# piece and no resize handle (ruling C6: a host that owns placement owns membership, and you
# leave by dragging out), and a bar laid out for the band's shape (ruling C13).
#
# I name no host type. Any container whose arrange drives its slots can hold docked frames; today
# FrameWdgt is the one that does.
class EdgeDockLayoutSpec extends LayoutSpec

  # 'top' | 'left' | 'right' | 'bottom'
  side: undefined

  # the payload's cross extent as it arrived (width for left/right, height for top/bottom), which
  # the band grants a payload that declares no dockThickness of its own; undefined for one that does,
  # until that payload leaves the band (notePayloadLeft)
  thickness: undefined

  # a RECORD of how many cells deep my carrier's payload stood as it arrived from somewhere (a
  # window on the desktop, a frame on the hand): for a payload that measures itself in cells (a
  # toolbar), the whole cells its shorter side held (ToolbarWdgt.depthInCellsAsIStand), which the
  # band grants it again (thicknessGrantedTo). A COUNT, so the pixels it means are derived at every
  # measure, in the theme of the world that lays the band out. undefined for any other payload, and
  # for one that arrived with no shape of its own (a frame fresh from its constructor), which docks
  # at its own depth. Written by the host as it builds me (FrameWdgt._edgeDockSpecFor); a re-side
  # keeps it, since it edits this spec, and a copy and a save carry it.
  depthInCells: undefined

  # the host's mode switch, as engagedUnder answers it: a disengaged dock takes no layout space
  engaged: true

  # a RECORD of this attachment: my carrier holds the toolbar my host docked for its content
  # (FrameWdgt._buildDockedToolbarNoSettle, the one door that writes it), which goes when that content
  # goes; false for a frame a person docked, whatever it holds. A re-side, a collapse and a mode flip
  # keep it (the first and the last edit this spec, a collapse leaves it as it is); a copy and a save
  # carry it; a band floated and docked again arrives
  # under a fresh spec, a person's. Cleared when my carrier's payload leaves it (notePayloadLeft):
  # what the band holds next is not what the content brought.
  broughtByContent: false

  constructor: (@side, @thickness) ->
    super()

  # What the band grants `payload` ACROSS the edge: the thickness it declares for itself, asked
  # now at the depth in cells recorded when it arrived (its own depth where none was), or else the
  # cross extent recorded when it arrived.
  thicknessGrantedTo: (payload) ->
    payload?.dockThickness?(@depthInCells) ? @thickness

  # Whether the band stands ENGAGED holding `payload`, under a host whose mode engages every dock
  # or not (`hostEngagesEveryDock`: editing, or holding no mode at all). A viewing host puts away
  # only a payload that is there for editing (isAnAmenityForEditing, a capability: a toolbar
  # answers it), and every other band stands. Pure: the host writes the answer, at a fresh dock and
  # at a mode flip (FrameWdgt._edgeDockSpecFor, _engageDocksNoSettle), so the rule has this one
  # home.
  engagedUnder: (hostEngagesEveryDock, payload) ->
    hostEngagesEveryDock or not payload?.isAnAmenityForEditing?()

  # My carrier's payload has LEFT it (FrameWdgt._reactToChildRemoved, before the carrier shows its
  # placeholder): the band keeps its thickness, as every window whose content leaves keeps its size.
  # So I keep what the departing payload was granted -- the cross extent I recorded at its arrival, or,
  # for a payload that declared its own dockThickness, that thickness at the depth in cells it stood
  # docked at -- and grant it to whatever the band holds next that declares none (the placeholder).
  # And I stop recording the band as what its host's content brought, since what it holds next is
  # not that: an emptied band is a person's, kept across the host's content changes, and the host,
  # wearing no band its content brought, offers that toolbar again on its "Toolbar" row and docks it
  # afresh at its next rebuild.
  notePayloadLeft: (payload) ->
    @thickness ?= @thicknessGrantedTo payload
    @broughtByContent = false
    return

  # The axis the band I give runs along: the length of my edge. A top or bottom band runs across its
  # host, a left or right one down it. My carrier's RUN (FrameWdgt._runAxis), whether it is expanded
  # or collapsed: the slot keeps its shape either way.
  runAxis: ->
    if @side is "top" or @side is "bottom" then "horizontal" else "vertical"

  # Capability query (duck-typed at the call sites): am I an edge dock?
  isEdgeDock: ->
    true
