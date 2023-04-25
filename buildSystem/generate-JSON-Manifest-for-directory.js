#!/usr/bin/node

// This script recursively traverses a directory and outputs a
// JSON object with the following structure:
// {
//   "dir1": {
//     "subDirs": ["subDir1", "subDir2"],
//     "files": ["file1", "file2"]
//   }
// where you can exclude directories matching some patterns,
// and include only files matching some other patterns.
//
// This is useful to generate "manifest" json files that show the
// content and structure of a directory
//
// examples:
//   node generate-JSON-Manifest-for-directory.js Fizzygum -no-dirs-matching 'js,latest,website,git,tests,modules,auxiliary' -only-files-matching '\.coffee' --no-empty-dirs --include-top-level-dir-name

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const directory = args[0];
const filterOutPatterns = args.includes('-no-dirs-matching') ? args[args.indexOf('-no-dirs-matching') + 1].split(',') : [];
const filterInPatterns = args.includes('-only-files-matching') ? args[args.indexOf('-only-files-matching') + 1].split(',') : [];
const includeEmptyDirs = !args.includes('--no-empty-dirs');
const includeTopLevelDirName = !args.includes('--include-top-level-dir-name');
const result = {};

function shouldDiscardDir(dirName) {
  return filterOutPatterns.some(pattern => dirName.match(pattern));
}

function shouldIncludeFile(fileName) {
  return filterInPatterns.some(pattern => fileName.match(pattern));
}

function visitDirectory(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const subDirs = entries.filter(entry => entry.isDirectory());
  const files = entries.filter(entry => entry.isFile());

  const filteredSubDirs = subDirs.filter(subDir => !shouldDiscardDir(subDir.name));
  const filteredFiles = files.filter(file => shouldIncludeFile(file.name));

  if (includeEmptyDirs || filteredFiles.length > 0) {
    var dirInJSON = includeTopLevelDirName ? path.basename(path.resolve((dir))) + "/" + dir : dir;
    result[dirInJSON] = {
      subDirs: filteredSubDirs.map(subDir => subDir.name),
      files: filteredFiles.map(file => file.name)
    };
  }

  filteredSubDirs.forEach(subDir => {
    visitDirectory(path.join(dir, subDir.name));
  });
}

visitDirectory(directory);

console.log(JSON.stringify(result, null, 2));