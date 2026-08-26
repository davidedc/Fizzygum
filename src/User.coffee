# User — the PERSON at the machine, and the modal state they carry from one widget to the next:
# what they are HOLDING, not what any widget owns. A plain delegated collaborator (the
# UntitledNamingService / DataflowEngine pattern), NOT a Widget: the world HAS-A list of them,
# `world.users`, with `world.user` naming the one who is acting.
#
# WHY THE STATE LIVES HERE. A toolbar is a destination-generic INSTRUMENT: the same Draw palette
# serves whichever image is in reach (PaintToolbarWdgt.resolveInjectionTarget), so a tool armed on
# one palette is not that palette's property -- it is the person's. Parking it on a palette makes
# the instrument owner-specific by accident, and two drawings open at once then disagree about
# what the one person is holding. A palette is a VIEW of this fact and a CONTROLLER that writes
# it; the fact itself has exactly one home.
#
# ── THE ANNOUNCE SEAM ────────────────────────────────────────────────────────────────────────
# I am a dataflow NODE (DataflowEngine's duck-typed node protocol: any object the engine holds by
# identity -- the SecondsSource / FrameSource precedent for a non-widget source). A change here
# ANNOUNCES with markNonValueChange, the weaker of the two verbs, because a person has no single
# VALUE for a wire to carry: my watchers RE-READ me. They subscribe with `firesOnAnyChange`, which
# is exactly the seam a reflecting menu row uses (MenuItemWdgt._subscribeToMyReflectedSource), one
# level up: a row reflects a widget's property, a palette reflects a person's hand.
#
# ── WHAT IS AND IS NOT MINE ──────────────────────────────────────────────────────────────────
# `world.editorFocusWdgt` (which widget the person is editing) and `world.caret` (where their
# typing goes) are the same KIND of fact and are future kin here -- they stay where they are
# today; moving them is not this arc's business.
#   Multi-user INPUT ATTRIBUTION is out of scope: `world.users` is a list because the concept is
# per-person, and it holds ONE member today. Nothing here decides which person an incoming event
# belongs to, and no pointer/keyboard path consults me.
class User

  # THE TOOL IN HAND: a tool KEY ('pencil' | 'brush' | 'toothpaste' | 'eraser'), or undefined for
  # an empty hand. A KEY and never a widget: the person holds a pencil, not one particular
  # palette's pencil button, and a key survives the death of every palette that ever showed it.
  #   Born holding a pencil, which is the same statement ImageWdgt makes when it builds a drawing
  # with the pencil source already injected (a new drawing is born editable, ready to draw).
  armedDrawingTool: 'pencil'

  # THE ONE WRITE, and it only STATES the fact: this tool is now in hand (undefined = an empty
  # hand, which paints nothing). IDEMPOTENT -- arming what is already held changes nothing and
  # announces nothing -- so re-stating a recorded hand, as a restored snapshot does, is as safe as
  # changing it. That a SECOND TAP on the tool in hand means "put it down" is the meaning of a
  # gesture, not of this fact, so it is decided where the gesture is (PaintToolbarWdgt.selectTool).
  armDrawingTool: (toolKey) ->
    return if toolKey is @armedDrawingTool
    @armedDrawingTool = toolKey
    # markNonValueChange, not markStale: see the announce seam above. DARK when nobody watches.
    world.dataflow?.markNonValueChange @
    return
