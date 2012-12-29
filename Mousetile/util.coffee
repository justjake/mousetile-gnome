####
# Utilities
# Especially getters/setters
####

# Constants
Constants = {
  # layout directions
  VERTICAL: false
  HORIZONTAL: true

  # which side when targeting an actor
  BEFORE: true
  AFTER: false

  # size of splitters
  SPACING: 5

  # Parenting
  NO_PARENT: null
}

# Library Management
is_gjs = -> # this function makes no sense: GSJ can't reach this before using GJS imports
  (imports? and not window?)

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


# Getters and setters using {get: ->, set: ->} maps
Function::property = (prop_name, fns) ->
    Object.defineProperty(@prototype, prop_name, fns)

# toString support with UUIDs
class Id
    uuid_counter = 0
    uuid = ->
        uuid += 1

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
