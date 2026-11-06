// coffee-mask.js — label each character of a CoffeeScript line as code, string or comment.
//
// maskLine(line, state) -> { mask, state }: mask[i] is 'code', 'str' or 'cut' (a `#` comment to the end
// of the line); `state` carries an open multi-line string (""" ''' `) into the next line (pass null for
// a file's first line). Strings are only LABELLED, never deleted, so a caller can keep string CONTENT
// while still cutting comments, and can tell "inside a string" from "code" — a census that must see
// name-string dispatch needs exactly that. A `#` inside a string ("#{x}") is string, not comment.
//
// Readers: census-public-private-calls.js (R4's src harvest; it re-exports maskLine for
// census-hierarchy-duplication.js, which compares method bodies with their string literals intact)
// and lib/tests-repo-code.js (the tests repo's code, the same reading).
//
// Stated limits (shared by every reader): a `###` block comment's inner lines read as code, and a
// "…" or '…' string left open at the end of a line ends there (CoffeeScript lets one span lines).

function maskLine(line, state) {
  const mask = new Array(line.length).fill('code');
  let i = 0;
  if (state) {
    const end = line.indexOf(state);
    if (end < 0) { mask.fill('str'); return { mask, state }; }
    for (let j = 0; j < end + state.length; j++) mask[j] = 'str';
    i = end + state.length;
    state = null;
  }
  while (i < line.length) {
    const three = line.substr(i, 3);
    if (three === '"""' || three === "'''") {
      const close = line.indexOf(three, i + 3);
      const stop = close < 0 ? line.length : close + 3;
      for (let j = i; j < stop; j++) mask[j] = 'str';
      if (close < 0) return { mask, state: three };
      i = stop; continue;
    }
    const c = line[i];
    if (c === '`' || c === '"' || c === "'") {
      let j = i + 1;
      while (j < line.length) {
        if (line[j] === '\\') { j += 2; continue; }
        if (line[j] === c) break;
        j++;
      }
      const stop = j >= line.length ? line.length : j + 1;
      for (let k = i; k < stop; k++) mask[k] = 'str';
      if (j >= line.length) return { mask, state: c === '`' ? '`' : null };  // unterminated: only ` spans lines
      i = stop; continue;
    }
    if (c === '#') { for (let j = i; j < line.length; j++) mask[j] = 'cut'; break; }
    i++;
  }
  return { mask, state };
}

// The line with its comment characters blanked (strings and code kept), so a word scan over it sees
// what the code names and nothing a comment says. Columns are preserved.
function codeOfCoffeeLine(line, state) {
  const { mask, state: next } = maskLine(line, state);
  let out = '';
  for (let k = 0; k < line.length; k++) out += mask[k] === 'cut' ? ' ' : line[k];
  return { code: out, state: next };
}

module.exports = { maskLine, codeOfCoffeeLine };
