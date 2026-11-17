# Base for the editor's "content property changer" buttons — the little icon
# buttons in the text-editing toolbar (bold, italic, the alignment trio, font,
# font-size, format-as-code, templates) that act on the LAST widget the user
# clicked or dropped (world.editorFocusWdgt) — or on the style it hands over
# (_styleSubject: a spreadsheet hands over its selected cell's). Which focus is
# mine to act on follows who my toolbar works for (ToolbarWdgt.hostWindowOf): a
# toolbar docked on a window works for that window, so I act on the focus only
# while it is in that window's reach; a floating toolbar works for the person,
# so I act on the focus wherever it is. Content in view mode hands over nothing
# (WorldWdgt.editableEditorFocus), so there every tool that acts on it does
# nothing and shows inactive.
#
# They share: a hover/press look shown on the tool cell each stands in rather
# than on the button (the cell asks the hand about the button as it paints,
# GlassBoxBottomWdgt, and the button tells the cell when the hand's answers
# move), the thumbnail-actionability flag and the editor-chrome exclusion
# below. A subclass supplies only its icon (createAppearance, in the
# toolbarGlyph ink), its tooltip
# (toolTipMessage), and its activated -- and, when it toggles a state of the text
# it acts on (bold, italic, the mono font, an alignment), whether it is the ACTIVE
# tool: isActiveTool, true while that text has the state, so its cell MIRRORS the
# edited text (re-derived whenever the world announces the focus, its style or
# the mode of the content holding it moved, and whenever my toolbar docks or
# leaves: ToolbarWdgt.noteToolStatesChanged). A tool with no state (the font,
# font-size and templates buttons) answers nothing and is never active.
#
# All of them are icon-shaped, hence the IconWdgt base: they paint through icon
# appearances, like every other glyph-faced tool. Bold, italic and format-as-code
# TYPE their face (a "B", an "I", a "</>") from the glyph atlases in a theme font
# role (TypedFaceIconAppearance); the others draw theirs.

class EditorContentPropertyChangerButtonWdgt extends IconWdgt

  actionableAsThumbnail: true

  # MY HOVER AND PRESS show on the tool cell I stand in, never on me (GlassBoxBottomWdgt.fillForToolState
  # asks this of the widget whose state a cell shows).
  lightsAToolCell: ->
    true

  # The hand's answers about me may have moved (ActivePointerWdgt._tellPointerStateChanged): my glyph
  # keeps its one ink, so I tell the cell I stand in, which repaints over me. A parent that is no cell
  # answers nothing.
  notePointerStateChanged: ->
    @parent?.noteItemStateChanged?()

  # Editor CHROME (Frame-model plan §5.D D2a): pressing me acts ON the editor
  # focus, so the press must neither steal the focus pointer nor end the
  # ongoing edit (the caret reads the selection my action needs). Honored BY
  # ANCESTRY at ActivePointerWdgt's focus-set sites and its caret-survival
  # policy — one capability for both, declared here for buttons standing
  # outside a toolbar (inside one, the toolbar's own declaration covers them).
  excludedFromEditorFocusTracking: ->
    true

  # WHAT I ACT ON: the style the editor focus hands over (WorldWdgt.editorStyleSubject — a
  # spreadsheet's selected cell's style, SheetCellStyle, or a text itself), within the window I work
  # for (ToolbarWdgt.hostWindowOf): while my toolbar is docked on a window, only a focus in that
  # window's reach hands me anything, and a focus anywhere else hands me nothing; while it floats (or
  # I stand in no toolbar) I work for the person, and the focus anywhere does. Every tool of the
  # family reads and writes through this, so a tool works the same on a text and on a sheet's
  # selected cell, and the focus decides what that is. A focus sitting in content in view mode hands
  # over nothing (WorldWdgt.editableEditorFocus), whatever toolbar I stand in, docked or floating: a
  # tool acting through this does nothing when pressed there and shows inactive.
  _styleSubject: ->
    world.editorStyleSubject ToolbarWdgt.hostWindowOf @

  constructor: (@color) ->
    super @color
    @appearance = @createAppearance()
