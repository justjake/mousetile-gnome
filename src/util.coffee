
IS_GJS = true # TODO: build system defines this

###
  Utilities
  -----------------------------------------------------------------------------
  All the little things that don't make sense elsewhere.
  Most of this is cruft that isn't being used.
  # TODO: remove unused functions
###

EPSILON = 0.000001

type = (obj) ->
  obj.constructor

# prototype of a GJS require shim
require = (path) ->
  names = path.split('/')
  cur = imports
  for n in names
    cur = cur[n]
  return cur.exports

# Data Structure Tools #######################################################

# creates a new aray with `arr`'s items in a random order
shuffle = (arr) ->
  out = []
  while arr.length
    idx = Math.min(Math.floor(Math.random() * arr.length), arr.length - 1)
    out.push(
      arr.splice(idx, 1)[0]
    )
  out

# run fn on all items in tree
# get_next_items will be called on tree
# it should return an array of items to recursively traverse
traverse = (tree, get_next_items, fn) ->
  fn(tree)
  items = get_next_items(tree)
  for i in items
    traverse(i, get_next_items, fn)

# Number Tools ################################################################

int = (n) -> Math.floor(n)

# comparison with epsilon
almost_equals = (a, b, epsilon = EPSILON) ->
  Math.abs(a - b) < epsilon

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
    throw new Error("Failed assertion '#{desc}': #{fn_or_condition.toString()}")


# Exports #####################################################################

exports = {
  require: require

  # class tools
  type: type

  # Number tools
  int: int
  almost_equals: almost_equals

  # data structure tools
  traverse: traverse
  shuffle:  shuffle

  # binding tools. do I even use these? answer: no
  bindRemoteFunction: bindRemoteFunction
  runAlso: runAlso
  proxy: proxy

  # sanity: also frighteningly unused
  assert: assert
}