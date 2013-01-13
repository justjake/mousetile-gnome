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

Color = imports.Mousetile.color

# Window Manager Libraries ####################################################
Layouts = imports.Mousetile.manager.layout
AssistantLib = imports.Mousetile.manager.assistant
# Constants ###################################################################
Util = Mousetile.Util
Constants = Mousetile.Util.Constants
W = 2000
H = W * Constants.GOLDEN
C = Mousetile.Region

class C extends Mousetile.Region
  @constructor: ->
    super()
    @connect 'window-added', =>
      @setColor()

Image = Mousetile.Image

# Alternate between `true` and `false`
select_alternate = (initial) ->
  prev = ! initial
  return ->
    prev = ! prev
    return prev


# create a [Empty, [Empty, ...]] Tree
# next_color = Color.native_series(Color.piet(15))
# next_color = Color.native_series(Color.tricolor(13))
# next_color = Color.native_series(Color.zenburn(15))
next_color = Color.native_series(Color.dark(13))

create_tree = (dir_selector, count) ->
  # base case: return a plain container
  if count == 0
    base = new C(W, H)
    base.setColor(next_color())
    return base

  # reverse the direction
  root = new C(W, H, dir_selector())

  empty_child = new C(W, H)
  empty_child.setColor(next_color())

  # sub-tree
  full_child = create_tree(dir_selector, count - 1)

  # add children
  root.addLast(empty_child)
  root.addLast(full_child)
  empty_child.ratio = 1 - Constants.GOLDEN
  full_child.ratio = 1 - empty_child.ratio

  return root


layout_and_show = (tree) ->
  tree.eachWindow (win) ->
    # @native.show()
    win.layout()



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
    Util.Log("disabling seams")
    SeamLib.DRAG_CONTROLLER.disableAll()
  manager.connect "drag-disabled", ->
    Util.Log("enabling seams")
    SeamLib.DRAG_CONTROLLER.enableAll()

  layout_and_show(tree)

  # try and use assistant
#  ast = new AssistantLib.Assistant()
#  root.addChild(ast)
#  [x, y] = RectLib.center(root, ast)
#  ast.setX Math.floor x
#  ast.setY Math.floor y

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


