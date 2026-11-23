# Shared behaviour of the three alignment buttons (left / center / right). I
# have TWO kinds of subject, tried in this order: the style the focus hands over,
# when it aligns itself directly (my verb, the direct method: a text, a sheet's
# selected cell), else the layout spec of the focus's grab root, when that root
# is an active vertical-stack element (a widget dropped into a document), on
# which I set my alignment. Each subject is acted on by its own method, and I
# have something to act on exactly while one of the two is there
# (_subjectOfferingMyVerb). Subclasses supply the two method names (verb,
# layoutAlignSetterMethod) and the alignment they set (and the icon + tooltip
# via the base). A button shows active while the style it aligns directly has
# its alignment (the family's mirror of the edited text); the layout-spec
# subject is not mirrored. Both
# subjects come from the world's editable focus within the window the button
# works for (WorldWdgt.editableEditorFocus, asked with ToolbarWdgt.hostWindowOf):
# content in view mode hands over neither, and neither does a widget outside
# the window the button's toolbar is docked on -- the button has nothing to act
# on there. A floating toolbar works for the person, so its buttons align the
# focus wherever it is.

class AlignButtonWdgt extends EditorContentPropertyChangerButtonWdgt

  # verb (the family's): my DIRECT method, which a style that aligns itself offers, e.g. "alignLeft"
  layoutAlignSetterMethod: undefined  # e.g. "setAlignmentToLeft": what a stack element's layout spec takes
  horizontalAlignmentName: undefined  # e.g. "LEFT": the AlignmentSpecHorizontal my direct method sets

  # ACTIVE while the style I would align directly already has my alignment
  isActiveTool: ->
    subject = @_styleSubject()
    @_offersMyVerb(subject) and subject.horizontalAlignment is AlignmentSpecHorizontal[@horizontalAlignmentName]

  # MY SUBJECT: the style I am handed, when it aligns itself directly (the family's answer), else the
  # layout spec my alignment is set on (_activeStackSpecOfMyFocus)
  _subjectOfferingMyVerb: ->
    super() ? @_activeStackSpecOfMyFocus()

  # The layout spec of the editable focus's grab root, when that root is an active vertical-stack
  # element, else undefined: the same focus my handed style comes from, within the window I work for.
  _activeStackSpecOfMyFocus: ->
    spec = world.editableEditorFocus(ToolbarWdgt.hostWindowOf @)?.findRootForGrab()?.layoutSpec
    if spec?.isStackElementActive?() then spec else undefined

  # each subject by its own verb: a style aligns itself (my verb), a stack element's layout spec takes
  # my alignment (layoutAlignSetterMethod)
  _actOn: (subject) ->
    if @_offersMyVerb subject
      subject[@verb]()
    else
      subject[@layoutAlignSetterMethod]()
    return
