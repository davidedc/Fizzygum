# Holds information about browser and machine
# Note that some of these could
# change during user session.

class SystemInfo

  userAgent: null
  screenWidth: null
  screenHeight: null
  screenColorDepth: null
  screenPixelRatio: null
  appCodeName: null
  appName: null
  appVersion: null
  cookieEnabled: null
  platform: null
  systemLanguage: null

  constructor: ->
    @userAgent = navigator.userAgent
    @screenWidth = window.screen.width
    @screenHeight = window.screen.height
    @screenColorDepth = window.screen.colorDepth
    @screenPixelRatio = window.devicePixelRatio
    @appCodeName = navigator.appCodeName
    @appName = navigator.appName
    @appVersion = navigator.appVersion
    @cookieEnabled = navigator.cookieEnabled
    @platform = navigator.platform
    @systemLanguage = navigator.systemLanguage
