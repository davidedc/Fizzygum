# FileSaving — save a Fizzygum serialization string to a downloaded file, over the
# `file://` protocol (the normal way Fizzygum runs). See
# docs/serialization-duplication-reference.md §10.
#
# This is a PRODUCT feature and ships in ALL builds (including --homepage) — it carries no
# homepage-strip markers and does NOT depend on the dev-only vendored FileSaver/JSZip (which
# --homepage strips). ~one method: Blob -> object URL -> synthetic <a download> click ->
# revoke. Spike-proven byte-exact over file:// in headless Chrome (plan Appendix A).
class FileSaving

  # Save `string` as a file the browser downloads under `suggestedName`.
  @saveStringAsFile: (string, suggestedName, mimeType = "application/json") ->
    blob = new Blob [string], {type: mimeType}
    if @isSafari()
      # Safari has historically ignored the <a download> attribute for blob: URLs, so
      # navigate a data: URL instead (mirrors the test harness's Automator.coffee fallback).
      reader = new FileReader
      reader.onload = -> window.location.href = reader.result
      reader.readAsDataURL blob
      return
    url = URL.createObjectURL blob
    anchor = document.createElement "a"
    anchor.href = url
    anchor.download = suggestedName
    document.body.appendChild anchor
    anchor.click()
    document.body.removeChild anchor
    # revoke on a later tick so the download has a chance to start (pure cleanup, nothing
    # rendered depends on it — safe as a wall-clock timer per DETERMINISM.md)
    setTimeout (-> URL.revokeObjectURL url), 1000
    return

  @isSafari: ->
    (typeof navigator isnt "undefined") and /^((?!chrome|android).)*safari/i.test navigator.userAgent
