# A sub-axis of FIT_BOX_TO_TEXT (see FittingSpecText): when the box hugs the
# text, which dimension is the FREE one that follows the content.
#  - HEIGHT_ADJUSTS_TO_WIDTH: the WIDTH is given (by the container) and the text
#    wraps to it; the HEIGHT then follows the wrapped line count. This is the
#    default and the configuration used by all contained multi-line text
#    (SimplePlainTextWdgt and bare contained TextWdgt).
#  - WIDTH_ADJUSTS_TO_HEIGHT: the converse (height given, width follows). Wired +
#    keyed per the original design; for multi-line text it is not exercised — the
#    single-line "box hugs text in both dimensions" case is handled by
#    StringWdgt#sizeToTextAndDisableFitting (the chrome-label path).
#
# SHIPS in the homepage build (referenced by FIT_BOX_TO_TEXT content layout) —
# do NOT re-add a homepage-exclusion header.

class FittingSpecTextBoxFittingTextWhichDimensionAdjusts
  @HEIGHT_ADJUSTS_TO_WIDTH: true
  @WIDTH_ADJUSTS_TO_HEIGHT: false
