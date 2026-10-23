# FileLoading — ingest a Fizzygum file (drag-dropped onto the desktop, or chosen through a
# file dialog) and route it by the envelope's `kind` field, NEVER by the filename. See
# docs/architecture/serialization-duplication-reference.md §10. A PRODUCT feature — ships in all builds.
#
# The single file extension is `*.fzw.json` (plain JSON inside); a `kind:"widget"` file
# restores a detached widget attached at the drop point, a `kind:"world"` file loads a whole
# world snapshot (§11). Non-Fizzygum files are rejected with a friendly inform.
class FileLoading

  # A hidden <input type=file>, created on demand and clicked from an "Open from file…" menu
  # item (a user gesture, so it is allowed over file://).
  @openFromFileDialog: ->
    input = document.createElement "input"
    input.type = "file"
    input.accept = ".json,application/json"
    input.style.display = "none"
    input.onchange = =>
      @loadFile input.files[0] if input.files? and input.files.length > 0
      input.remove?()
    document.body.appendChild input
    input.click()
    return

  # Read a File object (from drag-drop or the dialog) as text, then route it.
  @loadFile: (file, dropPoint) ->
    return unless file?
    reader = new FileReader
    reader.onload = => @loadEnvelopeString reader.result, dropPoint
    reader.onerror = -> world.inform "Could not read that file."
    reader.readAsText file
    return

  # Sniff a string as a Fizzygum envelope and route by its `kind`. `dropPoint` (optional) is
  # where a restored widget should be placed.
  @loadEnvelopeString: (string, dropPoint) ->
    envelope = undefined
    try
      envelope = JSON.parse string
    catch e
      envelope = undefined
    unless envelope? and envelope.format is Serializer.FORMAT
      world.inform "This is not a Fizzygum file\n(expected a *.fzw.json file)."
      return
    switch envelope.kind
      when "widget"
        result = @_reportingSerializationErrors -> Deserializer.deserialize envelope
        return unless result?
        widget = result.widget
        world.add widget
        widget._applyMoveTo dropPoint if dropPoint?
        # RE-RECORD (the F6 family, auto-bookkeeping arc): the loaded widget carries the
        # fractional bookkeeping serialized in its previous life, which the fill-only seed
        # respects -- re-derive at the landing position explicitly.
        widget._rememberFractionalSituationInHoldingPanel?()
        result.whenReady?.then? ->
          # door-callback law (PartsRegistry's header): the decode is exactly when the freshly
          # landed widget can be closed and destroyed, and the tail must not invalidate a corpse
          return if widget.destroyed
          # cross-invalidation-sanctioned: load orchestration — a deferred repaint once async
          # image/canvas assets have decoded; the deserializer restores fields directly, so
          # there is no receiver-side method seam for this
          widget._fullChanged?()
      when "world"
        if world.loadWorldSnapshot?
          # A file this build can never restore is refused by the loader itself, desktop untouched,
          # so a SerializationError reported here is one that failed part-way through the restore.
          # ⚠ Only the SYNCHRONOUS load is covered: a file that needs a lazy part or the reflective
          # layer makes the loader return a promise and re-enter once that arrives, and a failure
          # there rejects a promise nothing here observes.
          @_reportingSerializationErrors -> world.loadWorldSnapshot envelope
        else
          world.inform "This build cannot load whole-world snapshots yet."
      else
        world.inform "Unknown Fizzygum file kind: " + envelope.kind
    return

  # Run one restore and answer what it answers — or, when it throws a SerializationError, show that
  # to the user as one message and answer undefined, so a bad file never surfaces as an uncaught
  # error in the file reader's callback. Any other error is a bug, and propagates. Both kinds of
  # file come through here, so the two cannot report a failed load differently.
  @_reportingSerializationErrors: (restore) ->
    try
      restore()
    catch error
      throw error unless error instanceof SerializationError
      world.inform error.toString()
      undefined
