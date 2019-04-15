#!/usr/bin/env lua
-- A semaphore (traffic light) with a simple GUI.
-- Requires: - MoonSC to define the behavior of the semaphore,
--           - MoonNuklear to draw the GUI,
--           - MoonGLFW for window creation and input handling,
--           - MoonGL for rendering.

local glfw = require("moonglfw")
local gl = require("moongl")
local nk = require("moonnuklear")
local backend = require("moonnuklear.glbackend")
local moonsc = require("moonsc")
moonsc.import_tags()
local now = moonsc.now

local TITLE = "Semaphore" -- GLFW window title
local FPS = 20 -- minimum frames per seconds
local X, Y, W, H = 100, 200, 160, 500 -- window position and size
local BGCOLOR = {0.10, 0.18, 0.24, 1.0} -- background color
local R, G, B, A = table.unpack(BGCOLOR)
local DEFAULT_FONT_PATH = nil --  full path filename of a ttf file (optional)

-------------------------------------------------------------------------------
-- Statechart
-------------------------------------------------------------------------------
-- This statechart defines the behavior of the semaphore:
-- initially red, switches to green after 5s, then to yellow after 3s,
-- then back to red after 2s. Repeats this cycle indefinitely.
-- Expects a global set_light() function to be defined in its environment
-- to switch on one light and off the other ones.

local statechart = _scxml{ name='semaphore', initial='red',
   _state{ id='red',
      _onentry{ 
         _script{ text=[[set_light('red')]] },
         _log{ expr="'Semaphore is red'" },
         _send{ event='timeout', delay='5s' },
      },
      _transition{ event='timeout', target='green' },
   },
   _state{ id='green',
      _onentry{ 
         _script{ text=[[set_light('green')]] },
         _log{ expr="'Semaphore is green'" },
         _send{ event='timeout', delay='3s' },
      },
      _transition{ event='timeout', target='yellow' },
   },
   _state{ id='yellow',
      _onentry{ 
         _script{ text=[[set_light('yellow')]] },
         _log{ expr="'Semaphore is yellow'" },
         _send{ event='timeout', delay='2s' },
      },
      _transition{ event='timeout', target='red' },
   }
}

-------------------------------------------------------------------------------
-- GUI
-------------------------------------------------------------------------------

local RED, DARK_RED = {1, 0, 0, 1}, {.3, 0, 0, 1}
local GREEN, DARK_GREEN = {0, 1, 0, 1}, {0, .3, 0, 1}
local YELLOW, DARK_YELLOW = {1, 1, 0, 1}, {.3, .3, 0, 1}
local red_light, green_light, yellow_light -- color of the 3 lights

local function set_light(on)
-- The statechart will call this to switch one light on and the others off
   red_light = on=='red' and RED or DARK_RED
   green_light = on=='green' and GREEN or DARK_GREEN
   yellow_light = on=='yellow' and YELLOW or DARK_YELLOW
end

local function draw_gui(ctx)
   if nk.window_begin(ctx, "GUI", {0, 0, W, H}, nk.WINDOW_NO_SCROLLBAR) then
      local canvas = nk.window_get_canvas(ctx)
      canvas:fill_circle({10, 20, 140, 140}, red_light)
      canvas:fill_circle({10, 180, 140, 140}, yellow_light)
      canvas:fill_circle({10, 340, 140, 140}, green_light)
   end
   nk.window_end(ctx)
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------
-- GL/GLFW inits
glfw.version_hint(3, 3, 'core')
glfw.window_hint('resizable', false)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
glfw.set_window_pos(window, X, Y)
gl.init()

-- Initialize the backend
local ctx = backend.init(window, {
   vbo_size = 512*1024,
   ebo_size = 128*1024,
   anti_aliasing = true,
   clipboard = false,
   callbacks = true,
   circle_segment_count = 48,
})

-- Load fonts
local atlas = backend.font_stash_begin()
local default_font = atlas:add(13, DEFAULT_FONT_PATH)
backend.font_stash_end(ctx, default_font)

-- Set callbacks
glfw.set_key_callback(window, function (window, key, scancode, action, shift, control, alt, super)
   if key == 'escape' and action == 'press' then
      glfw.set_window_should_close(window, true)
   end
   backend.key_callback(window, key, scancode, action, shift, control, alt, super)
end)

moonsc.set_log_callback(function(sessionid, label, expr) print(expr) end)

-- Create a running instance of the statechart (i.e. a session):
local sessionid = moonsc.generate_sessionid()
moonsc.create(sessionid, statechart)
-- Add the set_light() function to the session's dedicated environment,
-- so that we can change the GUI aspect from the statechart:
moonsc.get_env(sessionid)['set_light'] = set_light
-- Start the statechart:
moonsc.start(sessionid)

local tnext = now() -- next time moonsc.trigger() must be called
local dtmax = 1/FPS -- max wait interval (for responsiveness)
local function limit(dt) -- limits a time interval between 0 and dtmax
   return dt < 0 and 0 or (dt > dtmax and dtmax or dt)
end

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   -- Wait for input events:
   local dt = limit(tnext-now())
   glfw.wait_events_timeout(dt)
   -- Execute the logic
   tnext = moonsc.trigger()
   if not tnext then break end -- no more sessions running in the system
   -- Start a new frame:
   backend.new_frame()
   -- Draw the GUI:
   draw_gui(ctx)
   -- Render:
   W, H = glfw.get_window_size(window)
   gl.viewport(0, 0, W, H)
   gl.clear_color(R, G, B, A)
   gl.clear('color')
   backend.render()
   glfw.swap_buffers(window)
   collectgarbage()
end

backend.shutdown()

