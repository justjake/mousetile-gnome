###
  Classes
  -----------------------------------------------------------------------------
  Basic clases. Class `Id` is the root of our class hierarchy.
###

Logger    = imports.Mousetile.logger.exports
Constants = imports.Mousetile.constants.exports

## Class: Id
# Base class. Provides basic toString with an Id for all of our objects
# which both improves debugging in basic environments, and allows us to use
# our objects in `Set`
class Id
  uuid_counter = 0
  uuid = ->
    uuid_counter += 1

  constructor: ->
    @_id = uuid()

  toString: ->
    "#{@constructor.name}<#{@_id}>"


## Class: Set
# Quick and dirty set implementation.
# uses Javascript's native hash type, which is Hash<String:Any>, so if you
# store objects, they will be cast to string. Make sure they have unique
# string representations. Hint: this is why we use Id
class Set extends Id
  constructor: (arr = []) ->
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
        Logger.Log("Connecting undeclared signal #{name} on #{this}")

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

    # Logger.Log("connect: on #{name} do #{callback}")

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
        Logger.Log("emit: emitting undeclared signal named #{name}")

    # No listeners, no actions taken
    if not @_signals?
      return

    # filter to deal with just this signal
    # creating this local handlers array also deals with removal/addition while
    # emitting
    connections = (c for c in @_signals.connections when c.name == name)

    #
    if connections.length == 0
      return

    call_args = [this].concat(args)

    for handler in connections
      if not handler.disconnected
        if Constants.DEBUG

          res = handler.callback.apply(null, call_args)
          return Constants.YES_STOP_EMITTING if res == Constants.YES_STOP_EMITTING

        else
          # Event loop with error hanbdling
          try
            res = handler.callback.apply(null, call_args)
            return Constants.YES_STOP_EMITTING if res == Constants.YES_STOP_EMITTING
          catch err
            Logger.Log("Error in callback for signal #{name} on #{this}")
            Logger.Log(err.stack) if err.stack

    return res

  # emit this event, then emit the same event off of the parent if it goes unhandled
  emitAndBubble: (name, args...) ->
    res = @emit(name, args...)

    if @parent and (res != Constants.YES_STOP_EMITTING or res != Constants.DO_NOT_BUBBLE)
      @parent.emitAndBubble(name, args...)


# Exports #####################################################################

exports = {
  Id:         Id
  Set:        Set
  HasSignals: HasSignals
}