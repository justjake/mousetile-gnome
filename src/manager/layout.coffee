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
    
    @dragging_enabled = false
    @dragged_window = null
    @windows = []

    # set so we can discard calls to `manage` for windows we already own
    @window_set = new Classes.Set()
    
    # define event handlers
    @win_mouse_down = (from, x, y) =>

      # print window info
      Logger.Log("Win: #{from.inspect()}, Parent: #{from.parent.inspect()}")

      if @dragging_enabled
        @dragged_window = from

      return Constants.YES_STOP_EMITTING

    # Window Event Handlers ###################################################
    # this is where the fancy tiling assistant should be shown and stuff!!!!

    @win_mouse_up = (from, x, y) =>
      if @dragged_window
        Logger.Log("going to swap #{from} with #{@dragged_window}")
        # just swap windows for now
        try
          RegionLib.swap(from, @dragged_window)
        catch err
          @dragged_window = null
          throw err
        from.parent.layoutRecursive()
        @dragged_window.parent.layoutRecursive()
        @dragged_window = null

      return Constants.DO_NOT_BUBBLE

    @win_child_added = (from, child) =>
      if child.managed_windows
        @manage(child) if child.managed_windows
        from.setColor(Constants.NativeColors.RED)
      
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
      
    
  manage: (win) ->
    if not @window_set.contains(win)

      # manage children
      if win.managed_windows
        for w in win.managed_windows
          @manage(w)

      Logger.Log "Managed #{win}"
      @windows.push(win)
      win.connect 'mouse-down', @win_mouse_down
      win.connect 'mouse-up', @win_mouse_up
      win.connect 'child-added', @win_child_added
