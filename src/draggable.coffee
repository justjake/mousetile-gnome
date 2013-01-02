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

  # method stubs
  dragBegin: ->
    # Set @drag_start here
  dragMotion: ->
    [new_x, new_y] = @applyConstrains(@getX(), @getY())
    @setX new_x
    @setY new_y
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

  dragMotion: (action, actor, delta_x, delta_y, data) ->
    # Clutter 1.12.2 has 'drag-progress' which you can return false to to cancel that atomic drag movement
    # We're supporting Clutter 1.10 becuase that's what Ubuntu 12.04 runs
    # so we have to do signal emission plumbing
    # see http://developer.gnome.org/clutter/1.10/ClutterDragAction.html#ClutterDragAction--x-drag-threshold

    Util.Log("action: #{action}, actor: #{actor}, data: #{data}")
    # TODO figure out how to stop event emission by name
    # cause this won't work
    # we'll need to import gobject
    GObject.signal_stop_emission_by_name(action, 'drag-motion')
    # dont call super here
    intended_x = @getX() + delta_x
    intended_y = @getY() + delta_y
    [x, y] = @applyConstrains(intended_x, intended_y)
    # this math is hard
    # TODO solve problem, time to sleep
    new_dx = intended_x - x
    new_dy = intended_y - y
    @native.move_by(new_dx, new_dy)


if Util.is_gjs()
  DragShadow = ClutterDragShadow
else
  DragShadow = DomDragShadow

# exports namespace
exports = {}
exports.makeDraggable = makeDraggable
exports.DragShadow = DragShadow
