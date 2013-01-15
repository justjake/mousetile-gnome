IS_GJS = true  # TODO: move this to build system

###
  Text
  -----------------------------------------------------------------------------
  A rect that contains text
###

Clutter = imports.gi.Clutter

Constants = imports.Mousetile.constants.exports
RectLib = imports.Mousetile.rect.exports
Rect = RectLib.Rect

class DomText extends Rect
  constructor: (text, color) ->
    super()


class Text extends Rect

  default_color: Constants.NativeColors.WHITE

  constructor: (text, color) ->
    super()
    if IS_GJS
      @native = new Clutter.Text {text: text, color: color}
    else
      if @native.textContent?
        @native.textContent = text
      else
        @native.innerText = text
      @native.style.color = color

    @setColor(@default_color)


# Exports #####################################################################
exports = {
  Text: Text
}
