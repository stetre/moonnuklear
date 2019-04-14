#!/usr/bin/env lua
-- Layout APIs example - layout.lua
-- Derived from the demo that comes with Nuklear.

local glfw = require("moonglfw")
local gl = require("moongl")
local backend = require("moonnuklear.glbackend")
local nk = require("moonnuklear")

local TITLE = "Layout"
local FPS = 30 -- frames per second
local W, H = 1200, 800 -- window width and height
local BGCOLOR = {0.10, 0.18, 0.24, 1.0}
local R, G, B, A = table.unpack(BGCOLOR)
local FONT_PATH = nil -- @@ 
local WINDOW_FLAGS = nk.panelflags('title', 'border', 'movable', 'scalable')
local PARAMETERS = { -- backend parameters
   vbo_size = 512*1024,
   ebo_size = 128*1024,
   anti_aliasing = true,
   clipboard = true,
   callbacks = true
}

local function set_bgcolor(color)
   BGCOLOR = color or BGCOLOR
   R, G, B, A = table.unpack(BGCOLOR)
end

local LEFT = nk.TEXT_LEFT

-------------------------------------------------------------------------------
local function draw_gui(ctx)
-------------------------------------------------------------------------------
   if nk.window_begin(ctx, "Nuklear Layout APIs", {40, 40, 600, 480}, WINDOW_FLAGS) then
      nk.style_push_color(ctx, 'button.border_color', {1, 0, 0, 1})

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_row_dynamic():", LEFT)
      nk.layout_row_dynamic(ctx, 20, 3)
      nk.button(ctx, nil, "1")
      nk.button(ctx, nil, "2")
      nk.button(ctx, nil, "3")
      nk.button(ctx, nil, "4")
      nk.button(ctx, nil, "5")

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_row_static():", LEFT)
      nk.layout_row_static(ctx, 20, 120, 3)
      nk.button(ctx, nil, "1")
      nk.button(ctx, nil, "2")
      nk.button(ctx, nil, "3")
      nk.button(ctx, nil, "4")
      nk.button(ctx, nil, "5")

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_row(dynamic):",LEFT)
      nk.layout_row(ctx, 'dynamic', 20, {0.2, 0.6, 0.2})
      nk.button(ctx, nil, "1")
      nk.button(ctx, nil, "2")
      nk.button(ctx, nil, "3")
      nk.button(ctx, nil, "4")
      nk.button(ctx, nil, "5")

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_row(static):",LEFT )
      nk.layout_row(ctx, 'static', 20, {100, 200, 50})
      nk.button(ctx, nil, "1")
      nk.button(ctx, nil, "2")
      nk.button(ctx, nil, "3")
      nk.button(ctx, nil, "4")
      nk.button(ctx, nil, "5")

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_row_begin/push/end(dynamic):",LEFT)
      nk.layout_row_begin(ctx, 'dynamic', 20, 3)
      nk.layout_row_push(ctx, 0.2)
      nk.button(ctx, nil, "1")
      nk.layout_row_push(ctx, 0.6)
      nk.button(ctx, nil, "2")
      nk.layout_row_push(ctx, 0.2)
      nk.button(ctx, nil, "3")
      nk.layout_row_end(ctx)

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_row_begin/push/end(static):",LEFT)
      nk.layout_row_begin(ctx, 'static', 20, 3)
      nk.layout_row_push(ctx, 100)
      nk.button(ctx, nil, "1")
      nk.layout_row_push(ctx, 200)
      nk.button(ctx, nil, "2")
      nk.layout_row_push(ctx, 50)
      nk.button(ctx, nil, "3")
      nk.button(ctx, nil, "4")
      nk.button(ctx, nil, "5")
      nk.button(ctx, nil, "6")
      nk.button(ctx, nil, "7")
      nk.button(ctx, nil, "8")
      nk.layout_row_end(ctx)

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_row_template_begin/push/end():",LEFT)
      nk.layout_row_template_begin(ctx, 20)
      nk.layout_row_template_push_dynamic(ctx)
      nk.layout_row_template_push_variable(ctx, 80)
      nk.layout_row_template_push_static(ctx, 80)
      nk.layout_row_template_end(ctx)
      nk.button(ctx, nil, "1")
      nk.button(ctx, nil, "2")
      nk.button(ctx, nil, "3")
      nk.button(ctx, nil, "4")
      nk.button(ctx, nil, "5")
      nk.button(ctx, nil, "6")
      nk.button(ctx, nil, "7")
      nk.button(ctx, nil, "8")

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_space_begin/push/end(static):",LEFT)
      nk.layout_space_begin(ctx, 'static', 40, 4)
      nk.layout_space_push(ctx, {100, 0, 100, 20})
      nk.button(ctx, nil, "1")
      nk.layout_space_push(ctx, {0, 10, 100, 20})
      nk.button(ctx, nil, "2")
      nk.layout_space_push(ctx, {200, 10, 100, 20})
      nk.button(ctx, nil, "3")
      nk.layout_space_push(ctx, {100, 20, 100, 20})
      nk.button(ctx, nil, "4")
      nk.layout_space_end(ctx)
 
      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "layout_space_begin/push/end(dynamic):",LEFT)
      nk.layout_space_begin(ctx, 'dynamic', 40, 4)
      nk.layout_space_push(ctx, {0.15, 0, 0.15, .5})
      nk.button(ctx, nil, "1")
      nk.layout_space_push(ctx, {0, .25, 0.15, .5})
      nk.button(ctx, nil, "2")
      nk.layout_space_push(ctx, {.3, .25, .15, .5})
      nk.button(ctx, nil, "3")
      nk.layout_space_push(ctx, {.15, .5, .15, .5})
      nk.button(ctx, nil, "4")
      nk.layout_space_end(ctx)
 

      nk.style_pop_color(ctx)
   end
   nk.window_end(ctx)
end

-------------------------------------------------------------------------------
-- Main
-------------------------------------------------------------------------------

-- GL/GLFW inits
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

local ctx = backend.init(window, PARAMETERS)

local atlas = backend.font_stash_begin()
-- Load Fonts: if none of these are loaded a default font will be used
local def_font = atlas:add(13, FONT_PATH) -- default font
backend.font_stash_end(ctx, def_font)

glfw.set_key_callback(window, function (window, key, scancode, action, shift, control, alt, super)
   if key == 'escape' and action == 'press' then
      glfw.set_window_should_close(window, true)
   end
   backend.key_callback(window, key, scancode, action, shift, control, alt, super)
end)

-- Enter the main event loop.
collectgarbage()
collectgarbage('stop')

while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(1/FPS) --glfw.poll_events()
   backend.new_frame()
   -- Draw the GUI
   draw_gui(ctx)
   -- Render
   W, H = glfw.get_window_size(window)
   gl.viewport(0, 0, W, H)
   gl.clear_color(R, G, B, A)
   gl.clear('color')
   backend.render()
   glfw.swap_buffers(window)
   collectgarbage()
end

backend.shutdown()

