addLogDiv = ->
  # this "log" div shows info a) while loading all the source files and then
  # b) while compiling and evaluating them. Useful to give some feedback as these
  # can take in order of 10s of seconds. This div is removed after the last
  # log to it
  loadingLogDiv = document.createElement 'div'
  loadingLogDiv.id = 'loadingLog'
  loadingLogDiv.style.position = 'absolute'
  loadingLogDiv.style.width = "960px"
  loadingLogDiv.style.backgroundColor = "rgb(245, 245, 245)"
  loadingLogDiv.style.top = "0px"
  loadingLogDiv.style.top = "0px"
  document.getElementsByTagName('body')[0].appendChild(loadingLogDiv)

removeLogDiv = ->
  loadingLogDiv = document.getElementById 'loadingLog'
  loadingLogDiv?.parentElement.removeChild loadingLogDiv

emptyLogDiv = ->
  loadingLogDiv = document.getElementById 'loadingLog'
  loadingLogDiv?.innerHTML = ""

addLineToLogDiv = (content) ->
  loadingLogDiv = document.getElementById 'loadingLog'
  loadingLogDiv?.innerHTML += content + "</br>"
