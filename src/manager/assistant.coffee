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

Util = imports.Mousetile.util
RectLib = imports.Mousetile.rect
ImageLib = imports.Mousetile.image

ASSET_PATH = 'assets'


role_icon = (role) ->
  "#{ASSET_PATH}/#{role}.png"

class DropActionButton extends RectLib.Rect
  SPACING = 3

  constructor: (src) ->
    @icon = new ImageLib.Image(src)
    super(@icon.getWidth() + SPACING * 2, @icon.getHeight() + SPACING * 2)
    @addChild(@icon)
    @icon.setX SPACING
    @icon.setY SPACING

class Assistant extends Util.HasSignals
  SPACING = 10
  roles = ['split', 'shove']
  directions = ['top', 'left', 'bottom', 'right']

  buttons = ['swap-center']
  for d in directions
    for r in roles
      buttons.push("#{r}-#{d}")

  constructor: ->
    for role in buttons
      this[role] = new DropActionButton(role_icon(role))

    example_icon = this[buttons[0]]
    icon_width = example_icon.getWidth()
    icon_height = example_icon.getHeight()

    # container rect
    @container = new RectLib.Rect(
      icon_width * 5 + SPACING * 6,
      icon_height  * 5 + SPACING * 6
    )

    for role in buttons
      @container.addChild(this[role])

    # lay out icons
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

    # delegate methods to @container
    Util.proxy(this, @container, 'setX', 'getX', 'setY', 'getY', 'setParent', 'getWidth', 'getHeight')

