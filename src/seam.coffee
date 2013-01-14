
IS_GJS = true # TODO: move to build system

####
# Seams - goes in the empty space between container ports
####



# Local libraries
Logger    = imports.Mousetile.logger.exports
Constants = imports.Mousetile.constants.exports
Draggable = imports.Mousetile.draggable.exports

RectLib = imports.Mousetile.rect.exports
Rect = RectLib.Rect

DRAG_CONTROLLER = new Draggable.DraggableController()
DRAG_CONTROLLER.enableAll()

_constrain_to_direction = (dir = Constants.HORIZONTAL) ->
  (x, y) ->
    if dir == Constants.HORIZONTAL
      return [x, 0]
    else
      return [0, y]

# TODO: constrain by default to just the space between the left and right rectangles
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
    @native.set_background_color(Constants.NativeColors.SEAM_COLOR)
    @native.set_clip_to_allocation(false)

    @native.connect 'button-press-event', =>
      Logger.Log('derp real seam was clicked')



ClutterSeam::_non_native_init = DomSeam::_non_native_init = (parent, idx) ->
  parent.addChild(this)
  @index = idx
  @drag = DRAG_CONTROLLER.makeDraggable(this,
    [_constrain_to_direction(parent.format), _constrain_to_rect(parent)])
  # RESIZE FUNCTION ###########################################################
  # event handler for drag ending
  @drag.connect 'drag-end', (shadow, x, y) =>
    # x,y pair is in the parent coordinate space already

    # set the seam's new coordinates
    @setX x
    @setY y


    # how much ratio space will be on each side of the seam's NEW location
    [before_new_ratio, after_new_ratio] = @parent.ratioAround(x, y)

    # accumulate the total ratio before the CURRENT seam location
    before_prev_ratio = 0
    for rect in @parent.managed_windows[0..@index]
      before_prev_ratio += @parent.ratioOf(rect)
    after_prev_ratio = 1 - before_prev_ratio

    # calculate ratio differences on either side of the seam -- how much
    #   ratio delta do we have?
    before_diff = before_new_ratio - before_prev_ratio
    after_diff = after_new_ratio - after_prev_ratio

    # TODO: behave respobsibly if there are more than 2 children in a region

    before_rect = @parent.managed_windows[@index]
    after_rect = @parent.managed_windows[@index + 1]

    # these rectangles are being resized, so kindly inform them...
    before_rect.needs_layout = after_rect.needs_layout = true

    # set new ratios
    # TODO adjust for more than 2 rectangles
    before_rect.ratio += before_diff
    after_rect.ratio += after_diff

    Logger.Log("before.ratio = #{before_rect.ratio}, after.ratio = #{after_rect.ratio}, sum = #{before_rect.ratio + after_rect.ratio}")

    # lay out everything
    @parent.layoutRecursive()

# Exports #####################################################################
exports = {
  DRAG_CONTROLLER: DRAG_CONTROLLER
}
if IS_GJS
  exports.Seam = ClutterSeam
else
  exports.Seam = DomSeam
