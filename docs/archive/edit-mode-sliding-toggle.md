> **ARCHIVED — COMPLETE (2026-10-31).** Decision record for the frame strip's edit-mode control. The present-tense
> description lives in `docs/architecture/visual-design-system.md` (the "Edit-mode toggle" row and the `barToggle*`
> metrics) and in the headers of `src/buttons/EditIconButtonWdgt.coffee` and `src/icons/EditModeToggleAppearance.coffee`.
> Supersedes `pencil-eye-edit-mode-toggle-plan.md`. Index: `docs/archive/INDEX.md`.

# The edit-mode control becomes a sliding toggle

## What it is now

The strip's trailing piece is a pill-shaped switch 80 px wide, with the eye at its left end, the pencil at its right
and a knob under the current mode's icon. Right is on: editing. A press anywhere on it flips the mode, and the knob
slides over 160 ms. A mode change from anywhere else lands at once.

## Why the single swapping icon went

The owner found the old control convoluted, and a probe of one real click showed why. Hovering showed the eye and its
tooltip while the window was still editing. Releasing put the window in view mode with a **pencil** on the button and no
tooltip, and it stayed that way until the pointer left. So the same icon meant "you are here" at rest and "click to go
there" on hover, and the moment of a click was the moment it looked most wrong.

The reasons recorded for that design had also weakened by then:

- the yellow pencil people had learned to read as "editing" no longer existed at rest (§8 of the old plan);
- the hover yellow that said "this is a preview" was gone after the visual redesign, leaving `#E2E2DE` → `#FFFFFF` on the
  focused bar, so the swap read as a glitch;
- the amber pulse on the eye during a drag, which the plan leaned on, was never in `src` (the cue is a "view-only" badge);
- scanning modes at a glance had already been given up in §8.

## The options, seen on real windows

All were prototyped as a runtime patch over the real framework, in one scene that included windows nested three levels
deep, because busy-ness under nesting was the owner's explicit question.

| Option | Viewing | Editing | Why not |
|---|---|---|---|
| A. Action icon | Pencil | Eye | Calm, but plain panels lose their clear state signal |
| B. Keep it, fix the defects | Eye | Pencil | Still one icon with two meanings |
| C. One switch | Pencil | Pencil on a plate | Calmest clear option and the assistant's recommendation; a plate can read as a hover state, and a newcomer may need one click to learn it |
| **D. Sliding toggle (chosen)** | Knob at eye | Knob at pencil | |
| D2. Switch between icons | Bright eye | Bright pencil | Three separate things in every bar, and a faint inactive eye |
| E. Words | "Edit" | "Done" | Same font as the titles, so it competes with them |

D was the owner's decision over the recommendation for C. D is clearer, and a newcomer understands it without help. The
accepted costs are the most visual weight of any option under nesting (the white knob is the brightest thing on a light
bar), nearly twice C's width, and the earliest drop on narrowing windows (below 170 px, against 134 px).

## Decisions worth keeping

- **Only a press slides.** A slide is feedback to the person who pressed. Everything else lands at once, which is what
  stops every view-mode window sliding as it is built, uncollapsed or restored. It also means no "has this been painted
  yet" state, which the prototype needed and the real thing does not.
- **No test-only carve-out.** Scroll momentum and the blinker suppress themselves under the Automator's pacing; the slide
  does not. It runs the product's own path in every test that presses a toggle, and the macro pump holds until it lands
  (`world.anyKnobSlideOngoing`, asked by `MacroToolkit._queueDrained` and `readyForMacroScreenshot`). A slide reads the
  cycle clock, so this gate is what keeps wall-clock time out of captured pixels. Paint is a function of where the knob
  stands, so a landed knob is the same pixels however many frames it took.
- **No second registry.** "Is a knob sliding?" is asked of `world.steppingWdgts`, which every teardown path already
  clears, so there is no new set to forget.
- **The strip learned piece lengths rather than the toggle special-casing itself.** `FrameWdgt._barSpec` names
  `pieceLengths`, and `FrameBarWdgt`'s fit, placement and title inset all sum lengths. With every piece one slot long, the
  arithmetic is exactly the old `n * slotSize`.
- **Not the design's TOGGLE.** `LabelledToggleWdgt` has a fixed label and says "on" with the accent. This control names
  two modes, so it does not wear the accent and does not share that class.
- **The class keeps its name.** `EditIconButtonWdgt` and `win.editButton` still describe what it is: a member of the
  icon-button family that edits. A rename would change no behaviour.

## Case law

- **A check that says OK can be blind.** The first prototype check read `world.errorsWhileRepainting`, which the world
  resets every cycle, so a real paint crash passed while an error log sat on screen. What lasts after a paint crash is
  `world.widgetsGivingErrorWhileRepainting` and `world.errorConsole`.
- **A hidden title has no measured font size.** `StringWdgt.buildCanvasFontProperty()` with no arguments reads
  `fittingFontSize`, which a collapsed label never set, and the resulting invalid font string made SWCanvas's `measureText`
  return null. Name the font role's size explicitly when borrowing a label's font.
- **User-facing text can name a control.** `InfoDocs` told people to "click the pencil icon on the window bar". A control's
  look can be written into prose a code search for its class will not find.
