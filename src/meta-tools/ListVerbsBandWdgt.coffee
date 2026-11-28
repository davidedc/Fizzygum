# A LIST'S VERBS: the band of drawn icon buttons a list view of an inspector ends in, one per VERB its
# view OFFERS, always in the ONE order add, duplicate, rename, remove -- a verb the view does not offer
# leaves no gap, and a view that offers none builds no band. Each is the house's button
# (SimpleButtonWdgt: "a bordered rounded rectangle means press me"), 44 x 36 -- across, a chrome
# target's least, the 44 rule every button meets; down, the house's one button height, my 52 meeting
# the 44 rule (visual-design-system §4.2) -- whose face is a drawn MARK (MenuRowIndicatorWdgt, inked
# in the button's own text roles, enabled and disabled alike) and whose TOOLTIP is my view's words
# for the verb, since a mark alone does not say it. With all four verbs my least width is
# footerInset + 4 x 44 + 3 x footerGap + footerInset = 224, my spring's least being 0, and my desired
# width 225, my spring's desired 1. A press runs my view's method for the verb, at my view, the verb
# its argument (the button's arg1: a name, never a closure), so a copy of a view is reached by its own
# band. A verb that does not apply NOW stands disabled, in the button's own disabled look: it still
# catches a press, and does nothing with it.
#   THE PROTOCOL I ask of my view, by these fixed names:
#     verbsOffered()     a TABLE keyed by verb, an entry for each verb the view can ever offer, each
#                        {action, words}: the NAME of the view's method that performs the verb, and the
#                        words that say it ("Add…", "Remove": "…" where a prompt follows, §4.9). Read
#                        once, as I am built: which verbs a view can ever offer is its subject's to say
#                        -- and, for a list of a widget's children, the developer mode's, so that view
#                        builds me or takes me away as the mode switches (ObjectListWdgt).
#     verbApplies(verb)  whether the verb applies now, asked at every reflectVerbs, which my view asks
#                        of me at the seats it knows of where what its verbs act on changes (its
#                        verbApplies names them, and what they do not see).
#   And I answer my verbs (verbs, in the order my buttons stand) and my button for a verb (buttonFor)
# to whoever reads them: a reader outside me asks these, and none reads my pieces.
#   A CLASS, not a builder: reflecting my view's answers onto my buttons is mine, so every list view
# that ends in verbs reads them through one band. In every other respect I am a band (BandWdgt), at the
# footer band's metrics: footerBandHeight tall, footerInset in, footerGap between two buttons, a spring,
# footerInset again, my rule along my TOP (the line between me and the list above me), my buttons
# centred down me. I keep no field of my own: my view is my buttons' target, my verbs their arguments.
#   THE MARKS (_verbsInOrder) are PLACEHOLDERS, the owner's final icons still to come: the plus
# (PlusIconAppearance) for add, two overlapping sheets for duplicate, a text cursor in a field for
# rename, a bin outline for remove, each in a square of inspectorVerbMarkSize.
class ListVerbsBandWdgt extends BandWdgt

  #: initialization

  # My view is my identity, my one positional parameter: my buttons are built from what it offers,
  # before my base builds me from them (the items a band is handed). The verbs' enabled states are my
  # view's to have me reflect, once it can answer them (reflectVerbs).
  constructor: (view) ->
    theme = WorldWdgt.theme
    offered = view.verbsOffered()
    items = [theme.footerInset]
    for {verb, mark} in ListVerbsBandWdgt._verbsInOrder() when offered[verb]?
      items.push theme.footerGap  if items.length > 1
      items.push ListVerbsBandWdgt._buttonOf view, verb, mark, offered[verb]
    items.push BandWdgt.SPRING, theme.footerInset
    super theme.footerBandHeight, items, rule: "top"

  # THE VERBS IN MY ONE ORDER, each with the mark its button wears: a table, the verbs and their marks
  # read together. A method, not a class-level table: a class constant may not name another class.
  @_verbsInOrder: ->
    [
      {verb: "add", mark: PlusIconAppearance}
      {verb: "duplicate", mark: TwoSheetsIconAppearance}
      {verb: "rename", mark: TextCursorIconAppearance}
      {verb: "remove", mark: BinOutlineIconAppearance}
    ]

  # THE BUTTON OF `verb`: `view` its target, the view's method for the verb (the entry's action) its
  # action, the verb its argument, `mark` drawn as its face in a square of inspectorVerbMarkSize, inked
  # by the button (it hands its face no colour of its own), the view's words for the verb (the entry's
  # words) its tooltip
  @_buttonOf: (view, verb, mark, entry) ->
    face = new MenuRowIndicatorWdgt mark, glyphSize: WorldWdgt.theme.inspectorVerbMarkSize
    new SimpleButtonWdgt target: view, action: entry.action, arg1: verb, face: face, toolTip: entry.words

  #: verbs

  # EACH OF MY BUTTONS ENABLED exactly while its verb applies now, as its target, my view, answers
  # (verbApplies: a connection by method name on a target). My view asks this at the seats where it
  # knows what its verbs act on changes (its verbApplies names them: MemberListWdgt's, ObjectListWdgt's).
  # A button a person took out of me is not mine to reflect. Paint only: a button's enabled flag
  # changes nothing's size.
  reflectVerbs: ->
    for each in @children when each.argumentToAction1?
      each.setEnabled each.target.verbApplies each.argumentToAction1
    return

  # MY VERBS, in the order my buttons stand in me, left to right -- a band's pieces stand in the order
  # they are its children (a horizontal division row) -- each button's verb (its argument); a button a
  # person took out of me is not mine. Read off my pieces, never off their geometry, so a band not yet
  # laid out answers the same. What a reader outside me reads my verbs by (the macro toolkit's
  # listVerbsOf), so none of them reads my pieces.
  verbs: ->
    (each.argumentToAction1 for each in @children when each.argumentToAction1?)

  # MY BUTTON FOR `verb`: the button of mine whose argument is the verb, or undefined when I hold none
  # -- a verb my view does not offer, or a button a person took out of me, which is not mine. What a
  # reader outside me finds a verb's button by (the macro toolkit's locator, the menu sweep), so none
  # of them reads my pieces' order or their marks.
  buttonFor: (verb) ->
    @children.find (each) -> each.argumentToAction1? and each.argumentToAction1 is verb
