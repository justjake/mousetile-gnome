####
# Utilities
# Especially getters/setters
####

is_gjs = -> # this function makes no sense: GSJ can't reach this before using GJS imports
  true # TODO: make is_gjs a thing

# Constants
Constants = {
  # layout directions
  VERTICAL: false
  HORIZONTAL: true

  # which side when targeting an actor
  BEFORE: true
  AFTER: false

  # size of splitters
  SPACING: 7

  # Parenting
  NO_PARENT: null

  KEYS: {
    CTRL: 65507
    ALT: 65513
  }
}


if is_gjs()
  # Add global colors for GJS
  Clutter = imports.gi.Clutter
  Constants.MAIN_COLOR = new Clutter.Color {
    red: 0
    green: 0
    blue: 255
    alpha: 15
  }
  Constants.SEAM_COLOR = new Clutter.Color {
    red: 255
    green: 0
    blue: 0
    alpha: 15
  }
  Constants.DRAG_COLOR = new Clutter.Color {
    red: 255
    green: 255
    blue: 0
    alpha: 50
  }

  # Library Management
  # get the root GJS entry file
  getCurrentFile = ->
    Gio = imports.gi.Gio

    # see http://stackoverflow.com/questions/10093102/how-to-set-a-including-path-in-the-gjs-code/14078345#14078345
    stack = (ner Error()).stack

    stackLine = stack.split('\n')[1]
    if not stackLine
      throw new Error('Could not find current file')

    match = new RegExp('@(.+):\\d+').exec(stackLine)
    if not match
      throw new Error('Could not find current file')

    path = match[1]
    file = Gio.File.new_for_path(path)
    return [
      file.get_path()
      file.get_parent().get_path()
      file.get_basename()
    ]

  require = (path) ->
    names = path.split('/')
    cur = imports
    for n in names
      cur = cur[n]
    return cur


# Logging
Log = ->
  if is_gjs()
    for x in arguments
      log(x)
  else
    console.log.apply(console, arguments)

LogGroup = ->
  if is_gjs()
    Log("/-#{arguments[0]}--------------------------------------------------------")
    Log.apply(null, arguments)
  else
    console.group.apply(console, arguments)

LogGroupEnd = ->
  if is_gjs()
    Log("---------------------------------------------------------/")
  else
    console.groupEnd()

LogKeys = (obj) ->
  for k, _ of obj
    Log(k)

# Getters and setters using {get: ->, set: ->} maps
Function::property = (prop_name, fns) ->
    Object.defineProperty(@prototype, prop_name, fns)

# Property indirection tools
# Run an additional function each time a method is called
bindRemoteFunction = (obj, fn_name, run_also) ->
  old_fn = obj[fn_name]
  obj[fn_name] = ->
    run_also.apply(this, arguments)
    old_fn.apply(this, arguments)

# Run the local object's method whenever the remote object's method is called
runAlso = (fn_name, remote, local) ->
  bindRemoteFunction remote, fn_name, ->
    local[fn_name].apply(local, arguments)


# toString support with UUIDs
class Id
    uuid_counter = 0
    uuid = ->
        uuid_counter += 1

    constructor: ->
        @_id = uuid()

    toString: ->
        "#{@constructor.name}<#{@_id}>"

class Set extends Id
    constructor: (arr) ->
        super()
        @_set = {}

        for x in arr
            @add(x)

        return this

    add: (x) ->
        if @contains(x)
            return false
        @_set[x] = true

    remove: (x) ->
        if not contains(x)
            return false
        delete @_set[x]

    contains: (x) ->
        @_set[x] == true

# TODO subclass Array to use for Container.managed_windows
# because we need a way to make sure no window is in two places at once

# This is what the lib looks like when use from GJS
Util = {
  Constants: Constants

  # Logging
  Log: Log
  LogGroup: LogGroup
  LogGroupEnd: LogGroupEnd
  LogKeys: LogKeys


  # Classes
  Id: Id
  Set: Set

  # Functions
  is_gjs: is_gjs
  runAlso: runAlso
  bindRemoteFunction: bindRemoteFunction
}