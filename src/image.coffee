Clutter = imports.gi.Clutter
RectLib = imports.Mousetile.rect
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

Image = ClutterImage

exports = {
  Image: ClutterImage
}