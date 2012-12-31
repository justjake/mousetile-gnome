# Global libraries
Lang = imports.lang
Clutter = imports.gi.Clutter

# Local libraries
Util = imports.Mousetile.util
RectLib = imports.Mousetile.rect
Rect = RectLib.Rect

SPECIAL_AGENCY_KEY = Util.Constants.KEYS.CTRL

# DraggableController #########################################################
# activates and de-activates all the drag shadows
class DraggableController extends Util.Id
  constructor: ->
    super()
    @draggables = []
    @can_drag = false

  makeDraggable: (obj, constraints = []) ->
    shadow = new DragShadow(obj)
    @manage(shadow)
    for c in constraints
      shadow.addConstrain(c)

    # GJS event activation
    if Util.is_gjs()
      obj.native.set_reactive(true)

    return shadow

  manage: (drg) ->
    Util.Log "Controller #{this} managed #{drg}"
    @draggables.push(drg)
    if @can_drag
      @enable(drg)
    else
      @disable(drg)


  enable: (drg) ->
    drg.show()

  disable: (drg) ->
    drg.hide()

  enableAll: ->
    for d in @draggables
      @enable(d)
    @can_drag = true

  disableAll: ->
    for d in @draggables
      @disable(d)
    @can_drag = false

# global instance
DefaultController = new DraggableController()

# Make an object dragable. Fires the objects dragEnd event function
# when dragging stops

# Currently implemented with shadow draggables: instead of actually
# dragging the object, create a copy and drag that
makeDraggable  = (obj, constraints = []) ->
  DefaultController.makeDraggable(obj, constraints)



# DragShadow ##################################################################

class AbstractDragShadow extends Rect
  constructor: (to_clone) ->
    # Clone target position
    super(to_clone.getWidth(), to_clone.getHeight())
    # this is now a child of the cloned obj, so we default to 0,0: Directly over the parent
#    @setX(to_clone.getX())
#    @setY(to_clone.getY())

    to_clone.addChild(this)
    shadow_ref = this

    clone_set_x = to_clone.setX
    to_clone.setX = (x) ->
      clone_set_x.call(this, x)
      shadow_ref.setX(x)

    clone_set_y = to_clone.setY
    to_clone.setY = (y) ->
      clone_set_y.call(this, y)
      shadow_ref.setY(y)


    clone_set_y = to_clone.setY

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
  dragBegin: ->
    # Set @drag_start here
  dragMotion: ->
  dragEnd: ->
    # call event with new x and y
    if @binding.dragEnd?
      @binding.dragEnd(@getX(), @getY())
    # reset position
    @setX 0;
    @setY 0;

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
