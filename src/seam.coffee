####
# Seams - goes in the empty space between container ports
####

#=require "util"
#=require "rect"


# Local libraries
Util = imports.Mousetile.util
Constants = Util.Constants
Draggable = imports.Mousetile.draggable

RectLib = imports.Mousetile.rect
Rect = RectLib.Rect

DRAG_CONTROLLER = new Draggable.DraggableController()
DRAG_CONTROLLER.enableAll()

_constrain_to_direction = (dir = Constants.HORIZONTAL) ->
  (x, y) ->
    if dir == Constants.HORIZONTAL
      return [x, 0]
    else
      return [0, y]

class DomSeam extends RectLib.DomRect
  constructor: (container_parent, first_index = 0) ->
    super(0,0)
    # add seam  class to native representation
    @native.className += " seam"



class ClutterSeam extends RectLib.ClutterRect
  constructor: (container_parent, first_index = 0) ->
    super(0,0)
    @_non_native_init(container_parent, first_index)
    @native.set_background_color(Util.Constants.SEAM_COLOR)



ClutterSeam::_non_native_init = DomSeam::_non_native_init = (parent, idx) ->
  @parent = parent
  @index = idx
  @drag = DRAG_CONTROLLER.makeDraggable(this, [_constrain_to_direction(parent.format)])


# Write to global scope
if Util.is_gjs()
  Seam = ClutterSeam
else
  Seam = DomSeam
