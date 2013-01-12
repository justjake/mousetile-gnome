# Set up library path
getCurrentFile = ->
  Gio = imports.gi.Gio

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

LIB = getCurrentFile().dirname
imports.searchPath.unshift(LIB)
imports.Mousetile.util.Constants.LOCATION = LIB

# Libraries ###################################################################
RectLib = imports.Mousetile.rect
Region = imports.Mousetile.region

SeamLib = imports.Mousetile.seam

Clutter = imports.gi.Clutter
Mousetile = imports.Mousetile.Mousetile

# Window Manager Libraries ####################################################
Layouts = imports.Mousetile.manager.layout
AssistantLib = imports.Mousetile.manager.assistant
# Constants ###################################################################
Util = Mousetile.Util
Constants = Mousetile.Util.Constants
W = 1200
H = 800
C = Mousetile.Region
Image = Mousetile.Image

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

all_children = (tree) ->
  res = []
  tree.each ->
    res.push(this)

  return res


# Event Handlers ##############################################################
key_pressed = (target, sym) ->
  Mousetile.Util.Log(sym)
  if sym == Constants.KEYS.CTRL
    Mousetile.Draggable.DefaultController.enableAll()

key_released = (target, sym) ->
  if sym == Constants.KEYS.CTRL
    Mousetile.Draggable.DefaultController.disableAll()

# Main ########################################################################
# Create a stage and run the demo
main = ->
  Clutter.init(null, null)

  root = new Layouts.RootLayout(W, H)
  manager = new Layouts.LayoutController(root)
  # bind key handling to enable/disable draggables
  root.connect('key-up', key_pressed)
  root.connect('key-down', key_released)

  tree = create_tree(select_alternate(false), 10)
  root.addChild(tree)
  for win in all_children(tree)
    manager.manage(win)

  # toggle seams so we can drag parent windows
  manager.connect "drag-enabled", ->
    SeamLib.DRAG_CONTROLLER.enableAll()
  manager.connect "drag-enabled", ->
    SeamLib.DRAG_CONTROLLER.disableAll()

  layout_and_show(tree)

  # try and use assistant
  ast = new AssistantLib.Assistant()
  root.addChild(ast)
  [x, y] = RectLib.center(root, ast)
  ast.setX Math.floor x
  ast.setY Math.floor y

  # Clutter setup

  # stage setup
  stage = Clutter.Stage.get_default()
  stage.title = "Mousetile Clutter Test"
  stage.set_size(W, H) #worksformewontfix

  # add root to the stage
  stage.add_child(root.native)
  root.native.grab_key_focus()

  stage.show()
  Clutter.main()
  stage.destroy()

  Mousetile.Util.LogKeys(Clutter.keysyms)


# CHOO CHOO DO IT
main()


