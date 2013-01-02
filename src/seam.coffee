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

_constrain_to_rect = (rect) ->
  (x, y) ->
    max_x = rect.getWidth() - Constants.SPACING
    max_y = rect.getHeight() - Constants.SPACING
    x = Math.max(x, 0)
    y = Math.max(y, 0)
    x = Math.min(x, max_x)
    y = Math.min(y, max_y)
    [x, y]

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
    @native.set_reactive(true)

    @native.connect 'button-press-event', =>
      Util.Log('derp real seam was clicked')

  wasAddedAsChild: (to) ->
    @parent.native.set_child_above_sibling(@drag.native, @native)



ClutterSeam::_non_native_init = DomSeam::_non_native_init = (parent, idx) ->
  @parent = parent
  @index = idx
  @drag = DRAG_CONTROLLER.makeDraggable(this, [_constrain_to_direction(parent.format)
                                               _constrain_to_rect(parent)])
  # event handler for drag ending
  @drag.dragEnd = (shadow) =>

    [before_new_ratio, after_new_ratio] = @parent.ratioAround(shadow.getX(), shadow.getY())

    before_prev_ratio = 0
    for rect in @parent.managed_windows[0..@index]
      before_prev_ratio += @parent.ratioOf(rect)
    after_prev_ratio = 1 - before_prev_ratio

    before_diff = before_new_ratio - before_prev_ratio
    after_diff = after_new_ratio - after_prev_ratio

    before_rect = @parent.managed_windows[@index]
    after_rect = @parent.managed_windows[@index + 1]

    @setX shadow.getX()
    @setY shadow.getY()

    before_rect.needs_layout = after_rect.needs_layout = true
    before_rect.ratio += before_diff
    after_rect.ratio += after_diff

    Util.Log("before.ratio = #{before_rect.ratio}, after.ratio = #{after_rect.ratio}, sum = #{before_rect.ratio + after_rect.ratio}")

    @parent.layoutRecursive()


# Write to global scope
if Util.is_gjs()
  Seam = ClutterSeam
else
  Seam = DomSeam
