# FileLoading — ingest a Fizzygum file (drag-dropped onto the desktop, or chosen through a
# file dialog) and route it by the envelope's `kind` field, NEVER by the filename. See
# docs/serialization-duplication-reference.md §10. A PRODUCT feature — ships in all builds.
#
# The single file extension is `*.fzw.json` (plain JSON inside); a `kind:"widget"` file
# restores a detached widget attached at the drop point, a `kind:"world"` file loads a whole
# world snapshot (Phase 5). Non-Fizzygum files are rejected with a friendly inform.
class FileLoading

  # A hidden <input type=file>, created on demand and clicked from a "open from file…" menu
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
    envelope = nil
    try
      envelope = JSON.parse string
    catch e
      envelope = nil
    unless envelope? and envelope.format is Serializer.FORMAT
      world.inform "This is not a Fizzygum file\n(expected a *.fzw.json file)."
      return
    switch envelope.kind
      when "widget"
        try
          result = Deserializer.deserialize envelope
        catch error
          if error instanceof SerializationError
            world.inform error.toString()
            return
          else
            throw error
        widget = result.widget
        world.add widget
        widget._applyMoveTo dropPoint if dropPoint?
        widget.rememberFractionalSituationInHoldingPanel?()
        # a repaint once any async image/canvas assets have decoded
        result.whenReady?.then? -> widget.fullChanged?()
      when "world"
        if world.loadWorldSnapshot?
          world.loadWorldSnapshot envelope
        else
          world.inform "This build cannot load whole-world snapshots yet."
      else
        world.inform "Unknown Fizzygum file kind: " + envelope.kind
    return
