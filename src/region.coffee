####
# Regions
# Base window-manager class
#
# all this could just live in Container, but I've split it out to improve
# class readability. In general, Container has low-level methods (splice elements into array)
# where Region has high-level features (such as creating new regions as vertica splits)
#
# ###

#= require "container"
ContainerLib = imports.Mousetile.container
Container = ContainerLib.Container

# swap two regions
swap = (from, to) ->
  from_parent = from.parent
  to_parent = to.parent

  from_idx = from_parent.managed_windows.indexOf(from)
  to_idx = to_parent.managed_windows.indexOf(to)

  Util.Log("moving cell #{from_idx} in #{from_parent} to cell #{to_idx} in #{to_parent}")

  from_parent.removeChild(from)
  to_parent.removeChild(to)

  from_parent.addChild(to)
  to_parent.addChild(from)

  to_parent.managed_windows[to_idx] = from
  from_parent.managed_windows[from_idx] = to

  from.needs_layout = to.needs_layout = true

class Region extends Container
    # Constants
    VERTICAL = false
    HORIZONTAL = true

    # when splitting / adding windows
    BEFORE = true
    AFTER  = false

    mark_for_layout = (regs...) ->
        for r in regs
            r.needs_layout = true

    get = (obj, name, params...) ->
        obj["get#{name}"].apply(obj, params)
    set = (obj, name, params...) ->
        Util.log("setting #{name} on #{obj} to #{params}")
        obj["set#{name}"].apply(obj, params)

    # transform existing windows ratios to make room for new window
    # preservign thier scale to each other
    addNewWindowAtIndex: (win, idx, side = BEFORE) ->
        @addChild(win)

        # tranform exisiting to make even space for new window
        transform = @managed_windows.length / (@managed_windows.length + 1)
        for w in @managed_windows
            w.ratio = w.ratio * transform

        # insert window and set ratio
        @addWindowAtIndex(win, idx, side)
        win.ratio = 1 / @managed_windows.length

    # add a window at the top/left of the container
    # preserve the other window's relationshipts to each other,
    # giving the new window 1/N space where N is the number of total windows
    addFirst: (win) ->
        @addNewWindowAtIndex(win, 0)

    addLast: (win) ->
        @addNewWindowAtIndex(win, -1, AFTER)


    # split the space used by a current window
    splitWindowAtIndex: (win, idx, side = BEFORE) ->
        cur = @managed_windows[idx]
        # half of the current space used for each window
        ratio = cur.ratio / 2
        cur.ratio = ratio
        win.ratio = ratio
        @addWindowAtIndex(win, idx, side)

    splitOtherDirectionAtIndex: (new_win, idx, side_for_new = BEFORE) ->
        op_region = new Region(5, 5, not @format, @spacing)
        idx = @managed_windows.length + idx if idx < 0
        existant_window = @managed_windows[idx]


        # replace window with new region
        @replaceAtIndex(op_region, idx)
        
        # set up new region
        op_region.transact ->
            mark_for_layout(existant_window, new_win)
            @addNewWindowAtIndex(existant_window, 0)
            @addNewWindowAtIndex(new_win, 0, side_for_new)


# export global
this.Region = Region
