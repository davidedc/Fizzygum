# A sub-axis of FIT_BOX_TO_TEXT (see FittingSpecText): how much padding the box
# leaves around the text when it hugs it.
#  - TIGHT: no extra padding — the box is exactly the text extent. This is the
#    default and the only configuration the current content widgets use
#    (SimplePlainTextWdgt and bare contained TextWdgt are TIGHT).
#  - LOOSE: leave a padding margin around the text. Wired + keyed into the cache
#    key per the original design, but not yet exercised by any caller.
#
# SHIPS in the homepage build (referenced by FIT_BOX_TO_TEXT content layout) —
# do NOT re-add a homepage-exclusion header.

class FittingSpecTextBoxFittingTextTightOrLoose
  @TIGHT: false
  @LOOSE: true
