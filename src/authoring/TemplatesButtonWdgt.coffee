# Opens / re-focuses the editor's "useful snippets" templates window -- the one window of
# TemplatesApp, which keeps it in world.appWindows (see there). I am the family's SUBJECT-LESS
# tool: the window is what I open, whatever the editor focus is, so I keep my own activated (no
# subject, no verb, no refusal) and always have something to act on.
# See EditorContentPropertyChangerButtonWdgt for the shared family contract.

class TemplatesButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  toolTipMessage: "useful snippets"

  createAppearance: -> new TemplatesIconAppearance @

  # opening the snippets window needs no subject, so a press on me always acts and I never show dimmed
  hasSomethingToActOn: ->
    true

  activated: ->
    (new TemplatesApp).launch()
