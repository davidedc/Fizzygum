# IMMUTABLE — see the InputEvent header.
# ONE family for every pointer kind: a mouse, a pen and a finger all arrive as W3C Pointer
# Events, so the kind rides each EVENT as `pointerType` (a hybrid device switches kind between
# strokes) rather than being implied by which listener set delivered it.
# see https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent
class PointerInputEvent extends InputEvent

  # WORLD (canvas logical) coordinates — the plane the hand lives in. BOTH are `undefined` when
  # the event states no place of its own, which means "wherever the pointer is when this event is
  # consumed": a synthesised down/up is built while the moves ahead of it are still queued, so
  # schedule-time code cannot know the position the hand will hold at drain time, and absence is
  # the honest value.
  worldX: undefined
  worldY: undefined

  # 'mouse' | 'pen' | 'touch'
  pointerType: undefined
  pointerId: undefined
  isPrimary: undefined
  pressure: undefined

  button: undefined
  buttons: undefined

  ctrlKey: undefined
  shiftKey: undefined
  altKey: undefined
  metaKey: undefined

  constructor: (@worldX, @worldY, @pointerType, @pointerId, @isPrimary, @pressure, @button, @buttons, @ctrlKey, @shiftKey, @altKey, @metaKey, isSynthetic, time) ->
    super isSynthetic, time

  # THE BROWSER BOUNDARY. A browser pointer event states PAGE coordinates, so the page → world
  # conversion happens here and only here, together with the rounding to whole pixels: a pointer
  # position can be fractional (a finger, a scaled page) and the rest of the system has no use for
  # fractional input positions, which complicate drawing and clipping. Construction itself is
  # PURE — this static is the one place the global `world` is read.
  @fromBrowserEvent: (event, isSynthetic, time) ->
    canvasPosition = world.getCanvasPosition()
    worldX = Math.round event.pageX - canvasPosition.x
    worldY = Math.round event.pageY - canvasPosition.y
    new @ worldX, worldY, event.pointerType, event.pointerId, event.isPrimary, event.pressure, event.button, event.buttons, event.ctrlKey, event.shiftKey, event.altKey, event.metaKey, isSynthetic, time

  # THE SYNTHESIS BOUNDARY (the macro toolkit). Everything a browser reports about the pointer
  # DEVICE is a deterministic constant here: one primary mouse, no pressure. `worldX`/`worldY`
  # come last because only a move states a place — a down/up omits them (see the field comment
  # above), so no caller passes a hole to reach a later argument.
  @synthetic: (button, buttons, ctrlKey, shiftKey, altKey, metaKey, time, worldX, worldY) ->
    new @ worldX, worldY, 'mouse', 1, true, 0, button, buttons, ctrlKey, shiftKey, altKey, metaKey, true, time

  # THE SAME BOUNDARY FOR A FINGER — one factory per KIND, rather than one factory taking a kind,
  # because what differs is precisely the DEVICE constants each bakes: a finger reports a pressure
  # where a mouse reports none. The argument list is the mouse factory's, unchanged, so a caller
  # learns nothing new to synthesise the other kind. `worldX`/`worldY` are effectively required
  # here: a finger's every event states its own place, because there is no hover to have walked
  # the pointer there (the position head in ActivePointerWdgt.processPointerDown).
  @syntheticTouch: (button, buttons, ctrlKey, shiftKey, altKey, metaKey, time, worldX, worldY) ->
    new @ worldX, worldY, 'touch', 1, true, 0.5, button, buttons, ctrlKey, shiftKey, altKey, metaKey, true, time
