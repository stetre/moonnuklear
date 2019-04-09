#!/usr/bin/env lua
-- Backend wrapper for the hello.lua example.
-- Wraps the glbackend.lua shipped with MoonNuklear, just to remove
-- backend noise from the Hello World example.

local glfw = require("moonglfw")
local gl = require("moongl")
local backend = require("moonnuklear.glbackend")
local nk = require("moonnuklear")

local TITLE = "Example"
local W, H = 1200, 800 -- window width and height
local BGCOLOR = {0.10, 0.18, 0.24, 1.0}
local THEME = 'default'
local window, ctx, atlas

-------------------------------------------------------------------------------
local function init(width, height, title, anti_aliasing, font_path)
-------------------------------------------------------------------------------
-- Initializes the backend.
-- width, height: initial dimensions of the window
-- title: window title
-- anti_aliasing: if =true then AA is turned on
-- font_path: optional full path filename of a ttf file

   -- GL/GLFW inits
   glfw.version_hint(3, 3, 'core')
   window = glfw.create_window(W, H, TITLE)
   glfw.make_context_current(window)
   gl.init()
   W, H = glfw.get_window_size(window)
   gl.viewport(0, 0, W, H)

   ctx = backend.init(window, {
      vbo_size = 512*1024,
      ebo_size = 128*1024,
      anti_aliasing = anti_aliasing,
      clipboard = true,
      callbacks = true
   })

   atlas = backend.font_stash_begin()
   -- Load Fonts: if none of these are loaded a default font will be used
   local def_font = atlas:add(13, font_path) -- default font
   backend.font_stash_end(ctx, def_font)

   glfw.set_key_callback(window, function (window, key, scancode, action, shift, control, alt, super)
      if key == 'escape' and action == 'press' then
         glfw.set_window_should_close(window, true)
      end
      backend.key_callback(window, key, scancode, action, shift, control, alt, super)
   end)

   return ctx
end

-------------------------------------------------------------------------------
local function loop(guifunc, bgcolor, fps)
-------------------------------------------------------------------------------
-- Enters the main event loop.
-- guifunc: a function implementing the front-end of the application.
-- bgcolor: background color (optional, defaults to BGCOLOR)
-- fps: desired frames per seconds (optional, defaults to 30)
--
-- The guifunc is executed at each frame as guifunc(ctx), where ctx is
-- the Nuklear context.
--
   local fps = fps or 30 -- frames per second
   local bgcolor = bgcolor or BGCOLOR
   local R, G, B, A = table.unpack(bgcolor)

   collectgarbage()
   collectgarbage('stop')

   while not glfw.window_should_close(window) do
      glfw.wait_events_timeout(1/fps) --glfw.poll_events()
      backend.new_frame()

      -- Draw the GUI ----------------
      guifunc(ctx)
      --------------------------------

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
end

return {
   init = init,
   loop = loop,
}

