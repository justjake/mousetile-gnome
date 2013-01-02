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

  signalsEmitted: ['drag-start', 'drag-motion', 'drag-end']

  constructor: (to_clone) ->
    # Clone target position
    super(to_clone.getWidth(), to_clone.getHeight())
    @setX(to_clone.getX())
    @setY(to_clone.getY())

    to_clone.parent.addChild(this) if to_clone.parent
    to_clone.connect 'parent-changed', (_, new_parent) =>
      Util.Log("#{to_clone.parent}, #{new_parent}, #{@parent}")
      new_parent.addChild(this)

    Util.runAlso('setWidth', to_clone, this)
    Util.runAlso('setHeight', to_clone, this)

    Util.runAlso('setX', to_clone, this)
    Util.runAlso('setY', to_clone, this)



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
    coords = [x, y]
    for c in @constraints
      coords = c.apply(this, coords)
    return coords

  # Generic mouse handling functions
  # params should be mouse x and y
  mouseDown: (x, y) ->
    if @grabMouse?
      @grabMouse()
    if not @mouse_is_down
      @mouse_is_down = true
      @drag_prev_coords = [x, y]

      # event
      @emit('drag-start', x, y)

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
      @emit('drag-motion', new_x, new_y)

      [new_x, new_y]
    else
      false

  mouseUp: (x, y) ->
    if @ungrabMouse?
      @ungrabMouse()

    if @mouse_is_down
      @mouse_is_down = false
      @drag_start = null

      @emit('drag-end', x, y)

class ClutterDragShadow extends AbstractDragShadow
  constructor: (to_clone) ->
    super(to_clone)
    @native.set_background_color(Util.Constants.DRAG_COLOR)

    # respond to events
    @native.set_reactive(true)

    # reorder so this is on top
    to_clone.connect 'parent-changed', (_, new_parent) =>
      Util.Log("#{to_clone.parent}, #{new_parent}, #{@parent}")
      new_parent.native.set_child_above_sibling(@native, to_clone.native)

    # bind event signals
    @native.connect 'button-press-event', (n, event) =>
      [x, y] = event.get_coords()
      @mouseDown(x, y)

    @native.connect 'motion-event', (n, event) =>
      [x, y] = event.get_coords()
      @mouseMove(x, y)

    @native.connect 'button-release-event', (n, event) =>
      [x, y] = event.get_coords()
      @mouseUp(x, y)

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
