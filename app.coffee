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

# Libraries ###################################################################
Logger    = imports.Mousetile.logger.exports
Constants = imports.Mousetile.constants.exports

SeamLib   = imports.Mousetile.seam.exports
RegionLib  = imports.Mousetile.region.exports
Color  = imports.Mousetile.color.exports

Clutter = imports.gi.Clutter

# Window Manager Libraries ####################################################
Layouts = imports.Mousetile.manager.layout
AssistantLib = imports.Mousetile.manager.assistant

# App Constants ###############################################################
W = 1000
H = W * Constants.GOLDEN

C = RegionLib.Region

# Alternate between `true` and `false`
select_alternate = (initial) ->
  prev = ! initial
  return ->
    prev = ! prev
    return prev

# color series - currently unusded
piet = Color.native_series(Color.piet(15))
tricolor = Color.native_series(Color.tricolor(13))
zenburn = Color.native_series(Color.zenburn(15))
dark = Color.native_series(Color.dark(13))

# create a [Empty, [Empty, ...]] Tree of depth `count`
create_tree = (dir_selector, depth, color_fn) ->
  # base case: return a plain container
  if depth == 0
    base = new C(W, H)
    base.setColor(color_fn()) if color_fn
    return base

  # reverse the direction
  root = new C(W, H, dir_selector())

  empty_child = new C(W, H)
  empty_child.setColor(color_fn()) if color_fn

  # sub-tree
  full_child = create_tree(dir_selector, depth - 1)

  # add children
  root.addLast(empty_child)
  root.addLast(full_child)
  empty_child.ratio = 1 - Constants.GOLDEN
  full_child.ratio = 1 - empty_child.ratio

  return root

# Main ########################################################################
# Create a stage and run the demo
main = ->
  Clutter.init(null, null)

  root = new Layouts.RootLayout(W, H)
  manager = new Layouts.LayoutController(root)

  tree = create_tree(select_alternate(true), 10)
  root.addChild(tree)
  manager.manage(tree)

  # toggle seams so we can drag parent windows
  manager.connect "drag-enabled", ->
    # Logger.Log("disabling seams")
    SeamLib.DRAG_CONTROLLER.disableAll()
  manager.connect "drag-disabled", ->
    # Logger.Log("enabling seams")
    SeamLib.DRAG_CONTROLLER.enableAll()

  tree.layoutRecursive(true)

  # Clutter setup
  # this sort of raw context wrangling is outside of Mousetile's scope

  # stage setup
  stage = Clutter.Stage.get_default()
  stage.title = "♥ Mousetile Clutter Test ♥"
  stage.set_size(W, H) #worksformewontfix

  # add root to the stage
  stage.add_child(root.native)
  root.native.grab_key_focus()

  stage.show()
  Clutter.main()
  stage.destroy()


# CHOO CHOO DO IT BITCHES
main()


