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

Util = imports.Mousetile.util

# Abstract class
class AbstractRect extends Util.Id
  NO_PARENT = Util.Constants.NO_PARENT

  constructor: (width = 0, height = 0) ->
    super()
    @children = []
    @parent = NO_PARENT

    @setWidth(width)
    @setHeight(height)

  # Child Management
  addChild: (rect) ->
    rect.parent = this
    @children.push(rect)

  removeChild: (rect) ->
    idx = @children.indexOf(rect)
    if idx != -1
      delete @children[idx]
      rect.parent = NO_PARENT
    else
      throw "InvalidRemoval: #{this} has no child #{rect}"
    return rect # helpful

  # PROPERTIES

  # property: width
  setWidth: (w) ->
  getWidth: ->

  # property: height
  setHeight: (h) ->
  getHeight: ->

  # property: x
  setX: (x) ->
  getX: ->

  # property: y
  setY: (y) ->
  getY: ->

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
    super(rect)
    @native.appendChild(rect.native)

  removeChild: (rect) ->
    super(rect)
    @native.removeChild(rect.native)


###
  ClutterRect
  rectangle abstraction for Clutter/GJS use
  This is intended to be the base class for the Gnome Shell window manager
###
class ClutterRect extends AbstractRect

  # GJS imports
  Clutter = imports.gi.Clutter

  constructor: (width = 0, height = 0) ->
    @native = new Clutter.Actor()
    @native.set_background_color(Util.Constants.MAIN_COLOR)
    super(width, height)

  # Child management

  addChild: (rect) ->
    super(rect)
    @native.add_child(rect.native)

  removeChild: (rect) ->
    super(rect)
    @native.remove_child(rect.nativek)


  # PROPERTIES
  # property: width
  setWidth: (w) -> @native.set_width(w)
  getWidth: -> @native.get_width()

    # property: height
  setHeight: (h) -> @native.set_height(h)
  getHeight: -> @native.get_height()

    # property: x
  setX: (x) -> @native.set_x(x)
  getX: -> @native.get_x()

    # property: y
  setY: (y) -> @native.set_y(y)
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
