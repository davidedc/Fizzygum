# EMPTY. A pop-up is a FRAME with a transient lifetime (FrameWdgt.lifetime), so everything
# that was a pop-up's — the registries, the click-outside dismissal, the pinning, the shadow
# policy, the placement verbs — lives on FrameWdgt, and the menu and prompt kinds are framed
# citizens of it (MenuWdgt / PromptWdgt). Nothing derives from this class and nothing
# instantiates it.

class PopUpWdgt extends Widget
