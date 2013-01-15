####
# Container
#
# Choo-choo all aboard the layout train
# Splittable rect container
####

Util      = imports.Mousetile.util.exports
Logger    = imports.Mousetile.logger.exports
Constants = imports.Mousetile.constants.exports

RectLib   = imports.Mousetile.rect.exports
Rect = RectLib.Rect

SeamLib   = imports.Mousetile.seam.exports
Seam = SeamLib.Seam

class Container extends Rect

    # Constants
    VERTICAL   = Constants.VERTICAL
    HORIZONTAL = Constants.HORIZONTAL

    # when splitting / adding windows
    BEFORE = Constants.BEFORE
    AFTER  = Constants.AFTER

    # space between child rectangles
    SPACING = Constants.SPACING

    # derp
    get = (obj, name, params...) ->
        obj["get#{name}"].apply(obj, params)
    set = (obj, name, params...) ->
        obj["set#{name}"].apply(obj, params)

    # size ratios to fixed pixel space
    fix = (rat, total) -> 
        intended = Math.ceil(total * rat)
        if intended < 0
            return 0
        return intended


    constructor: (width, height, horiz = HORIZONTAL, spacing = SPACING) ->
        super(width, height)
        @format = horiz
        @spacing = spacing
        @ratio = 1 # how much of our parent's space should we take up?

        @managed_windows = []
        @seams = []

        @native.className += " horiz" if @format
        @layout_needed = false

    # let us know layout format
    toString: ->
      fmt = "Horizontal"
      if @format is Constants.VERTICAL
        fmt = "Vertical"

      fmt + super()


    # given the number of children we have
    # and our spacing, how many pixels are in
    # our layout space?
    #
    # NO padding is applied on the outside edges
    # Spacing is only used *between* children
    spaceAvailible: ->
        if @format is VERTICAL
            res = @getHeight() - (@managed_windows.length - 1) * @spacing
        else
            res = @getWidth() - (@managed_windows.length - 1) * @spacing
        res

    # Get a child's ratio
    ratioOf: (child) ->
        child.ratio

    # ratio before/after a row/column
    ratioAround: (ord_or_x, or_y) ->
      if or_y?
        if @format is HORIZONTAL
          ord = ord_or_x
        else
          ord = or_y

      space = @spaceAvailible()
      if @format is VERTICAL
        full_space = @getHeight()
      else
        full_space = @getWidth()
      transform = space / full_space
      local_org = ord * transform
      [local_org / space, (space - local_org) / space] # ratio space before and after the ordinal

    _layoutParams: ->
        params = {}
        if @format is VERTICAL
            params.ord = 'Y'
            params.off_ord = 'X'
            params.dim = 'Height'
            params.off_dim = 'Width'
        else
            params.ord = 'X'
            params.off_ord = 'Y'
            params.dim = 'Width'
            params.off_dim = 'Height'
        return params


    # total ratio should be 1.
    # if not, scale everything so that it is 1.
    _normalizeLayout: ->

      target = 1

      # special case: only 1 managed window

      total = @managed_windows.reduce ((prev, cur) => prev + cur.ratio), 0

      transform = target / total

      Logger.Log("Normalizing layout from #{total} to #{target} with trasform factor #{transform}")

      for w in @managed_windows
        w.ratio *= transform


    # lay out all children based on our HOR/VERT
    # and dimensions
    layout: ->
        # we will get layout, so unflag us for future layout runs for now
        @needs_layout = false

        if @managed_windows.length == 0
          return

        # sanity check: all child ratios should add up to one
        total = @managed_windows.reduce ((prev, cur) => prev + cur.ratio), 0
        if not Util.almost_equals(total, 1)
          @_normalizeLayout()

        # what set of properties should we use?
        if @format is VERTICAL
            ord = 'Y'
            off_ord = 'X'
            dim = 'Height'
            off_dim = 'Width'
        else
            ord = 'X'
            off_ord = 'Y'
            dim = 'Width'
            off_dim = 'Height'

        space_availible = @spaceAvailible()
        space_consumed = 0
        final = null
        # lay out items
        for c in @managed_windows
            # size child
            ## primary dimension
            ratio = @ratioOf(c)
            size = fix(ratio, space_availible)

            # Logger.Log("layout ratio: #{ratio}, size: #{size}, spess: #{space_consumed}")
            set(c, dim, size)

            ## other dimension
            set(c, off_dim, get(this, off_dim))

            # set position
            ## primary ord
            set(c, ord, space_consumed)
            ## off ord
            set(c, off_ord, 0)

            # consume space
            space_consumed += size + @spacing

            final = c

        # make sure all the space is filled by adding 1px at a time
        # if we have any space left over
        if final
          while space_availible > space_consumed
            size = get(final, dim)
            set(final, dim, size + 1)
            space_consumed += 1

        # lay out seams
        @layoutSeams()


    eachWindow: (fn) ->
      Util.traverse(this, ((w) -> w.managed_windows), fn)

    # lay out this item, then lay out child items that need it
    layoutRecursive: (layout_all = false) ->
        @layout()
        for w in @managed_windows
            w.layoutRecursive(true) if w.needs_layout or layout_all


    # Add a managed window, which is part of layout stuff
    addWindow: (win) ->
        @addChild(win)
        @managed_windows.push(win)
        @emit('window-added', win)


    # remove from managed windows on removing child, and cull seams
    removeWindow: (win) ->
        @removeChild(win)
        idx = @managed_windows.indexOf(win)
        if idx > -1
            @managed_windows.splice(@managed_windows.indexOf(win), 1)
        idx


    # low-level
    addWindowAtIndex: (win, idx, side = BEFORE) ->
        @addChild(win)
        if side == BEFORE
            @managed_windows.splice(idx, 0, win)
        else
            idx = @managed_windows.length + idx if idx < 0
            @managed_windows.splice(idx + 1, 0, win)
        @emit('window-added', win)

    # replace managed window at index
    replaceAtIndex: (win, idx) ->
        # remove old window from index
        old_win = @managed_windows[idx]
        @removeChild(old_win)

        # add new window
        @addChild(win)

        # replace in managed window queue with new window
        @managed_windows[idx] = win
        win.ratio = old_win.ratio
        @emit('window-added', win)



    # add a seam
    # TODO: make event handlers for seams
    addSeam: (index) ->
        seam = new Seam(this, index)
        @addChild(seam)
        @seams[index] = seam

    # super-naive seam culling
    # TODO: robusify seam culling when windows are removed
    cullSeams: ->
        for s in @seams
            @removeChild(s)
        @seams = []

    # fault-tolderant: seams are totally inconsiquential
    # we do best-effor seam management, but they're super-ephemeral
    removeSeam: (index) ->
        seam = @seams[index]
        if seam?
            @removeChild(seam)
            @seams.splice(index, 1)
        seam


    # create seams and move them into position
    layoutSeams: ->
        # create any undefined seams
        i = 0
        len = @managed_windows.length - 1
        while i < len
            if not @seams[i]?
                @addSeam(i)
            i += 1

        # lay out seams
        p = @_layoutParams()
        for s in @seams
            # set dimensions
            set(s, p.off_dim, get(this, p.off_dim))
            set(s, p.dim, @spacing)

            # set position
            after = @managed_windows[s.index]
            set(s, p.ord, get(after, p.ord) + get(after, p.dim))
            set(s, p.off_ord, 0)

            # seams are always in front of everything
            @setAboveSibling(s)

            # win.


    # do actions, then run general cleanup
    # includeing recursive layout
    # and re-layout everything that needs it
    transact: (actions) ->
        @needs_layout = true
        actions.call(this)
        if @parent
            @parent.layoutRecursive()
        else
            @layoutRecursive()


allWindows = (tree) ->
  res = []
  tree.eachWindow (w) ->
    res.push(w)

  return res

# export
exports = {}
exports.Container = Container
exports.allWindows = allWindows

