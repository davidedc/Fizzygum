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
'src/CloseCircleButtonMorph.coffee',
'src/Rectangle.coffee',
'src/Point.coffee',
'src/PenMorph.coffee',
'src/MorphsListMorph.coffee',
'src/TriggerMorph.coffee',
'src/MenuItemMorph.coffee',
'src/CaretMorph.coffee',
'src/Color.coffee',
'src/StringFieldMorph.coffee',
'src/GrayPaletteMorph.coffee',
'src/ColorPickerMorph.coffee',
'src/ColorPaletteMorph.coffee',
'src/PreferencesAndSettings.coffee',
'src/BlinkerMorph.coffee',
'src/MouseSensorMorph.coffee',
'src/ShadowMorph.coffee',
'src/AutomatorRecorderAndPlayer.coffee',
]

def merge(files):

	buffer = []

	for filename in files:
		with open(os.path.join('..', '', filename), 'r') as f:
			buffer.append(f.read())

	return "".join(buffer)


def filterOverviewDocComments(files):


	outfile = open('../docs/overview/filteredCommentsForReadableStandaloneDoc.md','w')
	for line in open('../docs/overview/headerDoc.md'):
		outfile.write("\n"+line)
	outfile.write("\n\n")
	outfile.close()

	# This part was meant to include in the overview document
	# a little snippet of the beginning comments of each
	# class, marked with a particular #| style
	# But the styling is crap and the generated API is good enough
	# so I'm taking that away.

	#text = merge(files)
	#text = re.split(r"\n+",text)
	#outfile2 = open('../docs/overview/filteredCommentsForReadableStandaloneDoc.md','a')
	
	#pattern = re.compile('\s*#\| (.*)')

	
	#for line in text:
	#	found = pattern.match(line)
	#	if found:
	#		outfile2.write("\n"+found.group(1))
	#outfile2.write("\n"+line)
	#outfile2.close()



def main(argv=None):
	filterOverviewDocComments(COMMON_FILES)

if __name__ == "__main__":
	main()
