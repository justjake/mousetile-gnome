# Global libraries
Lang = imports.lang
Clutter = imports.gi.Clutter

# Local libraries
Util = imports.Mousetile.util
RectLib = imports.Mousetile.rect
Rect = RectLib.Rect

# DraggableController #########################################################
# activates and de-activates all the drag shadows
class DraggableController
  constructor: ->
    @draggables = []
    @can_drag = false

  enable: ->
    @can_drag = true
    for d in @draggables
      d.show()

  disable: ->
    @can_drag = false
    for d in @draggables
      d.hide()

# global instance
CONTROLLER = new DraggableController()

# Make an object dragable. Fires the objects dragEnd event function
# when dragging stops

# Currently implemented with shadow draggables: instead of actually
# dragging the object, create a copy and drag that
makeDraggable  = (obj, constraints...) ->
  shadow = new DragShadow(obj)
  for c in constraints
    shadow.addConstrain(c)
  CONTROLLER.draggables.push(shadow)

  if Util.is_gjs()
    _clutterMakeDraggable(obj, shadow)
  else
    _domMakeDraggable(obj)

  return shadow

# Env-specific implementations ###################################
_clutterMakeDraggable = (obj, shadow) ->
  obj.native.set_reactive(true)



# DragShadow ##################################################################

class AbstractDragShadow extends Rect
  constructor: (to_clone) ->
    # Clone target position
    super(to_clone.getWidth(), to_clone.getHeight())
    @setX(to_clone.getX())
    @setY(to_clone.getY())

    @binding = to_clone

    @constraints = []

  addConstrain: (c) ->
    @constrains.push(c)

  applyConstrains: (x, y) ->
    coords = [x, y]
    for c in @constrains
      coords = c.apply(this, coords)

    return coords

  # method stubs
  dragBegin: -> Util.Log('Drag began', arguments...)
  dragMotion: -> Util.Log('Drag moved', arguments...)
  dragEnd: ->
    Util.Log('Drag ended', arguments...)
    # call event with new x and y
    if @binding.dragEnd?
      @binding.dragEnd(@getX(), @getY())

class ClutterDragShadow extends AbstractDragShadow
  constructor: (to_clone) ->
    super(to_clone)
    @native.set_background_color(Util.Constants.DRAG_COLOR)
    # enable dragging
    @drag_action = new Clutter.DragAction()

    @native.add_action(@drag_action)
    @native.set_reactive(true)

    @drag_action.connect('drag-begin', Lang.bind(this, @dragBegin))
    @drag_action.connect('drag-end', Lang.bind(this, @dragEnd))
    @drag_action.connect('drag-motion', Lang.bind(this, @dragMotion))


if Util.is_gjs()
  DragShadow = ClutterDragShadow
else
  DragShadow = DomDragShadow

# exports namespace
exports = {}
exports.makeDraggable = makeDraggable
exports.DragShadow = DragShadow
