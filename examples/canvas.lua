#!/usr/bin/env lua
-- This is a Lua porting of the canvas example that comes with Nuklear
-- (nuklear/example/canvas.c).

local nk = require("moonnuklear")
local backend = require("backend")

local ctx

local function canvasgui(ctx)
   local W, H = backend.get_window_size()
-- local X, Y = backend.get_window_pos()
   -- save style properties which will be overwritten
   local panel_padding = nk.style_get_vec2(ctx, 'window.padding')
   local item_spacing = nk.style_get_vec2(ctx, 'window.spacing')
   local window_background = nk.style_get_style_item(ctx, 'window.fixed_background')
   -- use the complete window space and set background
   nk.style_set_vec2(ctx, 'window.padding', {0, 0})
   nk.style_set_vec2(ctx, 'window.spacing', {0, 0})
   nk.style_set_style_item(ctx, 'window.fixed_background', {.98, .98, .98})

   -- create/update window and set position + size
   nk.window_set_bounds(ctx, "Window", {0,0,W,H})
   if nk.window_begin(ctx, "Window", {0,0,W,H}, nk.WINDOW_NO_SCROLLBAR) then
      -- allocate the complete window space for drawing
      local total_space = nk.window_get_content_region(ctx)
      nk.layout_row_dynamic(ctx, total_space[4], 1)
      nk.widget(ctx, total_space)
      local canvas = nk.window_get_canvas(ctx)

      local rgb = nk.color_from_bytes
      canvas:fill_rect({15,15,210,210}, 5, rgb(247, 230, 154))
      canvas:fill_rect({20,20,200,200}, 5, rgb(188, 174, 118))
      canvas:draw_text({30, 30, 150, 20}, "Text to draw", ctx:font(), rgb(188,174,118), rgb(0,0,0))

      canvas:fill_rect({250,20,100,100}, 0, rgb(0,0,255))
      canvas:fill_circle({20,250,100,100}, rgb(255,0,0))
      canvas:fill_triangle(250, 250, 350, 250, 300, 350, rgb(0,255,0))
      canvas:fill_arc(300, 180, 50, 0, math.pi*3/4, rgb(255,255,0))

      local points = {{200, 250}, {250, 350}, {225, 350}, {200, 300}, {175, 350}, {150, 350}}
      canvas:fill_polygon(points, rgb(0,0,0))

      canvas:stroke_line(15, 10, 200, 10, 2.0, rgb(189,45,75))
      canvas:stroke_rect({370, 20, 100, 100}, 10, 3, rgb(0,0,255))
      canvas:stroke_curve(380, 200, 405, 270, 455, 120, 480, 200, 2, rgb(0,150,220))
      canvas:stroke_circle({20, 370, 100, 100}, 5, rgb(0,255,120))
      canvas:stroke_triangle(370, 250, 470, 250, 420, 350, 6, rgb(255,0,143))
   end
   nk.window_end(ctx)

   -- restore style properties
   nk.style_set_vec2(ctx, 'window.padding', panel_padding)
   nk.style_set_vec2(ctx, 'window.spacing', item_spacing)
   nk.style_set_style_item(ctx, 'window.fixed_background', window_background)
end

-- Init the backend and enter the event loop:
ctx = backend.init(1200, 800, "Canvas", true, nil)
backend.loop(canvasgui, {.2, .2, .2, 1}, 30)

