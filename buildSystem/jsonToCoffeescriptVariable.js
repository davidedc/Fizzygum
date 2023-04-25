#!/usr/bin/node

// turns a JSON string in stdin into an assigned Coffeescript object in stdout
// i.e. something you can load/parse as .coffeescript (and eventually .js)
// e.g.:
//     echo '{"name": "May", "wins": []}' | node jsonToCoffeescriptVariable.js myData
// gives in stdout:
//     myData = {"name": "May", "wins": []}

const { readFileSync } = require('fs');
const inputData = readFileSync(0, 'utf-8');

const variableName = process.argv[2];
console.log(`${variableName} = ${inputData}`);