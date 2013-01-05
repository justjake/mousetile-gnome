####
# Utilities
# Especially getters/setters
####

Gio = imports.gi.Gio

is_gjs = -> # this function makes no sense: GSJ can't reach this before using GJS imports
  true # TODO: make is_gjs a thing

# Constants
Constants = {

  DEBUG: true

  # layout directions
  VERTICAL: false
  HORIZONTAL: true

  # which side when targeting an actor
  BEFORE: true
  AFTER: false

  # size of splitters
  SPACING: 9

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
    red:   0
    green: 0
    blue:  0
    alpha: 255
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
  # see http://stackoverflow.com/questions/10093102/how-to-set-a-including-path-in-the-gjs-code/14078345#14078345
  stack = (new Error()).stack

  stackLine = stack.split('\n')[1]
  if not stackLine
    throw new Error('Could not find current file')

  match = new RegExp('@(.+):(\\d+)').exec(stackLine)
  if not match
    throw new Error('Could not find current file')

  path = match[1]
  file = Gio.File.new_for_path(path)
  return {
    path: file.get_path()
    dirname: file.get_parent().get_path()
    basename: file.get_basename()
    line_number: match[2]
  }


require = (path) ->
  names = path.split('/')
  cur = imports
  for n in names
    cur = cur[n]
  return cur


# Logging #####################################################################
Log = ->
  if is_gjs()
    out = ""
    for x in arguments
      out += x
    log(out)
  else
    console.log.apply(console, arguments)

LogGroup = ->
  if is_gjs()
    Log("/-#{arguments[0]}---")
    Log.apply(null, arguments)
  else
    console.group.apply(console, arguments)

LogGroupEnd = ->
  if is_gjs()
    Log("----/")
  else
    console.groupEnd()

LogKeys = (obj) ->
  for k, _ of obj
    Log(k)

# Binding tools ###############################################################

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

# pass through function calls to a delegate objects' methods
proxy = (local, remote, methods...) ->
  for method in methods
    local[method] = -> remote[method].apply(remote, arguments)


# Sanity checks ###############################################################

assert = (desc, fn_or_condition) ->
  if typeof fn_or_condition == "Function"
    res = fn_or_condition()
  else
    res = fn_or_condition
  if res is false
    Util.Log("Failed assertion '#{desc}': #{fn_or_condition.toString()}")


# Basic Classes ###############################################################
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


###
  Signals
  -----------------------------------------------------------------------------
  this is an implementation of a GTK/GObject style signals system.

  these signals are arbitrary non-bubbling events that can be connected to any
  number of listening functions.

  This is mostly just a coffeescript port of gjs-1.0/signals.js

  Objects extending HasSignals may optionally specify an array of valid signal
  names in thier prototype with @signalsEmitted. If you object emits "drag-start",
  "drag-end" and "drag-motion" then you should have
###
class HasSignals extends Id

# Class Methods #############################################################

  @extend = (obj) ->
    obj.connect = HasSignals::connect
    obj.disconnect = HasSignals::disconnect
    obj.disconnectAll = HasSignals::disconnect
    obj.emit = HasSignals::emit

  # Connection Management #####################################################

  connect: (name, callback) ->
    # Only allow functions as callbacks
    if typeof callback != 'function'
      throw new TypeError("must connect signal to a function")

    if @signalsEmitted?
      if not name in @signalsEmitted
        Util.Log("Connecting undeclared signal #{name} on #{this}")

    # add signal internals only if someone is listening
    if not @_signals?
      @_signals = {
      connections: []
      nextId: 1
      # TODO: faster then gjs-1.0's simple signals array?
      # more hashmaps, maybe?
      }

    id = @_signals.nextId
    @_signals.nextId += 1

    sig_struct = {
      'id': id
      'name': name
      'callback': callback
      'disconnected': false
    }

    ###
    Iterating through all the signals on each emission is
    O(n), but the Gnome developers wanted to keep things light-weight and
    avoid memory overhead. On the web we'll be contending with Internet
    Explorer, so maybe we should change this to signal-name-specific type
    arrays
    ###
    @_signals.connections.push(sig_struct)

    # Util.Log("connect: on #{name} do #{callback}")

    return id

  disconnect: (id) ->
    if @_signals?
      for c in @_signals.connections
        if c.id == id
          if c.disconnected
            throw new Error("Signal handler id #{id} was already disconnected")

          # the disconnected flag is for removal during signal emission
          # herp derp coffeescript loops make this ugly and slow
          @_signals.connections.splice(i, @_signals.connections.indexOf(c))

          return

    throw new Error("No signal connection with id #{id} found")

  disconnectAll: ->
    if @_signals?
      for c in @_signals.connections
        @disconnect(c.id)

  # Signal Emission ###########################################################

  emit: (name, args...) ->

    if @signalsEmitted?
      if not name in @signalsEmitted
        Util.Log("emit: emitting undeclared signal named #{name}")

    # No listeners, no actions taken
    if not @_signals?
      return

    # filter to deal with just this signal
    # creating this local handlers array also deals with removal/addition while
    # emitting
    connections = (c for c in @_signals.connections when c.name == name)

    call_args = [this].concat(args)

    for handler in connections
      if not handler.disconnected
        if Constants.DEBUG
          res = handler.callback.apply(null, call_args)
          return undefined if res == false # stop emitting on false from handler
        else
          try
            res = handler.callback.apply(null, call_args)
            return undefined if res == false # stop emitting on false from handler
          catch err
            Util.Log("Error in callback for signal #{name} on #{this}")
            Util.Log(err.stack) if err.stack



# Library Normalization #######################################################
# This is what the lib looks like when use from GJS

exports = {
  Constants: Constants

  # Logging
  Log: Log
  LogGroup: LogGroup
  LogGroupEnd: LogGroupEnd
  LogKeys: LogKeys


  # Classes
  Id: Id
  Set: Set
  HasSignals: HasSignals

  # Functions
  is_gjs: is_gjs
  runAlso: runAlso
  bindRemoteFunction: bindRemoteFunction
  assert: assert
}