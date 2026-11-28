# Method categories — the `#:` marker, what a class's record keeps of its text, and the gate

How a class's source names the categories of its methods, what the meta-object keeps of that and of the comments
around its members, and the build gate that holds the marker. Present tense, verified against `src/` on 2026-11-28.
The arc that builds on it (the code browser that lists a class's categories, the verbs that edit them) and the
measurements behind its shape live in `docs/plans/inspector-browser-plan.md` (§5.9, §5.10).

**The rule in one paragraph.** A class's text groups its methods by MARKER lines, `  #: <category>` at the member
column, each giving its category to every member after it up to the next. The parse that cuts a class's members out
of its text (`src/meta/Class.coffee`) keeps, beside each member's source, its comment and its category, and keeps the
class's own comment and the names of its categories. A marker is a comment: it excludes nothing and changes no
compiled byte. `buildSystem/check-method-categories.js` holds its form, reading the tree through that same parse,
and holds the classes that name no category yet to a budget that only falls.

---

## 1. What a method category is

A Smalltalk PROTOCOL: a name for a group of a class's methods by what they are for ("initialization", "accessing",
"testing"), so a reader finds a method by its purpose before its name. A category belongs to the class whose text
names it; a method stands in at most one. A class that names none has its methods in no category; a class that
names one gives one to every instance method it holds (§5, `MARKED_CLASS_UNMARKED_METHOD`). Categories group METHODS: a
field or a class-side member under a marker is kept in that category by the record (§3) but is never counted or
required by the gate.

Nothing in the product SHOWS a category yet: the readers today are the meta-object's accessors, a world snapshot's
records (`serialization-duplication-reference.md` §12) and the gate.

## 2. The marker

```coffee
  #: accessing

  # my inspectors, left to right
  inspectors: ->
```

- **ONE form**: a line that is exactly two spaces, `#:`, one space, and the category's name
  (`Class::categoryMarkerRegex`, `/^  #: (.*)$/`). The name is lower-case words with one space between two, and no
  word of it OPENS with `extends` (`Class.isACategoryName`: `/^[a-z]+(?: [a-z]+)*$/`, and none of `/(?:^| )extends/`):
  the boot dependency scan (`src/boot/dependencies-finding.coffee`, `EXTENDS`, `\sextends\s*(\w+)`) reads a blank,
  then `extends`, then the word glued to it or after it, on any line of a class's text, a comment's included, as an
  edge — `#: extendsfoo` would make its class load after a class `foo`, `#: drag extends drop` after `drop`. (The scan
  reads one line at a time, so a name whose last word is `extends` reads no edge; the one rule refuses it all the
  same.) A `#:` line whose name is no category's is no marker to the parse: it stays a line
  of the member's comment, and nothing throws (the build's syntax gate drives this parse over every file, where a
  throw fails the build) — the gate fails it instead (`CATEGORY_NAME_MALFORMED`).
