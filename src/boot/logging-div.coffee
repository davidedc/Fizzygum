addLogDiv = ->
  # this "log" div shows info while compiling and evaluating each source
  # file (one "compiling and evalling <name> (n/total)" line at a time).
  # Useful to give some feedback as this can take in order of 10s of
  # seconds. This div is removed after the last log to it
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
