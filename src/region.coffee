####
# Regions
# Base window-manager class
#
# all this could just live in Container, but I've split it out to improve
# class readability. In general, Container has low-level methods (splice elements into array)
# where Region has high-level features (such as creating new regions as vertica splits)
#
# ###

Constants    = imports.Mousetile.constants.exports
ContainerLib = imports.Mousetile.container.exports
Logger       = imports.Mousetile.logger.exports

if Constants.DEBUG
  TextLib = imports.Mousetile.text.exports


# swap two regions
swap = (from, to) ->

  from_parent = from.parent
  to_parent = to.parent
  # Sanity check: do not swap parents with children
  if to.isAncestor(from) or from.isAncestor(to)
    throw new Error("Swap failed: cannot swap parent with child")

  from_idx = from_parent.managed_windows.indexOf(from)
  to_idx = to_parent.managed_windows.indexOf(to)

  Logger.Log("moving cell #{from_idx} in #{from_parent} to cell #{to_idx} in #{to_parent}")

  # low level - swap object parents
  from_parent.removeChild(from)
  to_parent.removeChild(to)

  from_parent.addChild(to)
  to_parent.addChild(from)

  # put objects in right order of new parent
  to_parent.managed_windows[to_idx] = from
  from_parent.managed_windows[from_idx] = to

  # swap ratios
  [from.ratio, to.ratio] = [to.ratio, from.ratio]

  from.needs_layout = to.needs_layout = true



# destroy a region by merging all of its children into the parent
#   if the region has the same format as its parent
mergeIntoParent = (region) ->
  parent = region.parent

  # sanity check
  if not parent
    Logger.Log("Tried to merge #{region} into #{parent} but failed: parent was falsy")
  else if parent.format != region.format
    Logger.Log("Tried to merge #{region} into #{parent} but failed: format mismatch")

  # remove the region from its parent, and capture its former index
  idx = parent.removeWindow(region)

  # transform the region's children so they all fit into the same
  #   space as the region, then add them to the parent in order
  c_num = 0
  for c in region.managed_windows
    c.needs_layout = true
    c.ratio *= region.ratio

    parent.addWindowAtIndex(idx + c_num)

    c_num += 1




class Region extends ContainerLib.Container

    # when splitting / adding windows
    BEFORE = Constants.BEFORE
    AFTER  = Constants.AFTER

    constructor: (args...) ->
      super(args...)

      if Constants.DEBUG
        txt = new TextLib.Text(@toString(), Constants.NativeColors.BLUE)
        @addChild(txt)

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
        op_region.ratio = existant_window.ratio

        # replace window with new region
        @replaceAtIndex(op_region, idx)
        op_region.needs_layout = true
        
        # set up new region
        for win in [existant_window, new_win]
          win.needs_layout = true
        op_region.addNewWindowAtIndex(existant_window, 0)
        op_region.addNewWindowAtIndex(new_win, 0, side_for_new)

        return op_region


# Exports #####################################################################
exports = {
  swap: swap
  mergeIntoParent: mergeIntoParent

  Region: Region
}
