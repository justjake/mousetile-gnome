###
Layouts

Base objects in the window manager.
Abstracts away some root Clutter or DOM element that we'll add things to
and bind basic event handling on for controllers
###

Util = imports.Mousetile.util
Constants = Util.Constants
Rects = imports.Mousetile.rect

class RootLayout extends Rects.Rect
  constructor: (w, h) ->
    super(w, h)
    @setColor(Constants.ROOT_COLOR)

###
  LayoutController ------------------------------------------------------------

  Manages moving windows, adding new windows,
  and saving/restoring application layouts
###

class LayoutController
