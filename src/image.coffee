IS_GJS = true  # TODO: move this to build system

###
  Images
  -----------------------------------------------------------------------------
  A rect that displays a bitmap
  TODO: specify a pathing standard for loading those bitmaps
###

Clutter = imports.gi.Clutter

RectLib = imports.Mousetile.rect.exports
Rect = RectLib.Rect


class DomImage extends Rect
  constructor: (src) ->
    super()
    @native = document.createElement('img')
    @native.src = src



class ClutterImage extends Rect
  constructor: (src) ->
    super()
    @native = new Clutter.Texture {filename: src}




# choose class to export based on env
if IS_GJS
  Image = ClutterImage
else
  Image = DomImage

# Exports #####################################################################
exports = {
  Image: Image
}