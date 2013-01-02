# Global libraries
Lang = imports.lang
Clutter = imports.gi.Clutter
GObject = imports.gi.GObject

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

    Util.runAlso('setWidth', to_clone, this)
    Util.runAlso('setHeight', to_clone, this)

    @binding = to_clone

    @constraints = []

    @mouse_is_down = false
    @drag_start = null


  # Constraint functions are (x,y) coorinate filters
  # they are run in the order they are added, mapping the x, y points
  # they can be used either for drag rate reduction
  # or just to constrain x, y to be in certain ranges
  addConstrain: (c) ->
    @constraints.push(c)

  applyConstrains: (x, y) ->
    coords = [x, y]
    for c in @constraints
      coords = c.apply(this, coords)
    return coords

  # Generic mouse handling functions
  # params should be mouse x and y
  mouseDown: (x, y) ->
    if not @mouse_is_down
      @mouse_is_down = true
      @drag_start = [x, y]

  mouseMove: (x, y) ->
    delta_x = x - @drag_start[0]
    delta_y = y - @drag_start[1]
    [new_x, new_y] = @applyConstrains(delta_x + @getX(), delta_y + @getY())
    @setX new_x
    @setY new_y
    [new_x, new_y]

  mouseUp: (x, y) ->
    @mouse_is_down = false
    @drag_start = null

class ClutterDragShadow extends AbstractDragShadow
  constructor: (to_clone) ->
    super(to_clone)
    @native.set_background_color(Util.Constants.DRAG_COLOR)

    # respond to events
    @native.set_reactive(true)

    # bind event signals
    @native.connect 'button-press-event', (n, event) =>
      Util.Log("MouseDown at x: #{event.get_x()} y: #{event.get_y()}")
      @mouseDown(event.get_x(), event.get_y())

    @native.connect 'motion-event', (n, event) =>
      Util.Log("motion-event #{event}")
      [x, y] = event.get_coords()
      Util.Log("motion-event at x: #{x} y: #{y}")
      @mouseMove(event.get_x(), event.get_y())

    @native.connect 'button-release-event', (n, event) =>
      Util.Log("button-release-event at x: #{event.get_x()} y: #{event.get_y()}")
      @mouseMove(event.get_x(), event.get_y())





if Util.is_gjs()
  DragShadow = ClutterDragShadow
else
  DragShadow = DomDragShadow

# exports namespace
exports = {}
exports.makeDraggable = makeDraggable
exports.DragShadow = DragShadow
