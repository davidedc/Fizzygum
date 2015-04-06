set numberOfTilesX to 3
set numberOfTilesY to 3
set screenWidth to 1280
set screenHeight to 800
set pageRoot to "file:///Users/daviddellacasa/Zombie-Kernel/"

set eachWindow_width to screenWidth / numberOfTilesX
set eachWindow_height to screenHeight / numberOfTilesY
set numberOfWindows to numberOfTilesX * numberOfTilesY
set windows_number to 0

repeat with tile_x from 1 to numberOfTilesX
	repeat with tile_y from 1 to numberOfTilesY
		
		tell application "Google Chrome"
			tell (make new window)
				set URL of active tab to (pageRoot & "Zombie-Kernel-builds/latest/worldWithSystemTestHarness.html?startupActions=%7B%0D%0A++%22paramsVersion%22%3A+0.1%2C%0D%0A++%22actions%22%3A+%5B%0D%0A++++%7B%0D%0A++++++%22name%22%3A+%22runTests%22%2C%0D%0A++++++%22testsToRun%22%3A+%5B%22all%22%5D%2C%0D%0A++++++%22numberOfGroups%22%3A+9%2C%0D%0A++++++%22groupToBeRun%22%3A+" & windows_number & "%0D%0A++++%7D++%5D%0D%0A%7D")
				
				set bounds to {Â
					(tile_x - 1) * eachWindow_width, Â
					(tile_y - 1) * eachWindow_height, Â
					(tile_x - 1) * eachWindow_width + eachWindow_width, Â
					(tile_y - 1) * eachWindow_height + eachWindow_height}
			end tell
			activate
		end tell
		set windows_number to windows_number + 1
		
	end repeat
end repeat


