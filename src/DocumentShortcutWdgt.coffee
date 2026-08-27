# This is a reference to any type of document, be it a script, or an image
# or a slide or a note etc. etc.

class DocumentShortcutWdgt extends ShortcutWdgt

  # (icon assembly -- bare object composite vs the arrow'd wrap -- lives in ShortcutWdgt's
  # constructor, driven by the per-instance arrow-contract declaration; my inner art is the
  # base's default, the object composite around the referent's representative icon)

  _reactToChildDropped: (droppedWidget) ->

  activated: (arg1, arg2, arg3, arg4, arg5, arg6, arg7, doubleClickInvocation, arg9) ->
    if doubleClickInvocation
      return

    @bringUpReferencedWidget()


