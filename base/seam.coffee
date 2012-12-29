####
# Seams - goes in the empty space between container ports
####

#=require "util"
#=require "rect"

class Seam extends Rect
    constructor: (container_parent, first_index = 0) ->
        super(0,0)
        @parent = container_parent
        @index =  first_index

        # add seam  class to native representation
        @native.className += " seam"
        
# Write to global scope
this.Seam = Seam
