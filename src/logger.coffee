
IS_GJS = true

# Logging #####################################################################
Log = ->
  if IS_GJS
    out = ""
    for x in arguments
      out += x + " "
    log(out)
  else
    console.log.apply(console, arguments)

LogGroup = ->
  if IS_GJS
    Log("/-#{arguments[0]}---")
    Log.apply(null, arguments)
  else
    console.group.apply(console, arguments)

LogGroupEnd = ->
  if IS_GJS
    Log("----/")
  else
    console.groupEnd()

LogKeys = (obj) ->
  for k, _ of obj
    Log(k)


# Exports #####################################################################
exports = {
  Log:         Log
  LogGroup:    LogGroup
  LogGroupEnd: LogGroupEnd
  LogKeys:     LogKeys
}
