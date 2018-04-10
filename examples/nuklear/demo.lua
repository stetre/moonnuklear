#!/usr/bin/env lua

local glfw = require("moonglfw")
local gl = require("moongl")
local nk = require("moonnuklear")

local renderer = require("renderer")
local floor = math.floor

local W, H = 1200, 800 -- window width and height
local TITLE = "MoonNuklear Demo"

local FPS = 30 -- frames per seconds
local VBO_SIZE = 512 * 1024
local EBO_SIZE =  128 * 1024
local ANTI_ALIASING = true
local INSTALL_CALLBACKS = true
local BG_COLOR = {0.10, 0.18, 0.24, 1.0}
local R, G, B, A = table.unpack(BG_COLOR)
local THEME = 'default'

-- @@ nk.trace_objects(true)

-- This are some code examples to provide a small overview of what can be done
-- with this library
local style = require("style")
local overview = require("overview")
local calculator = require("calculator")
local node_editor = require("node_editor")

-- GL/GLFW inits
glfw.version_hint(3, 3, 'core')
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()
local width, height = glfw.get_window_size(window)
gl.viewport(0, 0, W, H)

local ctx = renderer.init(window, VBO_SIZE, EBO_SIZE, ANTI_ALIASING, INSTALL_CALLBACKS)

local atlas = renderer.font_stash_begin()
-- Load Fonts: if none of these are loaded a default font will be used
local def_font = atlas:add(13)
local droid = atlas:add(14, "fonts/DroidSans.ttf")
local roboto = atlas:add(14, "fonts/Roboto-Regular.ttf")
local future = atlas:add(13, "fonts/kenvector_future_thin.ttf")
local clean = atlas:add(12, "fonts/ProggyClean.ttf")
local tiny = atlas:add(10, "fonts/ProggyTiny.ttf")
local cousine = atlas:add(13, "fonts/Cousine-Regular.ttf")
renderer.font_stash_end(ctx, def_font)
-- Load Cursor: if you uncomment cursor loading please hide the cursor
-- nk_style_load_all_cursors(ctx, atlas->cursors) --@@

-- nk.style_set_font(ctx, droid)

local window_flags = nk.panelflags('border', 'movable', 'scalable', 'minimizable', 'title')
-- Alt: local window_flags = nk.WINDOW_BORDER|nk.WINDOW_MOVABLE|nk.WINDOW_SCALABLE|
--                           nk.WINDOW_MINIMIZABLE|nk.WINDOW_TITLE

local gui = { op = 'easy', property = 20 }

function set_op(op)
   if op == gui.op then return end
   gui.op = op
   print("op is now '"..gui.op.."'")
end

function set_property(property)
   if property == gui.property then return end
   gui.property = property
   print("property is now "..gui.property.."")
end

local function set_style(ctx, theme)
   THEME = theme
   style(ctx, THEME)
end

set_style(ctx, THEME)

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(1/FPS) --glfw.poll_events()
   -- input
   renderer.new_frame()
   if nk.window_begin(ctx, "Demo", {50, 50, 400, 250}, window_flags) then
      --  GUI 
      nk.layout_row_static(ctx, 30, 80, 1)
      if nk.button(ctx, nil, "button") then
         print("button pressed")
      end

      nk.layout_row_dynamic(ctx, 30, 2)
      if nk.option(ctx, "easy", gui.op == 'easy') then set_op('easy') end
      if nk.option(ctx, "hard", gui.op == 'hard') then set_op('hard') end

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "theme:", nk.TEXT_LEFT)
      nk.layout_row_dynamic(ctx, 30, 5)
      if nk.option(ctx, 'default', THEME == 'default') then set_style(ctx, 'default') end
      if nk.option(ctx, 'white', THEME == 'white') then set_style(ctx, 'white') end
      if nk.option(ctx, 'red', THEME == 'red') then set_style(ctx, 'red') end
      if nk.option(ctx, 'blue', THEME == 'blue') then set_style(ctx, 'blue') end
      if nk.option(ctx, 'dark', THEME == 'dark') then set_style(ctx, 'dark') end

      nk.layout_row_dynamic(ctx, 25, 1)
      set_property(nk.property(ctx, "Compression:", 0, gui.property, 100, 10, 1))

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "background:", nk.TEXT_LEFT)
      nk.layout_row_dynamic(ctx, 25, 1)
      if nk.combo_begin(ctx, BG_COLOR, nil, { nk.widget_width(ctx),400 }) then
         nk.layout_row_dynamic(ctx, 120, 1)
         BG_COLOR = nk.color_picker(ctx, BG_COLOR, 'rgba')
         R, G, B, A = table.unpack(BG_COLOR)
         nk.layout_row_dynamic(ctx, 25, 1)
         R = nk.property(ctx, "#R:", 0, R, 1.0, 0.01,0.005)
         G = nk.property(ctx, "#G:", 0, G, 1.0, 0.01,0.005)
         B = nk.property(ctx, "#B:", 0, B, 1.0, 0.01,0.005)
         A = nk.property(ctx, "#A:", 0, A, 1.0, 0.01,0.005)
         BG_COLOR = { R, G, B, A }
         nk.combo_end(ctx)
      end
   end
   nk.window_end(ctx)

   -------------- EXAMPLES ----------------
   calculator(ctx)
   overview(ctx)
   node_editor(ctx)

   -- Draw
   width, height = glfw.get_window_size(window)
   gl.viewport(0, 0, width, height)
   gl.clear_color(R, G, B, A)
   gl.clear('color')
   renderer.render()
   glfw.swap_buffers(window)
   collectgarbage()
end
renderer.shutdown()

