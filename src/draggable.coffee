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
    # Util.Log "Controller #{this} managed #{drg}"
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

  signalsEmitted: ['drag-start', 'drag-motion', 'drag-end']

  constructor: (to_clone) ->
    # Clone target position
    super(to_clone.getWidth(), to_clone.getHeight())

    to_clone.addChild(this)

    Util.runAlso('setWidth', to_clone, this)
    Util.runAlso('setHeight', to_clone, this)

    # this object has instance methods with the same name as events.
    # there is no magic here - we have to hook up the methods as usual.
    # I think this makes sense -- we still use the events system, but subclasses
    # can easily override the behavior
    @connect 'mouse-down', (_, x, y) =>
      @mouseDown(
        x, y
      )

    @connect 'mouse-up', (_, x, y) =>
      @mouseUp(
        x, y
      )

    @connect 'mouse-move', (_, x, y) =>
      @mouseMove(x, y)

    @binding = to_clone

    @constraints = []

    @mouse_is_down = false
    @drag_prev_coords = null


  # Constraint functions are (x,y) coorinate filters
  # they are run in the order they are added, mapping the x, y points
  # they can be used either for drag rate reduction
  # or just to constrain x, y to be in certain ranges
  addConstrain: (c) ->
    @constraints.push(c)

  applyConstrains: (x, y) ->
    # transform the local x, y (which is WITHIN the object we marked as draggable)
    # to the coordinate system used by the object-to-be-dragged
    coords = RectLib.parent_coord(@parent, x, y)
    for c in @constraints
      coords = c.apply(this, coords)
    return RectLib.deparent_coord(@parent, coords...)

  # Generic mouse handling functions
  # params should be mouse x and y
  mouseDown: (x, y) ->
    if @grabMouse?
      @grabMouse()
    if not @mouse_is_down
      @mouse_is_down = true
      @drag_prev_coords = [x, y]

      # event
      @emit('drag-start', RectLib.parent_coord(@parent, @getX(), @getY())...)

      return Constants.YES_STOP_EMITTING

  mouseMove: (x, y) ->
    if @mouse_is_down
      delta_x = x - @drag_prev_coords[0]
      delta_y = y - @drag_prev_coords[1]
      desired_x = delta_x + @getX()
      desired_y = delta_y + @getY()
      [new_x, new_y] = @applyConstrains(desired_x, desired_y)
      @setX new_x
      @setY new_y

      # only update drag loc if that coordinate was valid
      # intended to prevent mouse-out-of-dragger becoming a long invisible leash
      @drag_prev_coords[0] = x if new_x == desired_x
      @drag_prev_coords[1] = y if new_y == desired_y

      # event
      @emit('drag-motion', RectLib.parent_coord(@parent, new_x, new_y)...)

      [new_x, new_y]
      return Constants.YES_STOP_EMITTING

  mouseUp: (x, y) ->
    if @ungrabMouse?
      @ungrabMouse()

    if @mouse_is_down
      @mouse_is_down = false
      @drag_start = null

      # events are emitted in the draggable object's coordinate space
      # instead of its nested-child space
      @emit('drag-end', RectLib.parent_coord(@parent, @getX(), @getY())...)

      # re-center shadow
      @setX 0
      @setY 0

      return Constants.YES_STOP_EMITTING

class ClutterDragShadow extends AbstractDragShadow
  constructor: (to_clone) ->
    super(to_clone)
    @native.set_background_color(Util.Constants.DRAG_COLOR)

    # respond to events
    @native.set_reactive(true)

  grabMouse: ->
    Clutter.grab_pointer(@native)
  ungrabMouse: ->
    Clutter.ungrab_pointer()





if Util.is_gjs()
  DragShadow = ClutterDragShadow
else
  DragShadow = DomDragShadow

# exports namespace
exports = {}
exports.makeDraggable = makeDraggable
exports.DragShadow = DragShadow
