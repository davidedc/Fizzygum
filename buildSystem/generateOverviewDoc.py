#!/usr/bin/env python

try:
	import argparse
	ap = 1
except ImportError:
	import optparse
	ap = 0

import os
import tempfile
import sys
import re

COMMON_FILES = [
'docs/overview/headerDoc.txt',
'src/FrameMorph.coffee',
'src/InspectorMorph.coffee',
'src/MorphicNode.coffee',
'src/Morph.coffee',
'src/WorldMorph.coffee',
'src/HandMorph.coffee',
'src/BouncerMorph.coffee',
'src/MenuMorph.coffee',
'src/ListMorph.coffee',
'src/globalFunctions.coffee',
'src/HandleMorph.coffee',
'src/SliderButtonMorph.coffee',
'src/SliderMorph.coffee',
'src/ScrollFrameMorph.coffee',
'src/TextMorph.coffee',
'src/StringMorph.coffee',
'src/SpeechBubbleMorph.coffee',
'src/BoxMorph.coffee',
'src/CircleBoxMorph.coffee',
'src/Rectangle.coffee',
'src/Point.coffee',
'src/PenMorph.coffee',
'src/MorphsListMorph.coffee',
'src/TriggerMorph.coffee',
'src/MenuItemMorph.coffee',
'src/CursorMorph.coffee',
'src/Color.coffee',
'src/StringFieldMorph.coffee',
'src/GrayPaletteMorph.coffee',
'src/ColorPickerMorph.coffee',
'src/ColorPaletteMorph.coffee',
'src/globalSettings.coffee',
'src/morphicVersion.coffee',
'src/BlinkerMorph.coffee',
'src/MouseSensorMorph.coffee',
'src/ShadowMorph.coffee',
]

def merge(files):

	buffer = []

	for filename in files:
		with open(os.path.join('..', '', filename), 'r') as f:
			buffer.append(f.read())

	return "".join(buffer)


def filterOverviewDocComments(files):

	text = merge(files)
	text = re.split(r"\n+",text)

	outfile = open('../docs/overview/filteredCommentsForReadableStandaloneDoc.md','w')
	
	pattern = re.compile('\s*#\| (.*)')
	
	for line in text:
		found = pattern.match(line)
		if found:
			outfile.write("\n"+found.group(1))
	outfile.write("\n"+line)
	outfile.close()



def main(argv=None):
	filterOverviewDocComments(COMMON_FILES)

if __name__ == "__main__":
	main()
