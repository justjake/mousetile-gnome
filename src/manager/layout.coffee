###
Layouts

Base objects in the window manager.
Abstracts away some root Clutter or DOM element that we'll add things to
and bind basic event handling on for controllers
###

Util = imports.Mousetile.util
Constants = Util.Constants
Rects = imports.Mousetile.rect
Regions = imports.Mousetile.region

class RootLayout extends Rects.Rect
  constructor: (w, h) ->
    super(w, h)
    @setColor(Constants.ROOT_COLOR)

###
  LayoutController ------------------------------------------------------------

  Manages moving windows, adding new windows,
  and saving/restoring application layouts
###

class LayoutController extends Util.HasSignals

  WINDOW_DRAG_KEY = Constants.KEYS.CTRL

  localize = (obj, fn) ->
    -> fn.apply(obj, arguments)

  signalsEmitted: ["drag-enabled", "drag-disabled"]

  constructor: (@root) ->
    
    @dragging_enabled = false
    @dragged_window = null
    @windows = []
    
    # define event handlers
    @win_mouse_down = (from, x, y) =>
      Util.Log("Mouse down in window: #{from}")
      if @dragging_enabled
        @dragged_window = from

      return Constants.YES_STOP_EMITTING

    @win_mouse_up = (from, x, y) =>
      Util.Log("Mouse up in window: #{from}")
      if @dragged_window
        Util.Log("going to swap #{from} with #{@dragged_window}")
        # just swap windows for now
        try
          Regions.swap(from, @dragged_window)
        catch err
          @dragged_window = null
          throw err
        from.parent.layoutRecursive()
        @dragged_window.parent.layoutRecursive()
        @dragged_window = null

      return Constants.YES_STOP_EMITTING
      
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
    Util.Log "Managed #{win}"
    @windows.push(win)
    win.connect 'mouse-down', @win_mouse_down
    win.connect 'mouse-up', @win_mouse_up
