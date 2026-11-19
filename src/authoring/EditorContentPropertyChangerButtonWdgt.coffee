# Base for the editor's "content property changer" buttons — the little icon
# buttons of the text and sheet toolbars (bold, italic, the alignment trio,
# font, font-size, format-as-code, the sheet's fill, decimals and slider tools,
# templates) that act on the LAST widget the user clicked or dropped
# (world.editorFocusWdgt) — or on the style it hands over (_styleSubject: a
# spreadsheet hands over its selected cell's). Which focus is mine to act on
# follows who my toolbar works for (ToolbarWdgt.hostWindowOf): a toolbar docked
# on a window works for that window, so I act on the focus only while it is in
# that window's reach; a floating toolbar works for the person, so I act on the
# focus wherever it is. Content in view mode hands over nothing
# (WorldWdgt.editableEditorFocus).
#
# THE FAMILY CONTRACT: a SUBJECT, a VERB, ONE REFUSAL.
#   - My VERB is the one method or field my act needs a subject to offer, which
#     a subclass names once, as data (verb: bold "toggleWeight"; a font size
#     "originallySetFontSize", the size it steps from).
#   - My SUBJECT is what I would act on now (_subjectOfferingMyVerb): the style
#     the focus hands over, when it offers my verb. A tool with a second kind of
#     subject resolves it there too (AlignButtonWdgt).
#   - A PRESS on me (activated) acts on that subject (actOn: by default my verb,
#     called on it), and with no subject it is REFUSED, here and nowhere else: a
#     tap on the cell I stand in and a toolbar overflow row standing for me
#     (OverflowChevronButtonWdgt.triggerToolFromMenu) both reach this activated.
#   - Whether I HAVE SOMETHING TO ACT ON (hasSomethingToActOn) is that same
#     answer, asked without pressing. The cell I stand in reads it for its look
#     (GlassBoxBottomWdgt.holdsToolWithNothingToActOn), so in a toolbar I show
#     dimmed exactly while a press on me would be refused. The refusal does not
#     wait for a cell to show it: standing in none (every real home of mine is a
#     toolbar), I refuse a press with nothing to act on all the same -- the font
#     tool opens no menu.
#   A subject-less tool (TemplatesButtonWdgt) keeps its own activated and always
#   has something to act on.
#
# MY LOOK: my hover, my press and whether I am the active tool show on the tool
# cell I stand in, never on me (the cell asks the hand about me as it paints,
# GlassBoxBottomWdgt, and I tell the cell when the hand's answers move). My
# glyph's INK is read as I paint (_fillForMyState, which my icon appearance asks:
# IconAppearance._iconColorString): the toolbar glyph ink, dimmed while the cell I
# stand in holds me with nothing to act on. A subclass supplies its icon
# (createAppearance, given no colour of its own, so that ink reaches it), its
# tooltip (toolTipMessage), its verb, and its act where that is more than
# calling its verb -- and, when it toggles a state of the text it acts on (bold,
# italic, the mono font, an alignment), whether it is the ACTIVE tool:
# isActiveTool, true while that text has the state, so its cell MIRRORS the
# edited text. The cell re-derives both answers whenever the
# world announces the focus, its style or the mode of the content holding it
# moved, and whenever my toolbar docks or leaves (ToolbarWdgt.noteToolStatesChanged).
# A tool with no state (the font, font-size and templates buttons) answers
# nothing about being active and is never active.
#
# All of them are icon-shaped, hence the IconWdgt base: they paint through icon
# appearances, like every other glyph-faced tool. Bold, italic and format-as-code
# TYPE their face (a "B", an "I", a "</>") from the glyph atlases in a theme font
# role (TypedFaceIconAppearance); the others draw theirs.

