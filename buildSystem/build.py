#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
This script performs only some of the steps of the build:

1) generates an ordered list of the coffee files, so the order respects the
   dependencies between the files.

2) For each class file (not all of the coffee files are class files), it adds
   a special string that contains the source of the file itself.  This is so we
   can allow some editing of the classes in coffeescript, and do something like
   generating the documentation on the fly.

3) Combines the "extended" coffee files.  Note that 2) is a bit naive
   because we just do some simple string checks. So, there could be strings in
   the source code that mangle this process. It's not likely though.

4) Generates an index html file that also includes all the tests, which
   are javascripts in a special directory

The order in which the files are combined does matter.  There are three cases
where order matters:

1) if class A extends class B, then B needs to be before class A. This
   dependency can be figured out automatically (although at the moment in
   a sort of naive way) by looking at the source code.

2) no objects of a class can be instantiated before the definition of the
   class. This dependency can be figured out automatically (although at the
   moment in a sort of naive way) by looking at the source code.

3) some classes use global functions or global variables. These dependencies
   must be manually specified by creating a specially formatted comment.

"""

# These are included in order to make the script compatible both
# with Python 2 and 3.
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals
from __future__ import absolute_import

# standard library's imports
from collections import OrderedDict
from datetime import datetime
from glob import glob
import codecs
import re
import os
import ntpath

# to find the multiple js test files
# recursively in the src/tests folder
import fnmatch

# GLOBALS
FINAL_OUTPUT_FILE = '../Zombie-Kernel-builds/latest/delete_me/zombie-kernel.coffee'

STRING_BLOCK = \
"""  @coffeeScriptSourceOfThisClass: '''
%s  '''
"""

DIRECTORY_WITH_TEST_FILES = "../Zombie-Kernel-tests/tests/"
FILE_TO_BE_ADDED_TEST_INCLUDES = "src/index.html"
OUTPUT_FILE_WITH_TEST_INCLUDES = "../Zombie-Kernel-builds/latest/worldWithSystemTestHarness.html"

# RegEx Patterns
# We precompile them in order to improve performance and increase
# code readability
REQUIRES = re.compile(r"\sREQUIRES\s*(\w+)")
EXTENDS = re.compile(r"\sextends\s*(\w+)")
DEPENDS = re.compile(r"\s\w+:\s*new\s*(\w+)")
IS_CLASS = re.compile(r"\s*class\s+(\w+)")
TRIPLE_QUOTES = re.compile(r"'''")

# These two functions search for "requires" comments in the
# files and generate a list of the order in which the files
# should be combined. Basically creates a directed graph
# and creates the list making sure that the dependencies
# are respected.


def generate_inclusion_order(dependencies):
    """
    Returns a list of the coffee files. The list is ordered in such a way  that
    the dependencies between the files are respected.

    :param dict dependencies:

    """
    inclusion_order = []
    nodes = OrderedDict()
    filenames = list(dependencies.keys())

    for filename, requirements in dependencies.items():
        required_paths = []
        requirements = list(OrderedDict.fromkeys(requirements))
        for req in requirements:
            # convert class names to file paths
            class_filename = "/%s.coffee" % req

            for f in filenames:
                if class_filename in f:
                    required_paths.append(f)

        nodes[filename] = dict(requires=required_paths, visited=False)

    for filename in nodes.keys():
        visit(filename, nodes, inclusion_order)

    return inclusion_order


def visit(filename, nodes, inclusion_order):
    """
    :param str filename:
    :param dict nodes:
    :param list inclusion_order:

    """
    node = nodes[filename]
    if not node["visited"]:
        node["visited"] = True
        for other_filename in node["requires"]:
            visit(other_filename, nodes, inclusion_order)

    if filename not in inclusion_order:
        inclusion_order.append(filename)

def generateHTMLFileIncludingTests(testsDirectory, srcHTMLFile, destHTMLFile):
    # create a list with the test files
    # src/tests/
    # filenames = sorted(glob(testsDirectory + "*.js"))


    # creating the manifest for the tests ------------------------------------
    # which only includes the test steps and not the
    # assets, so it's one js file for each test
    filenames2 = []
    for root, dirnames, fileNMS in os.walk("../Zombie-Kernel-tests/tests/"):
      for filename in fnmatch.filter(fileNMS, 'SystemTest_*[!0123456789][!0123456789][!0123456789][!0123456789][!0123456789][!0123456789][!0123456789].js'):
          filename = filename[:-3] # remove the last three chars i.e. the ".js" extension
          filenames2.append(os.path.join(filename))
          print("%s" % (filename))
    filenames2 = sorted(filenames2)

    manifest = "if (!SystemTestsRecorderAndPlayer.hasOwnProperty('testsManifest')) { SystemTestsRecorderAndPlayer.testsManifest = []; }"

    for filename in filenames2:
        manifest = manifest + "SystemTestsRecorderAndPlayer.testsManifest.push('"+ntpath.basename(filename)+"');"

    # 'build/indexWithTests.html'
    with codecs.open("../Zombie-Kernel-builds/latest/js/tests/testsManifest.js", "w", "utf-8") as f:
        f.write(manifest)
    # -------------------------------------------------------------------------

    # creating the manifest for the tests ASSETS ------------------------------------
    # which only includes the test steps and not the
    # assets, so it's one js file for each test
    filenames2 = []
    for root, dirnames, fileNMS in os.walk("../Zombie-Kernel-tests/tests/"):
      for filename in fnmatch.filter(fileNMS, 'SystemTest_*[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789].js'):
          filename = filename[:-3] # remove the last three chars i.e. the ".js" extension
          filenames2.append(os.path.join(filename))
          print("%s" % (filename))
    filenames2 = sorted(filenames2)

    manifest = "if (!SystemTestsRecorderAndPlayer.hasOwnProperty('testsAssetsManifest')) { SystemTestsRecorderAndPlayer.testsAssetsManifest = []; }"

    for filename in filenames2:
        manifest = manifest + "SystemTestsRecorderAndPlayer.testsAssetsManifest.push('"+ntpath.basename(filename)+"');"

    # 'build/indexWithTests.html'
    with codecs.open("../Zombie-Kernel-builds/latest/js/tests/testsAssetsManifest.js", "w", "utf-8") as f:
        f.write(manifest)
    # -------------------------------------------------------------------------

    '''
    filenames = []
    for root, dirnames, fileNMS in os.walk(testsDirectory):
      for filename in fnmatch.filter(fileNMS, '*.js'):
          filenames.append(os.path.join(filename))
    filenames = sorted(filenames)

    # create the string with the js inclusions for each
    # test
    target = ""
    target = target + '<script type="text/javascript" src="js/tests/testsManifest.js"></script>'
    for filename in filenames:
        target = target + '<script type="text/javascript" src="js/tests/'+ntpath.basename(filename)+'"></script>'

    '''
    target =  '<script type="text/javascript" src="js/tests/testsManifest.js"></script>\n'
    target =  target + '<script type="text/javascript" src="js/tests/testsAssetsManifest.js"></script>'

    # put the tests inclusion in the right place

    # 'src/index.html'
    with codecs.open(srcHTMLFile, "r", "utf-8") as f:
        content = f.read()

    lines = content.split('\n')

    src = "<!--include test scripts here-->"

    replacedContent = ""
    for line in lines:
        replacedContent = replacedContent + line.replace(src, target) + "\n"

    # 'build/indexWithTests.html'
    with codecs.open(destHTMLFile, "w", "utf-8") as f:
        f.write(replacedContent)


def main():
    """
    Creates an ordered list of the coffee files, iterates through it, reads the
    source code of each file and combines them all into one final output file.
    """
    dependencies = OrderedDict()

    # create a list with the coffeescript files
    filenames = sorted(glob("src/*.coffee"))

    # Read each file and search it for each sort of dependency.
    for filename in filenames:
        dependencies[filename] = list()
        with open(filename, "r") as f:
            lines = f.readlines()

        for line in lines:
            matches = EXTENDS.search(line)
            if matches:
                dependencies[filename].append(matches.group(1))
                print("%s extends %s" % (filename, matches.group(1)))

            matches = REQUIRES.search(line)
            if matches:
                dependencies[filename].append(matches.group(1))
                print("%s requires %s" % (filename, matches.group(1)))

            matches = DEPENDS.search(line)
            if matches:
                dependencies[filename].append(matches.group(1))
                print("%s has class init in instance variable %s" %
                      (filename, matches.group(1)))

    # Generate inclusion order and print it
    inclusion_order = generate_inclusion_order(dependencies)
    print("Order /////////////////")
    for filename in inclusion_order:
        print(filename)

    # now iterate through the files and create the giant final *.coffee file.
    text = []
    for filename in inclusion_order:
        # open file and read its contents
        with codecs.open(filename, "r", "utf-8") as f:
            content = f.read()
        text.append(content)

        # if the file is a class, then we add its source code in the giant
        # *.coffee file as a static variable (string block).
        # We check if the file is a class by searching its contents for a
        # class ... declaration.
        is_class_file = IS_CLASS.search(content)
        if is_class_file:
            # If there is a string block in the source, then we must escape it.
            escaped_content = re.sub(TRIPLE_QUOTES, "\\'\\'\\'", content)
            text.append(STRING_BLOCK % escaped_content)

    # add the morphic version. This is used in the about box.
    time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    text.append("morphicVersion = 'version of %s'" % time)

    #concatenate text to a huge string.
    text = str.join(str("\n"), text)

    # write to disk
    if not os.path.exists(os.path.dirname(FINAL_OUTPUT_FILE)):
        os.makedirs(os.path.dirname(FINAL_OUTPUT_FILE))
    with codecs.open(FINAL_OUTPUT_FILE, "w", "utf-8") as f:
        f.write(text)

    # 4) a new HTML file is generated which also contains
    # all the loading of the test files
    generateHTMLFileIncludingTests(
            DIRECTORY_WITH_TEST_FILES,
            FILE_TO_BE_ADDED_TEST_INCLUDES,
            OUTPUT_FILE_WITH_TEST_INCLUDES)


if __name__ == "__main__":
    main()
