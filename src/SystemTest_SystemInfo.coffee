# Holds information about browser and machine
# Note that some of these could
# change during user session.

class SystemTest_SystemInfo extends SystemInfo
  # cannot just initialise the numbers here
  # cause we are going to make a JSON
  # out of this and these would not
  # be picked up.
  SystemTestsHarnessVersionMajor: null
  SystemTestsHarnessVersionMinor: null
  SystemTestsHarnessVersionRelease: null

  constructor: ->
    super()
    @SystemTestsHarnessVersionMajor = 0
    @SystemTestsHarnessVersionMinor = 1
    @SystemTestsHarnessVersionRelease = 0
