#!/usr/bin/env lua
-- This is a Lua porting of the demo that comes with Nuklear (nuklear/demo/).

local nk = require("moonnuklear")
local backend = require("backend")
-- These are some examples to provide a small overview of what can be done
-- with this library:
local style = require("style")
local overview = require("overview")
local calculator = require("calculator")
local node_editor = require("node_editor")

local ctx

local THEME = 'default'
local BGCOLOR = {0.10, 0.18, 0.24, 1.0}
local R, G, B, A = table.unpack(BGCOLOR)
local GUI = { op = 'easy', property = 20 }

local function set_op(op)
   if op == GUI.op then return end
   GUI.op = op
   print("op is now '"..GUI.op.."'")
end

local function set_property(property)
   if property == GUI.property then return end
   GUI.property = property
   print("property is now "..GUI.property.."")
end

local function set_style(ctx, theme)
   THEME = theme
   style(ctx, THEME)
end

local window_flags = nk.panelflags('border', 'movable', 'scalable', 'minimizable', 'title')
-- Alternatively: local window_flags = nk.WINDOW_BORDER|nk.WINDOW_MOVABLE| ...

local function demogui(ctx)
   if nk.window_begin(ctx, "Demo", {50, 50, 400, 250}, window_flags) then
      --  GUI 
      nk.layout_row_static(ctx, 30, 80, 1)
      if nk.button(ctx, nil, "button") then
         print("button pressed")
      end

      nk.layout_row_dynamic(ctx, 30, 2)
      if nk.option(ctx, "easy", GUI.op == 'easy') then set_op('easy') end
      if nk.option(ctx, "hard", GUI.op == 'hard') then set_op('hard') end

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "theme:", nk.TEXT_LEFT)
      nk.layout_row_dynamic(ctx, 30, 5)
      if nk.option(ctx, 'default', THEME == 'default') then set_style(ctx, 'default') end
      if nk.option(ctx, 'white', THEME == 'white') then set_style(ctx, 'white') end
      if nk.option(ctx, 'red', THEME == 'red') then set_style(ctx, 'red') end
      if nk.option(ctx, 'blue', THEME == 'blue') then set_style(ctx, 'blue') end
      if nk.option(ctx, 'dark', THEME == 'dark') then set_style(ctx, 'dark') end

      nk.layout_row_dynamic(ctx, 25, 1)
      set_property(nk.property(ctx, "Compression:", 0, GUI.property, 100, 10, 1))

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "background:", nk.TEXT_LEFT)
      nk.layout_row_dynamic(ctx, 25, 1)
      if nk.combo_begin(ctx, BGCOLOR, nil, { nk.widget_width(ctx),400 }) then
         nk.layout_row_dynamic(ctx, 120, 1)
         BGCOLOR = nk.color_picker(ctx, BGCOLOR, 'rgba')
         R, G, B, A = table.unpack(BGCOLOR)
         nk.layout_row_dynamic(ctx, 25, 1)
         R = nk.property(ctx, "#R:", 0, R, 1.0, 0.01,0.005)
         G = nk.property(ctx, "#G:", 0, G, 1.0, 0.01,0.005)
         B = nk.property(ctx, "#B:", 0, B, 1.0, 0.01,0.005)
         A = nk.property(ctx, "#A:", 0, A, 1.0, 0.01,0.005)
         BGCOLOR = { R, G, B, A }
         backend.set_bgcolor(BGCOLOR)
         nk.combo_end(ctx)
      end
   end
   nk.window_end(ctx)

   calculator(ctx)
   overview(ctx)
   node_editor(ctx)
end

-- Init the backend and enter the event loop:
ctx = backend.init(1200, 800, "MoonNuklear Demo", true, nil)
set_style(ctx, THEME)
backend.loop(demogui, BGCOLOR, 30)