- **It stands BETWEEN two members, at the member column** — before the first member included. A comment at the
  member column ends the body above it (`Class::topLevelCommentRegex`, `/^  #.*/m`), so a marker always closes the
  member above it and opens the STASH of the member below (the lines between a body and the next member's line), as
  every such comment does. That is also why a marker (or any comment) typed at the member column INSIDE a method
  cuts the method there: the rest of its body lands in the next member's stash and is never compiled
  (`STASH_HOLDS_CODE`). Never above the `class` line (the parse reads those lines as the class's comment), never
  after the last member (the parse drops what follows it), never at another indent (inside a body it is a comment of
  that method, read by nothing).
- **It gives its category to every member after it, up to the next marker**: a member's category is the last marker
  at or above it, and a member above the first marker has none. A category may open more than once in a class (a
  method that belongs to an earlier group takes that marker again above it, and no method moves in its file); the
  class lists it once.
- **A marked class is marked whole**: once a class names a category, every instance method of it stands in one, so
  the first marker stands above the first method.
- **Layout** (the house's, no rule): a blank line above a marker and one below it, and the marker ABOVE a member's
  comment block, never between that block and the member's line: the blank line below a marker would cut the
  contiguous comment block directly above a header that `# thin-wrap-exempt:`, `# relayout-bounds-first-exempt:` and
  `# raw-screen-pointer-sanctioned:` are read from (`lint-and-static-checks.md` §5), and a sanction cut off from its
  header excuses nothing. No reader depends on the blank lines themselves: the parse takes a marker out of a stash
  whatever surrounds it.
- **⚠ A marker ends the SOURCE of the member above it**: that member's source runs to the marker's line, the blank
  lines before it included. So write a marker into a blank line the class already has between two members, with its
  own blank line below it: a blank line ADDED above a marker is a line added to the source of the member above it —
  its compiled output the same, its source string not. A change that places markers is proved by comparing every
  member's SOURCE string as well as the compiled output.

## 3. What a class's record keeps (`src/meta/Class.coffee`)

**One parse, two passes.** `getSourceOfAllProperties` cuts each member's source out of the text as it always has and
keeps each member's stash, as written, beside its name; a second pass, `_notesOf`, reads the stashes in the text's
order (`_commentAndMarkersOf`: a stash's marker names, and every other line as its comment). It answers
`[staticSources, instanceSources, notes]`, the two source stores at the first two positions, where every reader of
the parse reads them. `_parsedSource` adds the class's comment, read off the lines above the `class` line. Every
store is a RECORD STORE, keyed by member names with no prototype (`Class._newRecordStore`), and holds a member only
where there is something to say of it (`Class._keepIn`: `""` is no entry).

| Kept | Read as | Asked as |
|---|---|---|
| the class's comment | the lines above the `class` line, as written, the blank lines at its ends trimmed; `""` for none | `classComment` |
| a member's comment | its stash with the marker lines taken out, each line less the member column's two spaces (a line indented deeper keeps the rest), the blank lines at its ends trimmed; a blank line between two groups stays | `commentOf name` (`""` for none) |
| a member's category | the name of the last marker at or above it; none above the first marker | `categoryOf name` (`""` for none) |
| the class's category list | its markers' names, each once, in the order first met | `categoryNames` |
| the class's categories | the category list, then each other category an instance member stands in, once, in the store's order | `categories()` |

Statics are read by the same pass into their own two stores (`staticPropertiesComments`,
`staticPropertiesCategories`), which no accessor reads. A member written twice keeps what its LAST writing says, as
its source does. `bootRecord` is the whole record as the class's text at boot gives it (the `SourceVault`'s text,
parsed again by `_parsedSource`), or `undefined` for a class made at run time.

**What the record does NOT keep** (the vault holds the whole text, and nothing reads these): the blank lines at a
comment's ends (between a member's comment and its line, around a marker, around the class's comment); the spaces
around a member's colon (`name:   value` and `name: value` keep the same source); whatever follows the last member;
and where the statics stand among the instance members (two stores, each in the text's order). The comment a class
writes INSIDE its body before its first member is that member's comment, as the parse reads every stash. A `###`
block comment is no comment by `Class.isAComment` (its inner lines open with no `#`), so the gate reads one between
members as code (§5): write a comment as `#` lines.

**The pure rules**, each in one place on `Class`: `isACategoryName name` (§2); `isAComment text` (every line blank or
opening, past its indent, with `#`); `splitLeadingComment text` — a member's text as an editor shows it split into
`{comment, source}` at its LAST leading `#` line (the comment is the leading run of blank and `#` lines up to it,
`""` where the text opens on code; the source is everything after that line, so a source opening on a blank line
keeps it); `withLeadingComment comment, source` — its inverse, the comment, a line break and the source, or the
source alone where the comment is `""`. The split of a join gives a member back its comment and its source unless the
source itself opens with a `#` line, or with blank lines and then one (a value written below its member's line, under
a comment of its own): no member of the tree does (measured by the record's proof, plan §5.9).

**The edits.** None of them tells anyone, as no meta-object edit does: telling is the caller's (the gesture records
and tells, serialization §12).

- `applyMemberEdit memberName, source, opts = {}`: `opts.comment` and `opts.category` are each KEPT as the member has
  it where the key is absent or `undefined`, SET where handed, and `""` CLEARS it (`undefined` is never the clear: a
  record carrying it would lose the key to JSON, which reads "keep"). A HANDED note is a person's or a file's, and one
  that is none — a comment that is not lines of comment, a category that is neither `""` nor a category's name — is
  refused before the compile (`Class._refuseNotes`), having changed nothing. A copy hands none: `opts.notesOf` names
  the member whose comment and category the edit CARRIES, as the stores hold them, unjudged (a duplicate's or a
  rename's copy, `ClassMemberRef._editCopyUnder`); a note handed beside it is set instead. So a note is judged only as
  it comes in from outside the stores, never one a class's text gave a member: a class made at run time, whose text
  may hold a `###` block or code between two members (the parse keeps those lines as the next member's comment),
  keeps what its parse read there, and each of its members is still edited, duplicated and renamed.
- `removeMember memberName` drops the member's comment and category with its source.
- `setClassComment text` replaces the class's comment whole (lines of comment, `""` for none); `setCategories names`
  replaces the category list whole (distinct category names, in a reader's order, a category no member stands in
  included). A member's category stays the member's: one the list leaves out still shows in `categories()`, after
  the list's.
- Away from boot: `Class.membersAwayFrom current, boot` lists each member whose source, comment or category is not
  its boot one (never the constructor); `Class.classNotesAwayFrom current, boot` names `"classComment"` and
  `"categoryNames"` where each differs; `editsAwayFromBoot` is both, the count a world load's confirm states
  (serialization §12).

## 4. The vocabulary

RECOMMENDED, not closed: these are the names that recur across the tree, each with what belongs there. A class names
a category of its own where none of them fits (the inspector's "choosing", "filtering", "member editing" are such
names); a name is never bent to fit the list, and the list never bent to fit one class.

| Category | What belongs there |
|---|---|
| initialization | the constructor and what builds a new instance's state and children (`_buildAndConnectChildren`, `createAppearance`) |
| accessing | reading and writing the object's own state, a field's getter and setter, where no topic below claims it |
| testing | the questions that answer true or false of the object (`isZero`, an `is…`, `has…` or `can…`) |
| geometry | position, extent and bounds, their setters, and the mapping between planes |
| layout | how the object arranges its children and is arranged: `_reLayout` and its kin, a layout spec's knobs |
| drawing | how it paints: its appearance, its back buffer, what it marks changed |
| event handling | what pointer, keyboard and wheel input does to it: presses, clicks, hovers, keys |
| drag and drop | being grabbed, carried and dropped, and taking drops (`grabsToParentWhenDragged`, `_reactToBeingDropped`) |
| notifications | what it is told of another object's change and what it tells others (its `_reactTo…` callbacks, a `note…` door) |
| structure | its place in the widget tree: adding and removing children, its parent, the queries that walk the tree |
| lifecycle | stepping, showing and hiding, and its end: destroy and teardown (`step`, `fullDestroy`) |
| menus | the menus it builds and the actions their rows dispatch (`addWidgetSpecificMenuEntries`) |
| pins and dataflow | the pins it advertises, their setters, and its part in the dataflow engine (`pins`) |
| copying and serialization | duplication, saving and restoring (`fullCopy`, `_reactToBeingCopied`, `_afterDeserialization`) |
| printing | the text that names or describes it (`toString`, `colloquialName`) |
| private | a helper with no topical home — NOT every underscored name: the underscore already says private, and a `_setXNoSettle` core stands with the `setX` it serves |
| comparing | on a value class: equality and order (`equals`, `lt`) |
| converting | on a value class: making another kind of value from it (`asArray`) |
| arithmetic | on a value class: `add`, `subtract`, `multiplyBy` and their kin |

Each name passes `Class.isACategoryName`; so must one a class makes up.

## 5. The gate — `buildSystem/check-method-categories.js`

A row of `buildSystem/gates.js` (row 35, run on every build but a `--noSyntaxCheck` one, whatever the flavour ships),
over the compiled sources: `src/` and the tests repo's harness. Its rules, each by its class
(`lint-and-static-checks.md` §3b):

| Rule | Class | Fails on |
|---|---|---|
| `MARKER_MISPLACED` | B, zero | a comment line opening `#:` where no marker is read: at any indent but the member column's two spaces (inside a member's code, a comment of it), above the `class` line (it is the class's comment), or in a compiled file that holds no class (`src/boot/*`) |
| `CATEGORY_NAME_MALFORMED` | B, zero | a `#:` comment at the member column the parse does not read as a marker: its name is no category's (§2), or no single space follows the `#:` |
| `STASH_HOLDS_CODE` | A, zero | a line the parse DROPS — above the `class` line, in a stash, after the last member — that is no comment (`Class.isAComment`): code the meta-system never compiles. A comment or marker typed at the member column inside a body ends the member there, and the rest of the body lands here |
| `EMPTY_CATEGORY` | B, zero | a marker with no instance method under it before the next marker or the class's end, each marker judged |
| `MARKED_CLASS_UNMARKED_METHOD` | B, zero | in a class that names a category, an instance method above its first marker |
| `UNMARKED_CLASSES_ABOVE_BUDGET` | C | the classes holding an instance method and naming no category are more than `UNMARKED_CLASSES_BUDGET`'s number for their repo |

**It reads the tree as the product does**, so the gate and the page cannot disagree: the tree's own `Class.coffee`,
loaded by `lib/meta-compiler.js` as the syntax gate loads it, parses each class file (`_parsedSource`), and each line
of the file is read as the parse reads a stash (`_commentAndMarkersOf`); each member is placed on its file's lines by
`lib/meta-compiler.js` `placesOfMember`, the rule `lib/call-sites.js` places one by too (a member written twice at
its LAST writing, the one the parse's store keeps); the `#:` comment lines are spotted by `lib/coffee-mask.js` (the
lexer's reading: a `#:` inside a string or a heredoc is no comment, so no marker-shaped line), while whether a
dropped line is comment or code is the meta-system's own rule, `Class.isAComment`; a member is a METHOD when its
source opens with a function literal, read by the product's own `Widget.functionLiteralReading`, compiled from
Widget's own record. Fields and
class-side members are never counted. And it reads each member's category back off the lines and holds it to the
parse's: a disagreement means the two readings drifted, and nothing is judged. Why the shared method-header matcher
is not its reading: `lint-and-static-checks.md` §6b.

**The budget counts CLASSES, one number per repo** (`UNMARKED_CLASSES_BUDGET`: Fizzygum's `src/`, the tests repo's
harness; `meta/Class.coffee` counts like every class), each with its dated reason beside it: a class holding an
instance method and naming no category counts once, however many methods it holds. So a method added to a class
nobody has marked costs nothing, and a NEW class holding a method lands marked whole — or raises its repo's number
in the same change, for the reason the advice names: a class that comes out of an unmarked one by a mechanical move
whose methods nobody re-read. A split of one unmarked class into two adds one to its repo's count; a move between
the two repos adds one to the count of the repo it lands in (and the other's falls by one); a rename within a repo
moves no count. A class marked whole lowers the count, and the run prints `UNDER` with the number to lock in — a
pass, so the build the first marked class lands in is green.
Markers placed by a name rule nobody read, or every method under one name, are the wrong answer to it.

**Exit 2, never a verdict, when it measured nothing**: the meta-compiler does not load; a reading it asks of the
meta-system is gone (`_parsedSource`, `_commentAndMarkersOf`, `classRegex`, `Class.isAComment`, Widget's
`functionLiteralReading`) or answers another shape; the parse keeps no categories; a class it cannot parse or whose
class line it cannot find; a member whose source stands nowhere in its file, or a line two members' sources claim; a
text the lexer refuses; a member's category read off the lines that is not the parse's. In
`check-method-categories-selftest.js` (on every build) the control passes at its budget or under it (`-- UNDER` and
its NOTE), as the tree stands; every rule fires on its own plants and no other (`#: extendsfoo` among the malformed
names); three runs that measure nothing read exit 2, each beside a planted violation it must not judge; and a tree
one UNDER its budget — one counted class taken out of the copy, since no plant can lower a count — passes with exit
0, `-- UNDER` and the NOTE naming the lower number, firing no rule. Each fired rule prints its advice
(`lib/gate-advice.js`); the control and the run under its budget print none.

**What it cannot see**: a class made at run time (it has no file; its record keeps whatever its text says, and an
edit's category is judged by `applyMemberEdit`); a class a test or a rig makes from its own text; a member that is a
function only at run time (`foo: someFunctionMadeElsewhere` is no method by its source's reading); whether a
category's NAME fits the methods under it, which is a reader's judgment, by §4.

## 6. It excludes nothing

A marker is no successor of the two retired exclusion markers (`check-region-markers.js`, `check-whole-file-markers.js`,
`lint-and-static-checks.md` §3), whose lesson stands: invisible, text-level EXCLUSION is the wrong tool. A marker
removes no line from any build, and the compiled output of a class is the same byte for byte with or without its
markers; what it adds is a name the record keeps.

## See also

- `lint-and-static-checks.md` — §3 (the gate's row), §3b (its rules' classes), §5 (the marker among the in-code
  markers), §6b (why it reads members off the parse, not the shared matcher).
- `serialization-duplication-reference.md` §12 — the records that carry a member's comment and category, a class's
  comment and its category list, and a world load's return to boot.
- `docs/plans/inspector-browser-plan.md` §5.9, §5.10 and §6 U5–U8 — the arc that built this and the browser that
  will show it.
