####
# Seams - goes in the empty space between container ports
####

#=require "util"
#=require "rect"


Util = imports.Mousetile.util

RectLib = imports.Mousetile.rect

Rect = RectLib.Rect
AbstractRect = RectLib.AbstractRect




class DomSeam extends RectLib.DomRect
  constructor: (container_parent, first_index = 0) ->
    super(0,0)
    @parent = container_parent
    @index = first_index
    # add seam  class to native representation
    @native.className += " seam"



class ClutterSeam extends RectLib.ClutterRect
  constructor: (container_parent, first_index = 0) ->
    super(0,0)
    @native.set_background_color(Util.Constants.SEAM_COLOR)
    @parent = container_parent
    @index = first_index
    # add seam  class to native representation
    @native.className += " seam"

# Write to global scope
if Util.is_gjs()
  Seam = ClutterSeam
else
  Seam = DomSeam
