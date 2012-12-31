import clutter
import gobject

class DragEnvelope(object):
    """Helps deal with drags."""
    def __init__(self, obj, event):
        self.event = event
        self.diffx = event.x - obj.get_x()
        self.diffy = event.y - obj.get_y()
    def calcPos(self, event):
        """Where to draw the Actor relative to cursor within it."""
        self.newx = event.x - self.diffx
        self.newy = event.y - self.diffy

class Mouserizer(object):
    ## User vars to form ui mask
    HITABLE = 1<<0
    DRAGABLE = 1<<1
    CLICKABLE = 1<<2
    SCROLLABLE = 1<<3
    PICK_UNDER = 1<<4

    LEFT = 1<<0
    MIDDLE = 1<<1
    RIGHT = 1<<2

    ## Private class vars
    __FLAG_ENTERED = 1<<0 # Not used in this version.
    __FLAG_PRESSING = 1<<1
    __FLAG_RELEASING = 1<<2
    __FLAG_MOVING = 1<<3
    __FLAG_DRAGGING = 1<<4

    __PATTERN_CLICK =  __FLAG_PRESSING | __FLAG_RELEASING
    __PATTERN_DRAG_START = __FLAG_PRESSING| __FLAG_MOVING
    __PATTERN_DRAG = __PATTERN_DRAG_START | __FLAG_DRAGGING
    __PATTERN_DROP =  __FLAG_PRESSING| __FLAG_DRAGGING | __FLAG_RELEASING

    YES_CONTINUE_EMITTING = False
    NO_STOP_EMITTING = True

    __clutter_mouse_event_types=[
        clutter.MOTION,
        clutter.ENTER,
        clutter.LEAVE,
        clutter.BUTTON_PRESS,
        clutter.BUTTON_RELEASE,
        clutter.SCROLL
    ]

    def __init__(self, ui=None, buttons=None):
        if ui is None:
            return # Not going to watch for any mouse events, so bug out.
        self.buttons = buttons

        ## If we want HIT kind of events, then just connect the usual suspects.
        if (ui & Mouserizer.HITABLE) !=0: # test bit
            self.connect('enter-event', self.on_enter_event)
            self.connect('leave-event', self.on_leave_event)

        self.__PICK_UNDER = False
        if (ui & Mouserizer.PICK_UNDER) !=0:
            self.__PICK_UNDER = True

        ## Keep a record of what we are going to listen to.
        self.ui = ui

        ## Enable the actor (self) to receive events.
        self.set_reactive(True)

        ## This is the state of our situation -- it will be masked bitwise.
        self.ui_state = 0

        ## Route all events (for this Actor) through one function:
        self.connect('captured-event', self.event_central)

    def event_central(self, obj, event):
        ## This routine runs many times. Once for every kind
        ## of event the actor is getting.

        ## filter out only the mouse events.
        if event.type not in Mouserizer.__clutter_mouse_event_types:
            return Mouserizer.YES_CONTINUE_EMITTING

        ## filter out buttons we are NOT going to deal with
        if hasattr(event, "button"):
            b = 1 << (event.button - 1)
            #print bin(b)," vs ", bin(self.buttons)
            if not(b & self.buttons !=0 ):
                return Mouserizer.NO_STOP_EMITTING # is this wise?

        ## event_central ONLY runs when cursor is
        ## over the actor -- thus ENTER is implied.

        ## Make a note of PRESS/RELEASE
        if event.type==clutter.BUTTON_PRESS:
            self.ui_state = self.ui_state | Mouserizer.__FLAG_PRESSING # set bit
        if event.type==clutter.BUTTON_RELEASE:
            self.ui_state = self.ui_state | Mouserizer.__FLAG_RELEASING # set bit

        ## Make a note of MOTION
        ## First, clear it.
        self.ui_state = self.ui_state & ~Mouserizer.__FLAG_MOVING # clear bit
        if event.type==clutter.MOTION:
            self.ui_state = self.ui_state | Mouserizer.__FLAG_MOVING # set bit

        ## Now, what kinds of stuff is this actor interested in?

        ## DO META EVENTS - "More than" events. e.g. 'Click' is press, then release.
        if (self.ui & Mouserizer.CLICKABLE) != 0: # test bit
            if self.ui_state == Mouserizer.__PATTERN_CLICK:
                if event.click_count > 1:
                    self.emit('double-click', event)
                else:
                    ## A single click is fired just before double-click...!
                    self.emit('single-click', event)

        if (self.ui & Mouserizer.DRAGABLE) !=0: # test bit
            if self.ui_state == Mouserizer.__PATTERN_DRAG_START:
                self.ui_state=self.ui_state | Mouserizer.__FLAG_DRAGGING # set bit
                self.draglet = DragEnvelope( self, event )
                ## Phew! I thought I was fcuked! In order to get dragging to
                ## work when the pointer is NOT ON the Actor, I had to revert
                ## to grab_pointer* -- and that needs connecting. I connected the
                ## two appropriate event to *this* same function! And it works :D
                ##
                ## * grab_pointer causes the entire window (stage?) to focus on the
                ##   Actor passed -- so I get all motion and release events even where
                ##   the Actor aint.
                ##   ! Not sure what kind of recursive issues this may throw at me :(
                clutter.grab_pointer( self )
                self.connect('motion-event', self.event_central)
                self.connect('button-release-event', self.event_central)
                self.emit('drag-start', self.draglet )
            elif self.ui_state == Mouserizer.__PATTERN_DRAG:
                self.draglet.calcPos( event ) # A 'draglet' is a little wrapper containing the event and some tricks.
                ## Who is under me? Only do if PICK_UNDER flag is set.
                if self.__PICK_UNDER:
                    self.hide()
                    a = self.stage.get_actor_at_pos(clutter.PICK_REACTIVE, int(event.x),int(event.y))
                    self.show()
                    ## a is!
                    ## Only emit if a has a drag-over signal:
                    if gobject.signal_lookup('drag-over', a ):
                        print a, " under me"
                        a.emit('drag-over', self.draglet)
                self.emit('dragging', self.draglet)

            elif self.ui_state == Mouserizer.__PATTERN_DROP:
                self.draglet.calcPos( event )
                self.ui_state= self.ui_state & ~Mouserizer.__FLAG_DRAGGING # clear bit
                clutter.ungrab_pointer()
                self.emit("drop", self.draglet)
                del(self.draglet)

        ## META EVENTS are done.

        ## Flip opposites off.
        if event.type==clutter.BUTTON_PRESS:
            self.ui_state = self.ui_state & ~Mouserizer.__FLAG_RELEASING # clear bit
        if event.type==clutter.BUTTON_RELEASE:
            self.ui_state = self.ui_state & ~Mouserizer.__FLAG_PRESSING # clear bit
            self.ui_state = self.ui_state & ~Mouserizer.__FLAG_RELEASING # clear bit
            self.ui_state = self.ui_state & ~Mouserizer.__FLAG_DRAGGING # clear bit

        return Mouserizer.YES_CONTINUE_EMITTING
