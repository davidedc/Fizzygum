set screenWidth to 1280
set screenHeight to 800
set pageRoot to "file:///Users/daviddellacasa/Fizzygum/"

set windows_number to 0

-- repeat -- repeat forever
set dialogResult to display dialog Â
	"Pick a mode" buttons {"9 squashed", "9 tiled", "close"} Â
	giving up after 536870910

if button returned of dialogResult is "9 squashed" then
	set numberOfTilesX to 3
	set numberOfTilesY to 3
	set absoluteDisplacementX to 20
	set windowSizeDivider to 2
	set displacementDueToWindowWidthX to 0
else if button returned of dialogResult is "9 tiled" then
	set numberOfTilesX to 3
	set numberOfTilesY to 3
	set absoluteDisplacementX to 0
	set windowSizeDivider to 1
	set displacementDueToWindowWidthX to 1
else if button returned of dialogResult is "close" then
	return
end if

set eachWindow_width to screenWidth / numberOfTilesX / windowSizeDivider
set eachWindow_height to screenHeight / numberOfTilesY / windowSizeDivider

set displacementDueToWindowWidthX to displacementDueToWindowWidthX * eachWindow_width

set numberOfWindows to numberOfTilesX * numberOfTilesY


repeat with tile_x from 1 to numberOfTilesX
	repeat with tile_y from 1 to numberOfTilesY
		
		tell application "Google Chrome"
			tell (make new window)
				set URL of active tab to (pageRoot & "Fizzygum-builds/latest/worldWithSystemTestHarness.html?startupActions=%7B%0D%0A++%22paramsVersion%22%3A+0.1%2C%0D%0A++%22actions%22%3A+%5B%0D%0A++++%7B%0D%0A++++++%22name%22%3A+%22runTests%22%2C%0D%0A++++++%22testsToRun%22%3A+%5B%22all%22%5D%2C%0D%0A++++++%22numberOfGroups%22%3A+9%2C%0D%0A++++++%22groupToBeRun%22%3A+" & windows_number & "%0D%0A++++%7D++%5D%0D%0A%7D")
				
				set posX to (tile_x - 1) * (displacementDueToWindowWidthX + absoluteDisplacementX)
				set posY to (tile_y - 1) * eachWindow_height
				set bounds to {Â
					posX, Â
					posY, Â
					posX + eachWindow_width, Â
					posY + eachWindow_height}
			end tell
			activate
		end tell
		set windows_number to windows_number + 1
		
	end repeat
end repeat
-- end repeat -- repeat forever


