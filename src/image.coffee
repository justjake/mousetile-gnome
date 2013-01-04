Clutter = imports.gi.Clutter
RectLib = imports.Mousetile.rect

class ClutterImage extends RectLib.Rect
  constructor: (width, height, src) ->
    super(width, height)
    @native = Clutter.Texture.new_from_file(src)

Image = ClutterImage

exports = {
  Image: ClutterImage
}