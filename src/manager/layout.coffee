###
  Layouts
  -----------------------------------------------------------------------------
  Base objects in the window manager.
  Abstracts away some root Clutter or DOM element that we'll add things to
  and bind basic event handling on for controllers
###

Logger    = imports.Mousetile.logger.exports
Util      = imports.Mousetile.util.exports
Constants = imports.Mousetile.constants.exports
Classes   = imports.Mousetile.classes.exports

RectLib   = imports.Mousetile.rect.exports
RegionLib = imports.Mousetile.region.exports
AssistantLib = imports.Mousetile.manager.assistant.exports

class RootLayout extends RectLib.Rect
  constructor: (w, h) ->
    super(w, h)
    @setColor(Constants.NativeColors.ROOT_COLOR)

###
  LayoutController ------------------------------------------------------------

  Manages moving windows, adding new windows,
  and saving/restoring application layouts
###

class LayoutController extends Classes.HasSignals

  WINDOW_DRAG_KEY = Constants.KEYS.CTRL

  localize = (obj, fn) ->
    -> fn.apply(obj, arguments)

  signalsEmitted: ["drag-enabled", "drag-disabled"]

  constructor: (@root) ->
    # state
    @dragging_enabled = false
    @dragged_window = null
    @over_role = null

    @windows = []

    @assistant = new AssistantLib.Assistant()
    @assistant.setColor(null)
    @assistant.hide()
    @root.addChild(@assistant)

    # set so we can discard calls to `manage` for windows we already own
    @window_set = new Classes.Set()
    

    # Window Event Handlers ###################################################
    # this is where the fancy tiling assistant should be shown and stuff!!!!

    # event handlers to bind to managed windows
    @window_handlers = {

      # note the target window and print some info about it
      'mouse-down':  (from, x, y) =>
        # print window info
        Logger.Log("Win: #{from.inspect()}, Parent: #{from.parent.inspect()}")

        if @dragging_enabled
          @startDrag(from)

        return Constants.YES_STOP_EMITTING

      # show the assistant
      'mouse-move': (from, x, y) =>
        if @dragged_window and @assistant.getTarget() != from
          Logger.Log("showing assistant on #{from}")
          @assistant.setTarget(from)
          @assistant.show()

        return Constants.YES_STOP_EMITTING

      # hide the assistant
      'mouse-out': (from, x, y) =>
        if @dragged_window and @assistant.getTarget() == from
          @assistant.hide()
          @assistant.setTarget(null)

      # release drag
      'mouse-up': (from, x, y) =>
        if @dragged_window
          @stopDrag(@dragged_window)

      # manage new children
      'child-added': (from, child) =>
        if child.managed_windows
          @manage(child) if child.managed_windows
    }

      # deprecated: we'll be over the assistant
#    @win_mouse_up = (from, x, y) =>
#      if @dragged_window
#        Logger.Log("going to swap #{from} with #{@dragged_window}")
#        # just swap windows for now
#        try
#          RegionLib.swap(from, @dragged_window)
#        catch err
#          @dragged_window = null
#          throw err
#        from.parent.layoutRecursive()
#        @dragged_window.parent.layoutRecursive()
#        @dragged_window = null
#
#      return Constants.DO_NOT_BUBBLE


    # Assistant event handlers ################################################
    @assistant.connect 'mouse-move-role', (from, role) =>
      if @dragged_window and @over_role != role
        Logger.Log('dragged window over role: '+ role)
        @over_role = role
        @previewRole(role, @assistant.getTarget(), @dragged_window)

        # draw highlight for action result

    @assistant.connect 'mouse-up-role', (from, role) =>
      if @dragged_window
        Logger.Log("dropped window on role: #{role}")
        # drop window
        @invokeRole(role, @dragged_window, @assistant.getTarget())
        @stopDrag(@dragged_window)


    # remove preview when leaving a role
    @assistant.connect 'mouse-leave-role', (from, role) =>
      @previewRole(null)


    # Root event handlers #####################################################
    # enable/disable window events
    @root.connect 'key-down', (from, sym) =>
      if sym is WINDOW_DRAG_KEY
        @dragging_enabled = true
        @emit("drag-enabled")
        
    @root.connect 'key-up', (from, sym) =>
      if sym is WINDOW_DRAG_KEY
        @dragging_enabled = false
        @emit("drag-disabled")

    @root.connect 'child-added', (root, child) =>
      root.setAboveSibling(@assistant, child)
      

  # connect event handlers to window
  manage: (win) ->
    if not @window_set.contains(win)
      @window_set.add(win)

      if win.managed_windows
        for w in win.managed_windows
          @manage(w)

      @windows.push(win)

      for signal, handler of @window_handlers
        win.connect(signal, handler)

  # drag and drop de-duplication
  startDrag: (win) ->
    @dragged_window = win

  stopDrag: (win) ->
    @dragged_window = null
    @assistant.hide()
    @assistant.setTarget(null)
    @over_role = null
    @previewRole(null) # clear any action-preview overlays

  # Role dispatch
  # passing `null` removes any preview
  previewRole: (role) ->
    Logger.Log("Previewing role #{role} (does nothing)")

  invokeRole: (role, win, target) ->
    [action, dir] = role.split('-')
    dest = target.parent
    win_has_chilren = win.managed_windows.length > 0
    old_parent = win.parent

    # sanity check: we need a destination!
    if not dest
      throw new Error("invokeRole: target window has no parent")

    target_idx = dest.managed_windows.indexOf(target)

    if dir in ['top', 'bottom']
      format = Constants.VERTICAL
    else
      format = Constants.HORIZONTAL

    if dir in ['top', 'left']
      side = Constants.BEFORE
    else
      side = Constants.AFTER

    # actions

    # swap the locations of win and target
    if action is 'swap'
      Logger.Log("swapping #{win} and #{target}")
      RegionLib.swap(win, target)
      for w in [win, target]
        if w.parent.format == w.format and win_has_chilren
          RegionLib.mergeIntoParent(w) #TODO: make this work
        w.parent.layoutRecursive() if w.parent
    else
      # for all other actions we first remove the window from its parent
      win.parent.removeWindow(win) if win.parent

    # split the targeted section in half by `direction`
    if action is 'split'
      if format == dest.format
        # no need to add a new wrapper, just resize the target
        dest.splitWindowAtIndex(win, target_idx, side)
        if win.format == dest.format and win_has_chilren
          RegionLib.mergeIntoParent(win)
      else # format mismatch
        new_region = dest.splitOtherDirectionAtIndex(win, target_idx, side)
        if new_region.format == win.format and win_has_chilren
          RegionLib.mergeIntoParent(win)

    ###
    shove the whole layout in a direction to make room for the new window.
    For example, 'shove-top' produces this trasformation on the following
    HORIZONTAL layout
    -----------          -----------
    |    |    |   ->     |_________|  new window is on top
    |    |    |          |    |    |
    -----------          -----------
    ###

    if action is 'shove'
      if format == dest.format
        # just add the layout to the beginning/end
        if side == Constants.BEFORE
          dest.addFirst(win)
        else
          dest.addLast(win)
      else
        # basically the same thing as calling 'split' on the dest itself
        return @invokeRole("split-#{dir}", win, dest)

    # cleanup
    dest.layoutRecursive(true)
    old_parent.layoutRecursive(true) if old_parent
