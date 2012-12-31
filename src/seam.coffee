####
# Seams - goes in the empty space between container ports
####

#=require "util"
#=require "rect"

# Global libraries
Lang =

# Local libraries
Util = imports.Mousetile.util
Draggable = imports.Mousetile.draggable

RectLib = imports.Mousetile.rect
Rect = RectLib.Rect

DRAG_CONTROLLER = new Draggable.DraggableController()
DRAG_CONTROLLER.enableAll()

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

  setWidth: (x) ->
    super(x)
    if @drag
      @drag.setWidth(x)

  setHeight: (x) ->
    super(x)
    if @drag
      @drag.setHeight(x)



ClutterSeam::_non_native_init = DomSeam::_non_native_init = (parent, idx) ->
  @parent = parent
  @index = idx
  @drag = DRAG_CONTROLLER.makeDraggable(this)


# Write to global scope
if Util.is_gjs()
  Seam = ClutterSeam
else
  Seam = DomSeam
