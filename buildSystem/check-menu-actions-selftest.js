'use strict';
// check-menu-actions-selftest.js — check-menu-actions.js proved able to BITE, by running the REAL gate (its class model,
// the boot install edges, the harness's installed members) on a planted copy of src/ and of the tests repo's harness
// (lib/planted-src.js). RULE 1: a function literal in a menu row's action slot fails (also behind a label holding `#`,
// and in a harness file, named harness/<path>, in a run of its own), and in a prompt's callback slot. RULE 1b: an `@`-targeted row
// and prompt naming a method NO class `@` could be defines fail. RULE 2: a string where the options object goes fails.
// RULE 3 — in a run of its own, since a hard violation exits before the ratchet — a menu verb with an unread
// parameter fails, and so does one whose signature WRAPS. The accepted forms ride the control: an action held in a
// variable, a verb defined only by a subclass, a harness member installed on the world, an options object (braced or
// implicit), a one-line verb reading its parameter after the arrow, parameters named `ignored`. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const cls = (name, parent, ...body) => [`class ${name} extends ${parent}`, ...body, ''].join('\n');
proveGate({
  name: 'check-menu-actions',
  gate: path.join(__dirname, 'check-menu-actions.js'),
  testsRepo: true,
  pass: /^\[menu-actions\] OK — \d+ menu-dispatched verb\(s\); \d+ `@`-targeted row\(s\) all resolve; 0 provably-wrong wirings; 0 unread parameter\(s\)/m,
  control: {
    plants: {
      'BiteProofMenuBaseWdgt.coffee': cls('BiteProofMenuBaseWdgt', 'Widget',
        '  bpWire: (menu) ->', '    verbName = "bpSomething"', '    menu.addMenuItem "bp", @, verbName',
        '    menu.addMenuItem "bp sub", @, "bpDefinedBySubclass"',
        '    menu.addMenuItem "bp opts", world, "bpOptsVerb", {toolTip: "x"}',
        '    menu.addMenuItem "bp implicit", world, "bpOptsVerb", toolTip: "x"',
        '    menu.addMenuItem "bp one", @, "bpOneLinerVerb"', '    menu.addMenuItem "bp ign", @, "bpIgnoringVerb"',
        '  bpOneLinerVerb: (menuItem) -> menuItem.bpMark()',
        '  bpIgnoringVerb: (ignored, ignored2, menuItem) ->', '    menuItem.bpMark()'),
      'BiteProofMenuSubWdgt.coffee': cls('BiteProofMenuSubWdgt', 'BiteProofMenuBaseWdgt', '  bpDefinedBySubclass: -> 1'),
      'BiteProofMenuWorldWdgt.coffee': cls('BiteProofMenuWorldWdgt', 'WorldWdgt', '  bpWire: (menu) ->', '    menu.addMenuItem "bp", @, "popUpSystemTestsMenu"'),
    },
  },
  runs: [{
    label: 'the hard rules, through both doors',
    plants: {
      'BiteProofMenuHardWdgt.coffee': cls('BiteProofMenuHardWdgt', 'Widget', '  bpWire: (menu) ->',
        '    menu.addMenuItem "bp fn", world, (-> 1)',
        '    @prompt "bp fn", world, (-> 1)',
        '    menu.addMenuItem "bp dead", @, "bpVerbNobodyDefines"',
        '    @prompt "bp dead", @, "bpCallbackNobodyDefines"',
        '    menu.addMenuItem "bp opts", world, "bpRuleTwoVerb", "a tooltip"',
        '    menu.addMenuItem "bp #1", world, (-> 1)'),
    },
    expect: {
      RULE_1_FUNCTION_ACTION: /^\[menu-actions\] RULE 1 FAIL — BiteProofMenuHardWdgt\.coffee:3$/m,
      RULE_1B_UNRESOLVED_ACTION: /^\[menu-actions\] RULE 1b FAIL — BiteProofMenuHardWdgt\.coffee:5$/m,
      RULE_2_STRING_OPTS: /^\[menu-actions\] RULE 2 FAIL — BiteProofMenuHardWdgt\.coffee:7$/m,
    },
    lines: [/^\[menu-actions\] RULE 1 FAIL — BiteProofMenuHardWdgt\.coffee:4$/m, /^\[menu-actions\] RULE 1b FAIL — BiteProofMenuHardWdgt\.coffee:6$/m,
      /^\[menu-actions\] RULE 1 FAIL — BiteProofMenuHardWdgt\.coffee:8$/m],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessMenuHardWdgt.coffee': cls('BiteProofHarnessMenuHardWdgt', 'Widget', '  bpWire: (menu) ->', '    menu.addMenuItem "bp fn", world, (-> 1)') },
    expect: { RULE_1_FUNCTION_ACTION: /^\[menu-actions\] RULE 1 FAIL — harness\/BiteProofHarnessMenuHardWdgt\.coffee:3$/m },
  }, {
    label: 'an unread parameter, a wrapped signature',
    plants: {
      'BiteProofMenuUnreadWdgt.coffee': cls('BiteProofMenuUnreadWdgt', 'Widget',
        '  bpWire: (menu) ->', '    menu.addMenuItem "bp", @, "bpMenuUnreadVerb"', '    menu.addMenuItem "bp wrapped", @, "bpWrappedVerb"',
        '  bpMenuUnreadVerb: (menuItem) ->', '    @bpX = 1',
        '  bpWrappedVerb: (', '    menuItem,', '    ignored', '  ) ->', '    @bpX = 2'),
    },
    expect: { RULE_3_UNREAD_PARAM: /^  BiteProofMenuUnreadWdgt\.coffee:5  bpMenuUnreadVerb  unread parameter `menuItem`$/m },
    lines: [/^  BiteProofMenuUnreadWdgt\.coffee:7  bpWrappedVerb  unread parameter `menuItem`$/m],
  }],
});
