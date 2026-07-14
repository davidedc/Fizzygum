# before monkey-patching, consider whether you could/should
# just create a class that extends this one, and has the extra
# functionality that you want

# canvas gradients might be tied to a specific context
# (unclear to me at the moment), so to keep things
# simple we just return NIL and we ask to the user of the
# gradients to check whether the gradient is nil
# and to re-create it from scratch if the case.
# Do a search for "gradient" to see how this pattern
# works (it's simpler than it sounds)
# TODO maybe there is a way to make a clean copy?
#      maybe the gradient is not tied to a particular canvas?
#      maybe even if it's tied to a canvas you can get to the
#            copy canvas and create the copy gradient from that?

CanvasGradient::deepCopy = (objOriginalsClonedAlready, objectClones, allWidgetsInStructure) ->
  # canvas gradients are returned as nil (see the file header) — the copier only
  # needs the identity mapping registered so it can walk past them.
  deepCopyWithIdentity @, objOriginalsClonedAlready, objectClones, => nil
