#!/usr/bin/env lua

local nk = require("moonnuklear")
local backend = require("backend")

local op = 'easy'
local value = 0.6
local window_flags = nk.WINDOW_BORDER|nk.WINDOW_MOVABLE|nk.WINDOW_CLOSABLE

local function hellogui(ctx)
   if nk.window_begin(ctx, "Show", {50, 50, 220, 220}, window_flags) then
      -- fixed widget pixel width
      nk.layout_row_static(ctx, 30, 80, 1)

      if nk.button(ctx, nil, "button") then
         -- ... event handling ...
         print("button pressed")
      end

      -- fixed widget window ratio width
      nk.layout_row_dynamic(ctx, 30, 2)
      if nk.option(ctx, 'easy', op == 'easy') then op = 'easy' end
      if nk.option(ctx, 'hard', op == 'hard') then op = 'hard' end

      -- custom widget pixel width
      nk.layout_row_begin(ctx, 'static', 30, 2)
      nk.layout_row_push(ctx, 50)
      nk.label(ctx, "Volume:", nk.TEXT_LEFT)
      nk.layout_row_push(ctx, 110)
      value = nk.slider(ctx, 0, value, 1.0, 0.1)
      nk.layout_row_end(ctx)
   end
   nk.window_end(ctx)
end

-- Init the backend and enter the event loop:
backend.init(640, 380, "Hello", true, nil)
backend.loop(hellogui, {.13, .29, .53, 1}, 30)

