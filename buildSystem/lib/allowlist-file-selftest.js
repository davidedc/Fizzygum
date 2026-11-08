'use strict';
// allowlist-file-selftest.js — the allowlist reader's cases (lib/allowlist-file.js), on a throwaway file: an entry
// with its reason, one with none, one whose reason holds a `#`, and the lines that hold no entry (blank, a comment);
// an absent file reads as no entries. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { readAllowlist } = require('./allowlist-file');
const t = require('./selftest-verdict').cases('allowlist-file');

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'allowlist-file-'));
const file = path.join(dir, 'x-allowlist.txt');
fs.writeFileSync(file, '# header comment\n\nwithReason   # a reason\nbare\n  indented  #  the reason has a # too\n   # an indented comment\n');
const got = readAllowlist(file);
t.check(JSON.stringify([...got]) === JSON.stringify([['withReason', 'a reason'], ['bare', ''], ['indented', 'the reason has a # too']]),
  'entries in file order, each with its reason ("" when none), comment and blank lines skipped', JSON.stringify([...got]));
t.check(readAllowlist(path.join(dir, 'absent.txt')).size === 0, 'an absent file reads as no entries');
fs.rmSync(dir, { recursive: true, force: true });
t.done();
