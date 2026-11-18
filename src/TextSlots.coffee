# WHERE A CARET MAY STAND IN A TEXT, AND HOW IT STEPS: the ONE definition every reader of a slot asks -- the
# caret's moves and deletes, a text's hit test, its selection paint, crop and password mask, a double-click's
# word, a spreadsheet's typed key, the macro toolkit's typing and aiming.
#   A SLOT is an offset into the text in UTF-16 code units -- what length, slice and substring count, so a slot is
# stored and sliced as any offset is -- but only an offset BETWEEN two characters as a person sees them: a
# grapheme cluster (Intl.Segmenter, granularity "grapheme"). So the smiley 😀 (two units, a surrogate pair), the
# frowning ☹️ (two code points, ☹ and its emoji selector) and a decomposed é (e and its accent) are each ONE
# character with no slot inside: a caret steps over each in one press, a Backspace deletes each whole, a click
# lands either side of it. Code points are not enough: ☹️ would still split, and it is one of the SWCanvas fonts'
# own emoji (BitmapText draws 😊 😀 😃 as ☺ and 😢 ☹️ as ☹, one glyph each; the native canvas draws the
# platform's emoji, one glyph too).
#   Grapheme segmentation, walked from the text's start, answers the same in the two engines the suite runs (Chrome
# and WebKit, measured on ASCII, surrogate pairs, emoji selectors, ZWJ sequences, flags, skin tones, combining marks,
# CRLF and Hangul). Two things the platform offers do NOT, so neither is used: the segments' own `containing(offset)`
# (WebKit's answers the character BEFORE a surrogate pair for the offset just before the pair: in "ab😀", the "b",
# three units long), so the character at an offset is found by walking (_characterAt); and WORD segmentation
# (WebKit's keeps "foo.bar" one word, Chrome's makes it two), so a word is defined here, over these characters.
#   Class-side members only, as Utils has: there is no instance of me.

class TextSlots

  # one segmenter for the page, made at its first use: a class-level construction would read, to the boot's
  # dependency scanner, as a class this one needs
  @_graphemeSegmenter: undefined

  @_graphemes: (text) ->
    TextSlots._graphemeSegmenter ?= new Intl.Segmenter undefined, granularity: "grapheme"
    TextSlots._graphemeSegmenter.segment text

  # every character of the text, in order, as [its slot before, its slot after]
  @spansOf: (text) ->
    ([each.index, each.index + each.segment.length] for each from TextSlots._graphemes text)

  # every slot of the text, in order: 0, then the end of each character, so the text's length last
  @slotsOf: (text) ->
    [0].concat (after for [before, after] in TextSlots.spansOf text)

  # every character of the text, in order, each as the string it is
  @characters: (text) ->
    (each.segment for each from TextSlots._graphemes text)

  # how many characters the text holds: a password's asterisks, how much of a crop survives
  @count: (text) ->
    (TextSlots.spansOf text).length

  # is the text exactly one character: a key that types (a key NAME -- "PageDown", "Dead", "F3" -- is several)
  @isOneCharacter: (text) ->
    (TextSlots.count text) is 1

  # THE SLOT AT AN OFFSET that may not be one: the offset itself where it is a slot, else the start of the
  # character it falls in (an offset past either end answers that end). Asked by whatever computes an offset by
  # arithmetic on a text it did not segment: a text's shown end where a crop's ellipsis stands for characters
  # longer than itself, a wrapped line's end where its break is one character with what precedes it (a "\r\n").
  @slotAtOrBefore: (text, offset) ->
    return 0 unless offset > 0
    return text.length if offset >= text.length
    (TextSlots._characterAt text, offset).index

  # the character holding the code unit at `offset` (0 <= offset < the text's length), as its segment: walked from
  # the text's start up to the offset (see the header: WebKit's `containing` answers wrongly before a surrogate pair)
  @_characterAt: (text, offset) ->
    for each from TextSlots._graphemes text
      return each if each.index + each.segment.length > offset
    undefined

  # the offset itself where it is a slot, else the END of the character it falls in: where a caret stands after
  # text it typed, which can join the character that follows it into one (two flag halves, a joiner and an emoji)
  @slotAtOrAfter: (text, offset) ->
    return 0 if offset <= 0
    TextSlots.slotAfter text, offset - 1

  # may a caret stand at `slot` in the text: its start, its end, or between two of its characters
  @isSlot: (text, slot) ->
    (TextSlots.slotAtOrBefore text, slot) is slot

  # the slot one character after `slot`; the text's end stays where it is
  @slotAfter: (text, slot) ->
    return text.length if slot >= text.length
    character = TextSlots._characterAt text, slot
    character.index + character.segment.length

  # the slot one character before `slot`; the text's start stays where it is, and an offset inside a character
  # answers that character's start
  @slotBefore: (text, slot) ->
    return 0 if slot <= 0
    TextSlots.slotAtOrBefore text, slot - 1

  # A WORD is a run of word characters, and a WORD CHARACTER is one that begins with a letter or a digit
  # (Unicode's \p{L} and \p{N}) or with an underscore: "café", "x2y", "Ελλάδα" and an identifier such as
  # "my_count" are words; spaces, punctuation, symbols and emoji are not.
  @isWordCharacter: (character) ->
    /^[\p{L}\p{N}_]/u.test character

  # A WORD WALK: the text's characters walked once, as `slots` (slotsOf: character i stands between slots[i] and
  # slots[i + 1]) and `words` (whether character i is a word character). Every word answer below steps an index
  # through it from `at`, the index of the slot it starts at (an offset that is no slot of the text -- one past
  # its end, after a script shortened it -- starts at the slot at or before it, as the arrows clamp).
  @_wordWalk: (text, slot) ->
    slots = TextSlots.slotsOf text
    words = (TextSlots.isWordCharacter text.slice slots[i], slots[i + 1] for i in [0...slots.length - 1])
    {slots, words, at: slots.indexOf TextSlots.slotAtOrBefore text, slot}

  # the word a slot stands in or touches, as [its start, its end] (a double-click's selection); [slot, slot]
  # where no word character touches it
  @wordAround: (text, slot) ->
    {slots, words, at} = TextSlots._wordWalk text, slot
    start = end = at
    start-- while start > 0 and words[start - 1]
    end++ while end < words.length and words[end]
    [slots[start], slots[end]]

  # where a word jump to the LEFT lands, in both keyboard families: back over what is not a word, then over the
  # word, to its start
  @wordStartBefore: (text, slot) ->
    {slots, words, at} = TextSlots._wordWalk text, slot
    i = at
    i-- while i > 0 and !words[i - 1]
    i-- while i > 0 and words[i - 1]
    slots[i]

  # where a Mac's word jump to the RIGHT lands (Option+Right): on over what is not a word, then over the word, to
  # its END
  @wordEndAfter: (text, slot) ->
    {slots, words, at} = TextSlots._wordWalk text, slot
    i = at
    i++ while i < words.length and !words[i]
    i++ while i < words.length and words[i]
    slots[i]

  # where a PC's word jump to the RIGHT lands (Ctrl+Right): on over the rest of the word, then over what is not a
  # word, to the START of the next word (the text's end where none follows)
  @wordStartAfter: (text, slot) ->
    {slots, words, at} = TextSlots._wordWalk text, slot
    i = at
    i++ while i < words.length and words[i]
    i++ while i < words.length and !words[i]
    slots[i]
