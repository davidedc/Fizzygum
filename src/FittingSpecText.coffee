# The top-level text FITTING MODE (the first axis of the FITTING MODEL — see the
# big comment in StringWdgt.coffee):
#  - FIT_TEXT_TO_BOX: the box extent is FIXED (set by the layout / the user) and
#    the TEXT is fitted INTO it (scaled up/down or cropped, per
#    fittingSpecWhenBoundsTooLarge / fittingSpecWhenBoundsTooSmall). This is the
#    default for every free-floating widget — the widget never resizes itself.
#  - FIT_BOX_TO_TEXT: the inverse — the widget resizes its OWN extent to hug its
#    text. For contained multi-line text the width comes from the container and
#    the height follows the wrapped content (height-adjusts-to-width); this is
#    what makes a SimplePlainTextWdgt — and now ANY TextWdgt used as
#    window / panel / scroll content — re-wrap and auto-grow/shrink its height.
#    Wired into StringWdgt/TextWdgt reflowText + _reLayoutSelf + createBufferCacheKey.
#
# This class SHIPS in the homepage build (production content layout references it
# via FIT_BOX_TO_TEXT) — do NOT re-add a "# this file is excluded from the
# fizzygum homepage build" header, or --homepage will strip it and the base will
# reference an undefined class at boot.

class FittingSpecText
  @FIT_TEXT_TO_BOX: true
  @FIT_BOX_TO_TEXT: false
