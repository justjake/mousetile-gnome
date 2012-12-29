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

Util = imports.Mousetile.util
Region = imports.Mousetile.region
Clutter = imports.gi.Clutter

W = 600
H = 600
C = Region.Region

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
    @native.show()
    @layout()

# Create a stage and run the demo
main = ->
  Clutter.init(null, null)

  stage = Clutter.Stage.get_default()
  stage.title = "Mousetile Clutter Test"

  tree = create_tree(select_alternate(true), 5)
#  tree = new C(50, 50)
  tree.native.set_position(20, 20)
#  tree.native.set_width(50)
#  tree.native.set_height(50)
  stage.add_child(tree.native)

  layout_and_show(tree)

  stage.show()
  Clutter.main()
  stage.destroy()


# CHOO CHOO DO IT
main()


