####
# Rectangles
# the building block of our layout system, and the only part
# that should know about the DOM
#
# TODO: make sure the css class .rect has:
#   position: absolute
#   box-sizing: border-box
# and optionally:
#   background: rgba(#f00, 0.1)
####

`const util`
util = 'throw error'

class Rect

    NO_PARENT = null

    # first: helper functions for pixesls
    to_pixels = (n) -> n + "px"
    from_pixels = (px) -> 
        parseInt(px[0..-3], 10)

    constructor: (width = 0, height = 0) ->
        el = document.createElement('div')
        el.className = 'rect'
        @native = el
        @children = []
        @parent = NO_PARENT

        # apply sizing
        @setWidth width
        @setHeight height

    # PROPERTIES

    # property: width
    setWidth: (w) ->
        @native.style.width = to_pixels(w)
    getWidth: ->
        from_pixels(@native.style.width)

    # property: height
    setHeight: (h) ->
        @native.style.height = to_pixels(h)
    getHeight: ->
        from_pixels @native.style.height

    # property: x
    setX: (x) ->
        @native.style.left = to_pixels(x)
    getX: ->
        from_pixels @native.style.left

    # property: y
    setY: (y) ->
        @native.style.top = to_pixels(y)
    getY: ->
        from_pixels @native.style.top


    # FUNCTIONS

    # child elements are tracked independently of the DOM
    # TODO: make sure this doesn't break/leak
    addChild: (rect) ->
        @children.push(rect)
        @native.appendChild(rect.native)
        rect.parent = this

    removeChild: (rect) ->
        idx = @children.indexOf(rect)
        if idx != -1
            delete @children[idx]
            @native.removeChild(rect.native)
            rect.parent = NO_PARENT
        else
            throw "InvalidRemoval: #{this} has no child #{rect}"
