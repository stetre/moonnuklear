#!/usr/bin/env lua
-- Application template.
-- Uses the GLFW/OpenGL backend shipped with MoonNuklear.

local glfw = require("moonglfw")
local gl = require("moongl")
local backend = require("moonnuklear.glbackend")
local nk = require("moonnuklear")

local TITLE = "Template" -- GLFW window title
local FPS = 30 -- desired frames per seconds
local W, H = 800, 640 -- window width and height
local BGCOLOR = {0.10, 0.18, 0.24, 1.0} -- background color
local VBO_SIZE, EBO_SIZE = 512*1024, 128*1024 -- size of GL buffers
local ANTI_ALIASING = true -- use anti-aliasing
local CLIPBOARD = false -- use clipboard
local DEFAULT_FONT_PATH = nil --  full path filename of a ttf file (optional)

local R, G, B, A
local window, ctx, atlas

local function set_bgcolor(color)
   BGCOLOR = color or BGCOLOR
   R, G, B, A = table.unpack(BGCOLOR)
end
set_bgcolor()

-- GL/GLFW inits
glfw.version_hint(3, 3, 'core')
window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()

-- Initialize the backend
ctx = backend.init(window, {
   vbo_size = VBO_SIZE,
   ebo_size = EBO_SIZE,
   anti_aliasing = ANTI_ALIASING,
   clipboard = CLIPBOARD,
   callbacks = true
})

-- Load fonts: if none of these are loaded a default font will be used
atlas = backend.font_stash_begin()
local default_font = atlas:add(13, DEFAULT_FONT_PATH)
local droid = atlas:add(14, "fonts/DroidSans.ttf")
local roboto = atlas:add(14, "fonts/Roboto-Regular.ttf")
local future = atlas:add(13, "fonts/kenvector_future_thin.ttf")
local clean = atlas:add(12, "fonts/ProggyClean.ttf")
local tiny = atlas:add(10, "fonts/ProggyTiny.ttf")
local cousine = atlas:add(13, "fonts/Cousine-Regular.ttf")
backend.font_stash_end(ctx, default_font)

glfw.set_key_callback(window, function (window, key, scancode, action, shift, control, alt, super)
   if key == 'escape' and action == 'press' then
      glfw.set_window_should_close(window, true)
   end
   backend.key_callback(window, key, scancode, action, shift, control, alt, super)
end)

collectgarbage()
collectgarbage('stop')

local window_flags = nk.WINDOW_BORDER|nk.WINDOW_MOVABLE|nk.WINDOW_CLOSABLE|nk.WINDOW_SCALABLE

while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(1/FPS) --glfw.poll_events()
   backend.new_frame()

   -- Draw the GUI --------------------------------------------
   if nk.window_begin(ctx, "GUI", {50, 50, 220, 220}, window_flags) then
   end
   nk.window_end(ctx)
   ------------------------------------------------------------

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

