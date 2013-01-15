####
# Rectangles
# the building block of our layout system, and the only part
# that should know about the DOM
#
# TODO: make sure the css class .rect has:
#   position: absolute
#   box-sizing: border-box
# and optionally:
#   background: rgba(#f00, 0.1)
####

# GJS imports
Clutter = imports.gi.Clutter

# Libraries
Logger    = imports.Mousetile.logger.exports
Classes   = imports.Mousetile.classes.exports
Util      = imports.Mousetile.util.exports
Constants = imports.Mousetile.constants.exports

# Abstract class
class AbstractRect extends Classes.HasSignals
  NO_PARENT = Constants.NO_PARENT

  # Pre-mature signal adding. Does rect really need to emit?
  # signalsEmitted: ['resize', 'move']
  signalsEmitted: ['parent-changed']

  default_color: Constants.NativeColors.RECT_COLOR

  constructor: (width = 0, height = 0, x = 0, y = 0) ->
    super()
    @children = []
    @parent = NO_PARENT

    @width = null
    @height = null
    @x = null
    @y = null

    @setWidth(width)
    @setHeight(height)
    @setX(x)
    @setY(y)

    @setColor(@default_color) if @default_color

  # like toString, but with more info
  inspect: ->
    @toString() + "at [#{@getX()}, #{@getY()}] size [#{@getWidth()}, #{@getHeight()}]"

  # Child Management
  addChild: (rect) ->
    if rect.parent == this
      return # we already are in this struct

    # sanity check: disallow adding parents to descendends
    if @isAncestor(rect)
      throw new Error("Cannot add parent #{rect} as child of its descendent #{this}")

    # remove from previous location
    if rect.parent
      rect.parent.removeChild(rect)

    rect.setParent(this)
    @children.push(rect)
    @emitAndBubble('child-added', rect)


  removeChild: (rect) ->
    idx = @children.indexOf(rect)
    if idx != -1
      @children.splice(idx, 1)
      rect.setParent(NO_PARENT)
    else
      # throw new Error("InvalidRemoval: #{this} has no child #{rect}")
      Logger.Log("InvalidRemoval: #{this} has no child #{rect}")
    return rect # helpful

  eachChild: (fn) ->
    Util.traverse(this, ((rect) -> rect.children), fn)

  # Is rect an ancenstor of this object?
  isAncestor: (rect) ->
    parent = this.parent
    while parent
      if parent == rect
        return true
      parent = parent.parent
    false


  # Style

  setColor: (c) ->

  # Visibility
  show: ->
  hide: ->

  # PROPERTIES
  setParent: (new_p) ->
    @parent = new_p
    @emit('parent-changed', new_p)

  # property: width
  setWidth: (w) ->
    @width = w
    # @emit('resize', width: w)
  getWidth: ->
    @width

  # property: height
  setHeight: (h) ->
    @height = h
    # @emit('resize', height: h)
  getHeight: ->
    @height

  # property: x
  setX: (x) ->
    @x = x
    # @emit('move', x: x)
  getX: ->
    @x

  # property: y
  setY: (y) ->
    @y = y
    # @emit('move', y: y)
  getY: ->
    @y

###
  DomRect
  Base class for the window manager in Webkit interfaces
###
class DomRect extends AbstractRect

# first: helper functions for pixesls
  to_pixels = (n) -> n + "px"
  from_pixels = (px) ->
    parseInt(px[0..-3], 10)

  constructor: (width = 0, height = 0) ->
    el = document.createElement('div')
    el.className = 'rect'
    @native = el

    # calls to set width & height for us
    super(width, heigth)

  show: ->
    @native.style.display = ""
  hide: ->
    @native.style.display = "none"

  # Style
  setColor: (c) ->
    @native.style.backgroundColor = c


  # PROPERTIES

  # property: width
  setWidth: (w) ->
    @native.style.width = to_pixels(w)
  getWidth: ->
    from_pixels(@native.style.width)

  # property: height
  setHeight: (h) ->
    @native.style.height = to_pixels(h)
  getHeight: ->
    from_pixels @native.style.height

  # property: x
  setX: (x) ->
    @native.style.left = to_pixels(x)
  getX: ->
    from_pixels @native.style.left

  # property: y
  setY: (y) ->
    @native.style.top = to_pixels(y)
  getY: ->
    from_pixels @native.style.top


  # FUNCTIONS

  # child elements are tracked independently of the DOM
  addChild: (rect) ->
    @native.appendChild(rect.native)
    super(rect)

  removeChild: (rect) ->
    @native.removeChild(rect.native)
    super(rect)


