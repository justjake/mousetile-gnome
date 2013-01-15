###
A widget that appears when you drag a window over another window

allows you to select your destination:
  shove{top.left.right.bottom} varies based on layout context.
    if the destination is in a HORIZONTAL layout, shoving left or right will
    resize all of destination's siblings to make proportional space for SOURCE.

    shoving top or bottom will split the whole view vertically, keeping DESITNATIOn and chilren
    together in a row, and adding SOURCE in its own row above or below

  split{top,left,right,bottom} evenly divides the detination space between
    the source and destination
  swap the source and the destination
###

Constants = imports.Mousetile.constants.exports
RectLib   = imports.Mousetile.rect.exports
ImageLib  = imports.Mousetile.image.exports

ASSET_PATH = 'assets'

role_icon = (role) ->
  "#{ASSET_PATH}/#{role}.png"

# a wrapper around an icon with extra padding and BG color
class DropActionButton extends RectLib.Rect
  SPACING = 3

  @default_color: Constants.NativeColors.BUTTON_NORMAL

  constructor: (@role) ->
    @icon = new ImageLib.Image(role_icon(@role))
    super(@icon.getWidth() + SPACING * 2, @icon.getHeight() + SPACING * 2)
    @addChild(@icon)
    @icon.setX SPACING
    @icon.setY SPACING


# Assistant ###################################################################
# a group of DropActionButtons in a + shape, with swap action in the middle,
# then "split" actions closest to the center, and shove actions farther away.

class Assistant extends RectLib.Rect
  SPACING = 10
  roles = ['split', 'shove']
  directions = ['top', 'left', 'bottom', 'right']

  buttons = ['swap-center']
  for d in directions
    for r in roles
      buttons.push("#{r}-#{d}")

  default_color: Constants.NativeColors.RED # do not set color

  constructor: ->
    # defie handlers for role widgets ##########################################

    @widget_hadlers = {
      'mouse-move': (widget, x, y) =>
        @emit('mouse-move-role', widget.role, x, y)

      'mouse-up': (widget, x, y) =>
        @emit('mouse-up-role', widget.role)

      'mouse-leave': (widget, x, y) =>
        @emit('mouse-leave-role', widget.role)
    }

    # create widgets ##########################################################

    # @setColor(Constants.NativeColors.NO_COLOR)
    for role in buttons
      this[role] = new DropActionButton(role)
      for signal, handler of @widget_hadlers
        this[role].connect(signal, handler)

    # our dimensions will be defined by the size of the buttons and our spacing
    example_icon = this[buttons[0]]
    icon_width = example_icon.getWidth()
    icon_height = example_icon.getHeight()

    super(
      icon_width * 5 + SPACING * 6,
      icon_height  * 5 + SPACING * 6
    )

    # add children now that we have instantianted the rect
    for role in buttons
      @addChild(this[role])


    # lay out children ########################################################
    center_col_x = SPACING * 3 + icon_width * 2
    idx = 0
    for role in ["shove-top", "split-top", "swap-center", "split-bottom", "shove-bottom"]
      this[role].setY SPACING * (1 + idx) + icon_height * idx
      this[role].setX center_col_x
      idx += 1

    row3_y = SPACING * 3 + icon_height * 2
    idx = 0
    for role in ["shove-left", "split-left", "swap-center", "split-right", "shove-right"]
      this[role].setY row3_y
      this[role].setX SPACING * (1 + idx) + icon_width * idx
      idx += 1


    # properties
    @target = null

  # Property methods
  setTarget: (t) ->
    @target = t

    if t # we will pass null to unset the target
      # center self over target
      [t_x, t_y] = RectLib.global_position(t)
      mock_target = new RectLib.AbstractRect(t.getWidth(), t.getHeight(), t_x, t_y)
      [x, y] = RectLib.center(mock_target, this)

      Logger.Log("Assistant: moving to #{x}, #{y}")

      @setX x
      @setY y

    @emit('target-changed', t)

  getTarget: ->
    @target


# Exports #####################################################################
exports = {
  Assistant: Assistant
}