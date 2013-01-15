###
  Constants
  -----------------------------------------------------------------------------
  Configuration and enum-like types for Mousetile
###

IS_GJS = true #TODO: move to build system

ColorLib = imports.Mousetile.color

rgba = ColorLib.rgba
fade = ColorLib.fade
random_color = ColorLib.random

Constants = {
  DEBUG: true

  # for floating-point comparrison
  EPSILON: 0.00001

  GOLDEN: 1 / 1.618

  # return from events
  # stop event handlers for this event IMMEDIATLY
  YES_STOP_EMITTING: true
  # carry on
  NO_CONTINUE_EMITTING: false
  # Finish current event handlers on this object, but do not bubble to parent
  DO_NOT_BUBBLE: 100


  # layout directions
  # these are boolean because it's fun to be able to `not region.format`
  VERTICAL:   false
  HORIZONTAL: true

  # which side when targeting an actor
  BEFORE: true
  AFTER:  false

  # size of seams
  SPACING: 9

  # Parenting
  NO_PARENT: null

  # for fun
  HEART: "♥" # seems buggy TODO: fix heart bugs

  KEYS: {
    CTRL: 65507
    ALT:  65513
  }
}
# Colors ######################################################################

Colors = {
  # basic solid colors
  BLACK:       rgba(  0,   0,   0)
  WHITE:       rgba(255, 255, 255)
  RED:         rgba(255,   0,   0)
  BLUE:        rgba(  0,   0, 255)
  GREEN:       rgba(  0, 255,   0)
  GREY:        rgba(255/2, 255/2, 255/2)
  # totally transparent
  NONE:        rgba(  0,   0,   0,  0)

  # palette of interesting colors
  ACTIVE_BLUE: rgba(12, 122, 247)
}

#### Styling
Colors.RECT_COLOR = fade(Colors.BLUE, 0.1 * 255)
Colors.SEAM_COLOR = Colors.BLACK
Colors.ROOT_COLOR = Colors.WHITE
Colors.DRAGGABLE_HANDLE = fade(Colors.ACTIVE_BLUE, 0.15 * 255)

Colors.BUTTON_NORMAL = fade(Colors.BLACK, 0.4 * 255)
Colors.BUTTON_HOVER  = fade(Colors.BLACK, 0.6 * 255)

#### Transform from struct to native representation
NativeColors = {}
for k, v of Colors
  NativeColors[k] = ColorLib.to_native(v)

# sub in special implementation of NONE color
if IS_GJS
  NativeColors.NONE = 0
else
  NativeColors.NONE = 'transparent'

# Exports #####################################################################

exports = Constants
exports.Colors = Colors
exports.NativeColors = NativeColors