###
  ClutterRect
  rectangle abstraction for Clutter/GJS use
  This is intended to be the base class for the Gnome Shell window manager
###
class ClutterRect extends AbstractRect

  # emits event name with x, y decoded from the native event
  mouse_event = (obj, to_emit) ->
    (_, event) ->
#      if to_emit == 'mouse-enter' or to_emit == 'mouse-leave'
#        Logger.Log("event #{to_emit} in #{obj}")
      [x, y] = event.get_coords()
      res = obj.emit(to_emit, x, y)
      if res == Constants.YES_STOP_EMITTING or res == Constants.DO_NOT_BUBBLE
        return true
      res

  key_event = (obj, to_emit) ->
    (_, event) ->
      sym = event.get_key_symbol()
      obj.emit(to_emit, sym)


  singnalsEmitted: [
    # layout structure
    # should be eliminated in favor of hygenic draggables
    'parent-changed'

    # Mouse
    'mouse-enter'
    'mouse-leave'
    'mouse-move'

    'mouse-down'
    'mouse-up'

    # key buttons
    'key-down'
    'key-up'

    # tree structure
    'child-added'
  ]

  constructor: (width = 0, height = 0) ->
    @native = new Clutter.Actor()
    @native.set_reactive(true)
    # equivalent to overflow: hidden;
    @native.set_clip_to_allocation(true)

    # Event Transformations ###################################################
    # mouse-enter
    @native.connect 'enter-event',  mouse_event(this,            'mouse-enter')
    @native.connect 'motion-event', mouse_event(this,            'mouse-move')
    @native.connect 'leave-event',  mouse_event(this,            'mouse-leave')

    # mouse buttons
    @native.connect 'button-press-event', mouse_event(this,      'mouse-down')
    @native.connect 'button-release-event', mouse_event(this,    'mouse-up')

    # key events
    @native.connect 'key-press-event', key_event(this,           'key-down')
    @native.connect 'key-release-event', key_event(this,         'key-up')


    super(width, height)

  # Child management

  addChild: (rect) ->
    @native.add_child(rect.native)
    super(rect)

  removeChild: (rect) ->
    @native.remove_child(rect.native)
    super(rect)

  setAboveSibling: (to_raise, sibling = {'native': null}) ->
    @native.set_child_above_sibling(to_raise.native, sibling.native)



  setColor: (c) ->
    @native.set_background_color(c)


  # Visibility
  show: ->
    @native.show()
  hide: ->
    @native.hide()

  # PROPERTIES
  # property: width
  setWidth: (w) -> @native.set_width(Util.int w)
  getWidth: -> @native.get_width()

    # property: height
  setHeight: (h) -> @native.set_height(Util.int h)
  getHeight: -> @native.get_height()

    # property: x
  setX: (x) -> @native.set_x(Util.int x)
  getX: -> @native.get_x()

    # property: y
  setY: (y) -> @native.set_y(Util.int y)
  getY: -> @native.get_y()


# choose which one should be Rect
#if (window?)
#  # Write it directly to the window for now
#  # TODO: require style BS? Function wrapper with `exports`?
#  Rect = DomRect
#else
#  # woot woot here we go with GJS
#  Rect = ClutterRect
Rect = ClutterRect

# Functions on rect ###########################################################

center = (big, small) ->
  x = (big.getWidth() - small.getWidth()) / 2
  y = (big.getHeight() - small.getHeight()) / 2

  x += big.getX()
  y += big.getY()

  return [x, y]

# translate the x,y pair from the child's coordinate system to the parent's coordinate system
parent_coord = (child, x, y) ->
  return [child.getX() + x, child.getY() + y]

deparent_coord = (child, x, y) ->
  return [x - child.getX(), y - child.getY()]

# Get the rect's X and Y in the top-most coordinate space
global_position = (rect) ->
  x = 0
  y = 0
  r = rect
  while r.parent isnt null
    x += r.getX()
    y += r.getY()
    r = r.parent
  [x, y]


# get all the children of a rect (including itself)
is_child_of = (rect) ->
  res = []
  rect.eachChild (r) ->
    res.push(r)

  return res

# Exports #####################################################################
exports = {
  # classes
  AbstractRect: AbstractRect # useful for low-impact rects
  DomRect:      DomRect
  ClutterRect:  ClutterRect
  Rect:         Rect

  # functions
  center:          center

  parent_coord:    parent_coord
  deparent_coord:  deparent_coord

  global_position: global_position
}
