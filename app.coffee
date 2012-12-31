# Set up library path
getCurrentFile = ->
  Gio = imports.gi.Gio

  # see http://stackoverflow.com/questions/10093102/how-to-set-a-including-path-in-the-gjs-code/14078345#14078345
  stack = (new Error()).stack

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

LIB = getCurrentFile()[1]
imports.searchPath.unshift(LIB)

# Libraries ##################################################################3
Region = imports.Mousetile.region
Clutter = imports.gi.Clutter
Mousetile = imports.Mousetile.Mousetile

# Constants ##################################################################
Util = Mousetile.Util
Constants = Mousetile.Util.Constants
W = 1920
H = 1080
C = Mousetile.Region

# Alternate between `true` and `false`
select_alternate = (initial) ->
  prev = ! initial
  return ->
    prev = ! prev
    return prev


# create a [Empty, [Empty, ...]] Tree
create_tree = (dir_selector, count) ->
  # base case: return a plain container
  if count == 0
    return new C(W, H)

  # reverse the direction
  root = new C(W, H, dir_selector())

  empty_child = new C(W, H)

  # sub-tree
  full_child = create_tree(dir_selector, count - 1)

  # add children
  root.addLast(empty_child)
  root.addLast(full_child)

  return root


layout_and_show = (tree) ->
  tree.each ->
    # @native.show()
    @layout()

# Event Handlers ##############################################################
key_pressed = (target, event) ->
  symbol = event.get_key_symbol()
  Mousetile.Util.Log(symbol)
  if symbol == Constants.KEYS.CTRL
    Mousetile.Draggable.CONTROLLER.enable()

key_released = (target, event) ->
  if event.get_key_symbol() == Constants.KEYS.CTRL
    Mousetile.Draggable.CONTROLLER.disable()

# Main ########################################################################
# Create a stage and run the demo
main = ->
  Clutter.init(null, null)

  # stage setup
  stage = Clutter.Stage.get_default()
  stage.title = "Mousetile Clutter Test"
  stage.set_size(W, H) #worksformewontfix

  # bind key handling to enable/disable draggables
  stage.connect('key-press-event', key_pressed)
  stage.connect('key-release-event', key_released)

  tree = create_tree(select_alternate(false), 10)
  tree.native.set_position(0, 0)
  stage.add_child(tree.native)

  layout_and_show(tree)

  # Test draggable
  parent = tree.managed_windows[1].managed_windows[1]
  target = parent.managed_windows[0]

  handle = Mousetile.Draggable.makeDraggable(target)
  parent.addChild(handle)

  # Set up drag controller events
  stage.connect('key-press-event', key_pressed)
  stage.connect('key-press-event', key_released)

  stage.show()
  Clutter.main()
  stage.destroy()

  Mousetile.Util.LogKeys(Clutter.keysyms)


# CHOO CHOO DO IT
main()


