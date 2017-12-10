# Holds information about browser and machine
# Note that some of these could
# change during user session.

class SystemInfo

  userAgent: nil
  screenWidth: nil
  screenHeight: nil
  screenColorDepth: nil
  screenPixelRatio: nil
  appCodeName: nil
  appName: nil
  appVersion: nil
  cookieEnabled: nil
  platform: nil
  systemLanguage: nil

  browser: nil
  browserVersion: nil
  mobile: nil
  os: nil
  osVersion: nil
  cookies: nil

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

    
    # code here is from "JavaScript Client Detection"
    # (C) viazenetti GmbH (Christian Ludwig)

    unknown = '-'
    #browser
    nVer = navigator.appVersion
    nAgt = navigator.userAgent
    browser = navigator.appName
    version = '' + parseFloat navigator.appVersion
    majorVersion = parseInt navigator.appVersion, 10
    nameOffset = undefined
    verOffset = undefined
    ix = undefined
    # Opera
    if (verOffset = nAgt.indexOf 'Opera') != -1
      browser = 'Opera'
      version = nAgt.substring verOffset + 6
      if (verOffset = nAgt.indexOf 'Version') != -1
        version = nAgt.substring verOffset + 8
    else if (verOffset = nAgt.indexOf 'MSIE') != -1
      browser = 'Microsoft Internet Explorer'
      version = nAgt.substring verOffset + 5
    else if (verOffset = nAgt.indexOf 'Chrome') != -1
      browser = 'Chrome'
      version = nAgt.substring verOffset + 7
    else if (verOffset = nAgt.indexOf 'Safari') != -1
      browser = 'Safari'
      version = nAgt.substring verOffset + 7
      if (verOffset = nAgt.indexOf 'Version') != -1
        version = nAgt.substring verOffset + 8
    else if (verOffset = nAgt.indexOf 'Firefox') != -1
      browser = 'Firefox'
      version = nAgt.substring verOffset + 8
    else if nAgt.indexOf('Trident/') != -1
      browser = 'Microsoft Internet Explorer'
      version = nAgt.substring(nAgt.indexOf('rv:') + 3)
    else if (nameOffset = nAgt.lastIndexOf(' ') + 1) < (verOffset = nAgt.lastIndexOf('/'))
      browser = nAgt.substring nameOffset, verOffset
      version = nAgt.substring verOffset + 1
      if browser.toLowerCase() == browser.toUpperCase()
        browser = navigator.appName
    # trim the version string
    if (ix = version.indexOf ';') != -1
      version = version.substring 0, ix
    if (ix = version.indexOf ' ') != -1
      version = version.substring 0, ix
    if (ix = version.indexOf ')') != -1
      version = version.substring 0, ix
    majorVersion = parseInt '' + version, 10
    if isNaN majorVersion
      version = '' + parseFloat navigator.appVersion
      majorVersion = parseInt navigator.appVersion, 10
    # mobile version
    mobile = /Mobile|mini|Fennec|Android|iP(ad|od|hone)/.test(nVer)
    # cookie
    cookieEnabled = if navigator.cookieEnabled then true else false
    if typeof navigator.cookieEnabled == 'undefined' and !cookieEnabled
      document.cookie = 'testcookie'
      cookieEnabled = if document.cookie.indexOf('testcookie') != -1 then true else false
    # system
    os = unknown
    clientStrings = [
      {
        s: 'Windows 3.11'
        r: /Win16/
      }
      {
        s: 'Windows 95'
        r: /(Windows 95|Win95|Windows_95)/
      }
      {
        s: 'Windows ME'
        r: /(Win 9x 4.90|Windows ME)/
      }
      {
        s: 'Windows 98'
        r: /(Windows 98|Win98)/
      }
      {
        s: 'Windows CE'
        r: /Windows CE/
      }
      {
        s: 'Windows 2000'
        r: /(Windows NT 5.0|Windows 2000)/
      }
      {
        s: 'Windows XP'
        r: /(Windows NT 5.1|Windows XP)/
      }
      {
        s: 'Windows Server 2003'
        r: /Windows NT 5.2/
      }
      {
        s: 'Windows Vista'
        r: /Windows NT 6.0/
      }
      {
        s: 'Windows 7'
        r: /(Windows 7|Windows NT 6.1)/
      }
      {
        s: 'Windows 8.1'
        r: /(Windows 8.1|Windows NT 6.3)/
      }
      {
        s: 'Windows 8'
        r: /(Windows 8|Windows NT 6.2)/
      }
      {
        s: 'Windows NT 4.0'
        r: /(Windows NT 4.0|WinNT4.0|WinNT|Windows NT)/
      }
      {
        s: 'Windows ME'
        r: /Windows ME/
      }
      {
        s: 'Android'
        r: /Android/
      }
      {
        s: 'Open BSD'
        r: /OpenBSD/
      }
      {
        s: 'Sun OS'
        r: /SunOS/
      }
      {
        s: 'Linux'
        r: /(Linux|X11)/
      }
      {
        s: 'iOS'
        r: /(iPhone|iPad|iPod)/
      }
      {
        s: 'Mac OS X'
        r: /Mac OS X/
      }
      {
        s: 'Mac OS'
        r: /(MacPPC|MacIntel|Mac_PowerPC|Macintosh)/
      }
      {
        s: 'QNX'
        r: /QNX/
      }
      {
        s: 'UNIX'
        r: /UNIX/
      }
      {
        s: 'BeOS'
        r: /BeOS/
      }
      {
        s: 'OS/2'
        r: /OS\/2/
      }
      {
        s: 'Search Bot'
        r: /(nuhk|Googlebot|Yammybot|Openbot|Slurp|MSNBot|Ask Jeeves\/Teoma|ia_archiver)/
      }
    ]
    for id of clientStrings
      cs = clientStrings[id]
      if cs.r.test nAgt
        os = cs.s
        break
    osVersion = unknown
    if /Windows/.test(os)
      osVersion = /Windows (.*)/.exec(os)[1]
      os = 'Windows'
    switch os
      when 'Mac OS X'
        osVersion = /Mac OS X (10[\._\d]+)/.exec(nAgt)[1]
      when 'Android'
        osVersion = /Android ([\._\d]+)/.exec(nAgt)[1]
      when 'iOS'
        osVersion = /OS (\d+)_(\d+)_?(\d+)?/.exec(nVer)
        osVersion = osVersion[1] + '.' + osVersion[2] + '.' + (osVersion[3] | 0)

    @browser = browser
    @browserVersion = version
    @mobile = mobile
    @os = os
    @osVersion = osVersion
    @cookies = cookieEnabled