class EditorContentPropertyChangerButtonWdgt extends IconWdgt

  actionableAsThumbnail: true

  # MY VERB: the name of the one method -- or field -- a subject must offer for me to act on it: the
  # method my press calls on it (the default act, actOn), or what my own act reads. Named once, here,
  # by each subclass. (subclass responsibility)
  verb: undefined

  # MY HOVER AND PRESS show on the tool cell I stand in, never on me (GlassBoxBottomWdgt.fillForToolState
  # asks this of the widget whose state a cell shows).
  lightsAToolCell: ->
    true

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my glyph's
  # ink does not follow the pointer (_fillForMyState), so I tell the cell I stand in, which repaints over
  # me. A parent that is no cell answers nothing.
  notePointerStateChanged: ->
    @parent?.noteItemStateChanged?()

  # MY INK, read by my icon appearance as it paints me (IconAppearance._iconColorString): the toolbar
  # glyph ink, or its dimmed twin while the cell I stand in holds me with nothing to act on
  # (GlassBoxBottomWdgt.holdsToolWithNothingToActOn). The cell answers for its own fill and for my ink
  # alike, so the two never disagree. Standing in no cell -- the detached copy a toolbar overflow row
  # takes its picture of (OverflowChevronButtonWdgt._miniatureOf) -- I wear the plain ink, which the
  # row greys while it is disabled.
  _fillForMyState: ->
    if @parent?.holdsToolWithNothingToActOn?()
      WorldWdgt.theme.toolbarGlyphDimmed
    else
      WorldWdgt.theme.toolbarGlyph

  # Editor CHROME (Frame-model plan §5.D D2a): pressing me acts ON the editor
  # focus, so the press must neither steal the focus pointer nor end the
  # ongoing edit (the caret reads the selection my action needs). Honored BY
  # ANCESTRY at ActivePointerWdgt's focus-set sites and its caret-survival
  # policy — one capability for both, declared here for buttons standing
  # outside a toolbar (inside one, the toolbar's own declaration covers them).
  excludedFromEditorFocusTracking: ->
    true

  # WHAT I AM HANDED: the style the editor focus hands over (WorldWdgt.editorStyleSubject — a
  # spreadsheet's selected cell's style, SheetCellStyle, or a text itself), within the window I work
  # for (ToolbarWdgt.hostWindowOf): while my toolbar is docked on a window, only a focus in that
  # window's reach hands me anything, and a focus anywhere else hands me nothing; while it floats (or
  # I stand in no toolbar) I work for the person, and the focus anywhere does. Every tool of the
  # family reads and writes through this, so a tool works the same on a text and on a sheet's
  # selected cell, and the focus decides what that is. A focus sitting in content in view mode hands
  # over nothing (WorldWdgt.editableEditorFocus), whatever toolbar I stand in, docked or floating: a
  # tool acting through this has nothing to act on there.
  _styleSubject: ->
    world.editorStyleSubject ToolbarWdgt.hostWindowOf @

  # MY SUBJECT NOW: what I am handed (_styleSubject) when it offers my verb, else undefined. Read by a
  # press on me (activated), by whether I have something to act on (hasSomethingToActOn) and by a
  # subclass's isActiveTool. A subclass with a second kind of subject answers it here too
  # (AlignButtonWdgt).
  _subjectOfferingMyVerb: ->
    subject = @_styleSubject()
    if @_offersMyVerb subject then subject else undefined

  # Does `subject` (undefined when I am handed nothing) offer MY VERB?
  _offersMyVerb: (subject) ->
    subject?[@verb]?

  # HAVE I SOMETHING TO ACT ON now -- a subject that offers my verb? A capability query, read by the
  # cell I stand in for its look and for my ink (GlassBoxBottomWdgt.holdsToolWithNothingToActOn), and
  # by the rows of a menu of mine for their enablement (the font tool's Fonts menu). It answers what a
  # press on me would do: act (true), or be refused (false). Destroyed, I have nothing: a menu of mine
  # left open past my window's end greys and refuses, rather than act for whoever holds the focus.
  hasSomethingToActOn: ->
    not @destroyed and @_subjectOfferingMyVerb()?

  # A PRESS ON ME -- a tap on the cell I stand in, or a toolbar overflow row standing for me
  # (OverflowChevronButtonWdgt.triggerToolFromMenu) -- and THE ONE REFUSAL of the family: I act on my
  # subject, and with none I do nothing, whatever delivered the press.
  activated: ->
    subject = @_subjectOfferingMyVerb()
    @actOn subject if subject?
    return

  # MY ACT on `subject`, which offers my verb (activated found it): by default, my verb called on it; a
  # subclass whose act is more than that names its own. Reached only through activated, and public
  # all the same: an act calls the subject's self-settling setters (toggleWeight, setFontSize, ...),
  # which the _-prefixed low-level tier may not (check-layering [A]).
  actOn: (subject) ->
    subject[@verb]()
    return

  constructor: (@color) ->
    super @color
    @appearance = @createAppearance()
