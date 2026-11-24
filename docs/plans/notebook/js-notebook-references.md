# JS notebooks for Fizzygum — references

What the owner's notes hold that is useful for building a **simple notebook inside Fizzygum**: small,
browser-only, hand-written implementations, sorted by how little code they take. Gathered on
2026-11-24 from Apple Notes and the notes vault. Jupyter-for-JS
items, the Mathematica material, the STOIC notes, and big or server-backed systems are left out; they
are listed at the end with their links. The design this research feeds:
[`notebook-design-proposal.md`](notebook-design-proposal.md).

The images below live in [`js-notebook-references/`](js-notebook-references/), beside this file; that
folder and the HTML version of this page (`js-notebook-references.html`) are gitignored, so the images
show only in a local checkout.

## At a glance

| # | Implementation | Own code | Size | Depends on | Server |
|---|---|---|---|---|---|
| 1 | [Scratch.js](#1-scratchjs) | `██` | 4 KB | nothing | none (keeps its text in [localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)) |
| 2 | [javascript-notebook](#2-timcwinklerjavascript-notebook) | `████` | 10 KB code + 1 KB CSS | nothing | none (saves itself as a file) |
| 3 | [Tangle](#3-tangle) | `█████░░░` | 13 KB + 8 KB kit | core: nothing; kit: [MooTools](https://mootools.net/) | none |
| 4 | [Chalkboard](#4-chalkboard) | `██████████░░` | 25 KB + 6 KB wiki | [jQuery](https://jquery.com/) (56 KB) | only to save pages (WebDAV) |
| 5 | [TensorBook](#5-tensorbook) | `███░░░░░░░░░░░░░░░░░` | 8 KB core, 50 KB app | [Lit](https://lit.dev/), [TensorFlow.js](https://www.tensorflow.org/js) | none |

`█` = the code that does the notebook work, `░` = the rest of that implementation's own code (one
block ≈ 2.5 KB). Sizes measured on 2026-11-24 from the sources linked below.

## Already in Fizzygum

A Fizzygum notebook would not start from zero. Three pieces overlap with what the implementations
below do:

- **`ConsoleWdgt`** already runs typed code, with *Run selection* and *Run contents*, against a target
  widget — [source](../../../src/meta-tools/ConsoleWdgt.coffee).
- **`DataflowEngine`** is the world's one calculation engine. It already serves wired circuits and the
  spreadsheet, and a notebook could be its third client for recalculating cells and marking stale
  results — [source](../../../src/dataflow/DataflowEngine.coffee),
  [spec](../../specs/dataflow-engine-spec.md).
- **The single-file save plan** covers what implementation 2 does by downloading its own page —
  [plan](../single-file-save-plan.md).

## Implementations, smallest first

### 1. Scratch.js

**[Scratch.js](https://news.ycombinator.com/item?id=25138872), an interactive JavaScript scratchpad.**
By [Kristian Andersen Hole](https://github.com/kahole), MIT licence,
[Show HN](https://news.ycombinator.com/item?id=25138872) on 2020-11-18. Saved in Apple Notes →
*Other generic links* (three link cards).
*4 KB script · one HTML file · no dependencies.*

The whole page is one editable text area, like Emacs's `*scratch*` buffer. Cmd/Ctrl-Enter runs the
selection, or the current line if nothing is selected, with a global `eval`, and inserts the result on
a new line right below. A thrown error inserts `#!Error`. The text is saved to localStorage when the
page closes.

> **For Fizzygum:** this is "print it" in place, and the results stay in the text as history.
> `ConsoleWdgt` already does the running; the difference is that here the output is written back into
> the document.

[![Scratch.js with four lines evaluated, each result on the line below](js-notebook-references/scratch.png)](http://fingswotidun.com/tests/scratch/)

*The live copy at fingswotidun.com, driven headlessly on 2026-11-24: each code line was run in order
through the page's own `evaluate()`, the function Cmd/Ctrl-Enter calls.*

Links: [HN thread](https://news.ycombinator.com/item?id=25138872) ·
[source (gist)](https://gist.github.com/kahole/651990b888c19b84d5700422daa961de) ·
[live copy](http://fingswotidun.com/tests/scratch/) ·
[original address](https://hole.dev/scratch/) (now a placeholder page)

### 2. timcwinkler/javascript-notebook

**[timcwinkler/javascript-notebook](https://github.com/timcwinkler/javascript-notebook), "a very
simple self-contained javascript notebook".** By [timcwinkler](https://github.com/timcwinkler), last
updated 2021. Saved twice in Apple Notes → *Notes* and *Github links*.
*9.7 KB script + 1 KB CSS · one 28 KB HTML file (the rest is its built-in help) · no dependencies.*

The notebook is a list of numbered "interaction units", each an input box with an output box under
it. Each unit has *go*, *txt*, *clr* and delete buttons; at the bottom are *go last*, *add*, *go-add*
and *go all*. Input starting with `<` is treated as HTML, so a unit can be documentation or a small
UI. Code runs in the global scope. An *RW⇄RO* button toggles read-only, and *save* downloads the
page's own HTML as a new file, so each notebook is one self-contained file.

> **For Fizzygum:** the unit model is about as small as a notebook can be, and recalculation is only
> "go all". The read-only toggle matches Fizzygum's view mode, and save-the-page-as-a-file matches the
> single-file save plan.

[![javascript-notebook help page showing an interaction unit](js-notebook-references/winkler-live.png)](https://timcwinkler.github.io/js+help.html)

*The live page, which documents itself as a notebook (screenshot 2026-11-24).*

[![A notebook with a text unit and a code unit computing phi](js-notebook-references/winkler-phi.png)](https://github.com/timcwinkler/javascript-notebook/blob/main/phi.png)

*The repo's own example: a text unit, then a code unit computing the golden mean.*

Links: [repo](https://github.com/timcwinkler/javascript-notebook) ·
[live page](https://timcwinkler.github.io/js+help.html) ·
[source (js+help.html)](https://raw.githubusercontent.com/timcwinkler/javascript-notebook/main/js%2Bhelp.html) ·
[longer example (mfibo.html)](https://raw.githubusercontent.com/timcwinkler/javascript-notebook/main/mfibo.html)

### 3. Tangle

**[Tangle](http://worrydream.com/Tangle/), a JavaScript library for reactive documents.** By
[Bret Victor](http://worrydream.com/), 2011. Saved in the notes vault (2014).
*13 KB core · + 8 KB TangleKit controls (need MooTools).*

Not a notebook, but its recalculation model fits one. Values are named in the HTML with `data-var`
attributes, and a model object has `initialize()` and `update()`. Changing any value, for example by
dragging a number, reruns `update()`, and every display of a value refreshes.

> **For Fizzygum:** this is the "keep every result current" half of the 2017 spec. `DataflowEngine`
> already propagates changes along edges, so Tangle is a reference for how it feels to use rather
> than code to borrow.

[![Tangle home page with the cookies and calories example](js-notebook-references/tangle.jpg)](http://worrydream.com/Tangle/)

*Tangle's home page: the whole reactive document is one HTML span and a two-line model (screenshot
2026-11-24).*

Links: [home](http://worrydream.com/Tangle/) · [guide](http://worrydream.com/Tangle/guide.html) ·
[repo](https://github.com/worrydream/Tangle) ·
[Tangle.js](https://github.com/worrydream/Tangle/blob/master/Tangle.js) ·
[TangleKit.js](https://github.com/worrydream/Tangle/blob/master/TangleKit/TangleKit.js) ·
[Explorable Explanations essay](http://worrydream.com/ExplorableExplanations/)

### 4. Chalkboard

**[Chalkboard](http://tinlizzie.org/chalkboard/), "a rich JavaScript workspace".** By Takashi
Yamamiya, 2009, MIT licence; shown at C5 2009 as
[Active Essays on the Web](http://tinlizzie.org/chalkboard/#ActiveEssaysOnTheWeb). Saved in the notes vault (2017, tagged `#fizzygum`).
*25 KB (≈800 lines) + 6 KB wiki · jQuery · saving pages needs a WebDAV server.*

Each page is an editable document (a wiki page, linked as `#PageName`) with code mixed into the
prose. Select an expression and press **Do it** (Ctrl+D) to run it and see the result in the
transcript pane, or **Print it** (Ctrl+P) to insert the answer next to the expression. Running
happens in the browser; only saving goes out, as an HTTP PUT to a WebDAV server, or to a local file in
old Firefox.

> **For Fizzygum:** Smalltalk's Do it / Print it inside a document is the Morphic-lineage version of
> a notebook, so it's the closest fit in spirit. A Fizzygum version would replace the WebDAV wiki with
> its own saving.

[![Chalkboard with a document on the left and a transcript pane showing results on the right](js-notebook-references/chalkboard-2013.png)](http://tinlizzie.org/chalkboard/)

*The 2013 screenshot from the vault: the transcript on the right holds results of Do it.*

Links: [live](http://tinlizzie.org/chalkboard/) ·
[chalkboard.js](http://tinlizzie.org/chalkboard/chalkboard.js) ·
[wiki.js](http://tinlizzie.org/chalkboard/wiki.js) ·
[Active Essays on the Web](http://tinlizzie.org/chalkboard/#ActiveEssaysOnTheWeb) ·
[SandBox page](http://tinlizzie.org/chalkboard/#SandBox)

### 5. TensorBook

**[TensorBook](https://github.com/ljcucc/tensorbook), a TensorFlow.js notebook.** By
[ljcucc](https://github.com/ljcucc), "under development", last pushed 2022-09. Saved in Apple Notes →
*Notes* (repo and site).
*≈8 KB notebook core · 50 KB app · Lit + TensorFlow.js · demo site down.*

Cells go into a run queue and execute one at a time through `window.eval`, so async cells finish in
order. While a cell runs, `console.log` is redirected into that cell's own output. Notebooks are kept
in localStorage.

> **For Fizzygum:** two small ideas worth taking: give each cell its own captured log, and serialise
> async cells. The rest is the Lit UI and the TensorFlow.js payload. There's no screenshot because the
> demo site does not respond.

Links: [repo](https://github.com/ljcucc/tensorbook) ·
[Notebook.js (the core)](https://github.com/ljcucc/tensorbook/blob/HEAD/src/Notebook.js) ·
[Cell.js](https://github.com/ljcucc/tensorbook/blob/HEAD/src/data/Cell.js) ·
[demo site](https://tensorbook.ljcu.cc/) (no response 2026-11-24)

## Design references (no code to reuse)

### The owner's spec: JS Notebook system – desiderata

Notes vault, 2017-03-14, tag `#algebriteNotebookSystem`.

- [ ] an in/out notation for referencing results from previous entries
- [ ] the output from a block can contain an aggregate of:
  - normal arbitrary text
  - LaTeX ([KaTeX](https://katex.org/))
  - plots
  - ASCII formulas
- [ ] the input should accept Markdown
- [ ] move / delete each block
- [ ] move / edit each block
- [ ] insert a new block
- [ ] it should be visible which blocks have stale results

Two to-dos from the same evening:
"Check notebook system in JS or generic repositionable divs / look at tympanus stuff as well"
(freely placed blocks, which Fizzygum's widgets already are) and
"That notebook system for algebra in JS – is any source visible?",
which is probably Math Notepad, below.

### Math Notepad

**[Math Notepad](https://mathnotepad.com/)**, by [Jos de Jong](https://github.com/josdejong), author
of [math.js](https://mathjs.org/). Saved in the notes vault (2016, tagged `#fizzygumApps`). *Hosted, with login · source not public.*

[![Math Notepad: lines of expressions with results in red, an inline plot, units and matrices](js-notebook-references/mathnotepad.png)](https://mathnotepad.com/)

One document of lines: each expression has its result right under it, in red, and the document also
holds variables, functions, an inline plot, units and matrices, with `#` lines as comments. It's close
to the 2017 spec drawn out, apart from Markdown input.

The answer to the 2017 question is still no: Jos de Jong has no notepad repository on GitHub
(checked 2026-11-24). Use it as a picture, not as code.

Links: [site](https://mathnotepad.com/) · [math.js](https://mathjs.org/) ·
[math.js repo](https://github.com/josdejong/mathjs)

### The Design Space of Computational Notebooks

**[The Design Space of Computational Notebooks: An Analysis of 60 Systems in Academia and Industry](https://pg.ucsd.edu/publications/computational-notebooks-design-space_VLHCC-2020.pdf)**
— Sam Lau, Ian Drosos, Julia M. Markel, Philip J. Guo, VL/HCC 2020. Saved in the notes vault (2020).

[![First page of the paper](js-notebook-references/paper-p1.jpg)](https://pg.ucsd.edu/publications/computational-notebooks-design-space_VLHCC-2020.pdf)

It sorts 60 notebook systems along 10 dimensions grouped into four stages: importing data, editing
code and prose, running code (execution order, liveness, outputs), and publishing. Useful for deciding
what "simple" leaves out, and for picking positions on **execution order** and **liveness** on
purpose, since those decide how staleness shows.

Links: [PDF](https://pg.ucsd.edu/publications/computational-notebooks-design-space_VLHCC-2020.pdf) ·
[IEEE Xplore](https://ieeexplore.ieee.org/document/9127201) ·
[DOI](https://doi.org/10.1109/VL/HCC50065.2020.9127201)

## Dropped, with the reason

**JS inside Jupyter** (owner's filter; Apple Notes → Notes)
- [Bringing Modern JavaScript to the Jupyter Notebook](https://blog.jupyter.org/bringing-modern-javascript-to-the-jupyter-notebook-fc998095081e) (saved twice)
- [Deno 1.37: Modern JavaScript in Jupyter Notebooks](https://deno.com/blog/v1.37)
- [How to Split Classes in Multiple Cells in Jupyter Notebook](https://saturncloud.io/blog/how-to-split-classes-in-multiple-cells-in-jupyter-notebook/)
- [GitHub topic: literate-programming, filtered to Jupyter](https://github.com/topics/literate-programming?l=jupyter+notebook)

**Mathematica-related** (owner's filter; vault)
- "Mathematica core in JS", an idea note (2014)
- Wolfram Language Computable Notebook · [Wolfram Cloud sandbox](https://sandbox.open.wolframcloud.com/app/objects/e373b965-afd7-4832-8bcb-4e613937f205#sidebar=compute) (no longer responds)
- Mathics · [mathics.org](https://mathics.org/)
- Best open-source Mathematica equivalent · [Stack Overflow](http://stackoverflow.com/questions/33550/best-open-source-mathematica-equivalent)
- Is there an open-source implementation of Mathematica-the-language? · [Mathematica Stack Exchange](http://mathematica.stackexchange.com/questions/4454/is-there-an-open-source-implementation-of-mathematica-the-language)
- Term-Rewriting in JavaScript for Fun and World Domination
- Calca: [announcement](http://praeclarum.org/post/55019743936/calca-the-text-editor-for-engineers) · [Calca 1.2](https://web.archive.org/web/2014/http://praeclarum.org/post/65701122908/calca-1-2-experiments-in-text-editing) (archived) · [calca.io](http://calca.io/)

**STOIC notebook notes** (owner's filter; vault, 2016)
- another strange example of STOIC's notebooks refresh
- Some interesting cases of dependencies tracking
- Untitled Quick Note 46 (cells screenshot)
- Debug code from Stoic notebooks
- How to run a Fermat session from the command line

**Observable** (needs its hosted platform)
- [asg017/unofficial-observablehq-compiler](https://github.com/asg017/unofficial-observablehq-compiler) · [its notebook](https://observablehq.com/@asg017/an-unofficial-observablehq-compiler) (Apple Notes)
- My First Observable notebook · [on Observable](https://observablehq.com/@kreijstal/my-first-observable-notebook)
- Bridget Riley · [on Observable](https://observablehq.com/@pstuffa/bridget-riley)
- Fractal tree · [on Observable](https://observablehq.com/@sethpipho/fractal-tree)
- randomizedFloodFill.gif · [on Observable](https://observablehq.com/@mbostock/randomized-flood-fill)
- oriented.gif · [on Observable](https://observablehq.com/@mbostock/oriented)
- "Imagine if Notion married Observable" · [tweet](https://twitter.com/yoshikischmitz/status/1327966301118025728)

**Too big**
- [datafrey/jnjs](https://github.com/datafrey/jnjs), [tallninja/jscode](https://github.com/tallninja/jscode), [ranasun/js-notebook](https://github.com/ranasun/js-notebook) ([live](https://ranasun.github.io/js-notebook/)): the same React + esbuild-wasm + code-editor stack
- [addison-ch/plutobook](https://github.com/addison-ch/plutobook): a 19 MB multi-package repo
- Kajero: [site](http://joelotter.github.io/kajero/) · [repo](https://github.com/JoelOtter/kajero): needs no server, but 1.25 MB of React/Redux
- Klipse: [repo](https://github.com/viebel/klipse) · [blog](http://blog.klipse.tech/) · [sleep post](http://blog.klipse.tech/javascript/2016/12/19/es2017-sleep.html) · [turtle post](http://blog.klipse.tech/python/2017/01/04/python-turtle-fractal.html): a 96 MB ClojureScript repo
- LiaScript: [algebrite_template](https://github.com/liaScript/algebrite_template) · [liascript.github.io](https://liascript.github.io/): a whole course system
- Eve: [witheve.com](http://witheve.com/) · [repo](https://github.com/witheve/Eve) · [A Visual History of Eve](https://web.archive.org/web/2018/http://futureofcoding.org/essays/eve/) (archived): a whole language and environment
- nteract / Hydrogen: [repo](https://github.com/nteract/hydrogen): Atom and Jupyter-kernel tooling

**Hosted or closed source**
- Carbide: [alpha.trycarbide.com](https://alpha.trycarbide.com/) (Apple Notes) · [Project Sandcastle article](http://news.mit.edu/2016/project-sandcastle-student-startups-0919) · [flashfill made in Carbide](http://alpha.trycarbide.com/@bijection/e9ed452d261ff3741e61013a381555e6)
- natto.dev: [natto.dev](https://natto.dev/) (Apple Notes, three cards) · [a @geoffrey canvas](https://natto.dev/@geoffrey/f6f27f2e9cf24e18b6d303539fa35e59) · [Prototyping a Logo environment inside natto.dev](https://www.youtube.com/watch?v=XmS0QGan_Qs) (Apple Notes → Youtube links) · [launch tweet](https://twitter.com/_paulshen/status/1370402539720503298): JS panes on a 2D canvas, the idea closest to Fizzygum's desktop, but hosted and closed
- MathTerm (a screenshot in the vault only): a local React app, source unknown

**Needs TiddlyWiki**
- [tiddly-gittly/zx-script](https://github.com/tiddly-gittly/zx-script) · [site](https://tiddly-gittly.github.io/zx-script/) · ["jupyter tiddlywiki" search](https://www.google.co.uk/search?q=jupyter+tiddlywiki) (Apple Notes)

**Gone**
- [randya.dev/js-notebook](https://randya.dev/js-notebook/): returns 404 (Apple Notes card "JS Notebook")

## How this was found

**Sources.** Apple Notes: the text of all 4,926 notes and all 3,609 saved link URLs were searched;
the notebook links there are link cards with no images. Vault: all ~30,300 Markdown notes were
searched by keyword and tag (`#algebriteNotebookSystem`, `#algebriteUses`, `#stoic`…). Text inside
vault images was not read, so an image-only note with no telling title or tag could be missed; about
ten screenshots were checked by eye.

**Images.** Scratch.js, javascript-notebook (live page) and Tangle were screenshotted in headless
Chrome on 2026-11-24 by `shoot.js` and `shoot2.js` (in `Fizzygum-tests/.scratch/notebook-research/`,
gitignored). The phi example comes from the javascript-notebook repo, Chalkboard and Math Notepad
from the owner's vault, and the paper page from its PDF.
