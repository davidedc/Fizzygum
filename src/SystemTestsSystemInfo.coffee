# Holds information about browser and machine
# Note that some of these could
# change during user session.

class SystemTestsSystemInfo extends SystemInfo
  # cannot just initialise the numbers here
  # cause we are going to make a JSON
  # out of this and these would not
  # be picked up.
  AutomatorVersionMajor: nil
  AutomatorVersionMinor: nil
  AutomatorVersionRelease: nil

  constructor: ->
    super()
    @AutomatorVersionMajor = 0
    @AutomatorVersionMinor = 2
    @AutomatorVersionRelease = 0
