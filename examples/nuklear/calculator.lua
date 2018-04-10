-- calculator.lua
local nk = require("moonnuklear")
local fmt = string.format

local ab, current, op, result

local function reset(a)
   ab, current, op, result = {a, 0}, 1, nil, nil
end

local function cancel() 
   reset(0)
end

local function digit(key) 
   if result then reset(0) end
   if op and current == 1 then current = 2 end
   ab[current] = ab[current]*10.0 + tonumber(key)
end

local function operation(key)
   if result then reset(ab[1]) end
   if not op then op = key end
end

local function equals()
   if not op then return
   elseif op == '+' then ab[1] = ab[1] + ab[2]
   elseif op == '-' then ab[1] = ab[1] - ab[2]
   elseif op == '*' then ab[1] = ab[1] * ab[2]
   elseif op == '/' then ab[1] = ab[1] / ab[2]
   end
   current = 1
   op = nil
   result = true
end

local function button(ctx, key, callback)
   if nk.button(ctx, nil, key) then callback(key) end
end


local flags = nk.panelflags('border', 'no scrollbar', 'movable')

reset(0)

-----------------------------------------------------------------------------------

return function(ctx)
   if nk.window_begin(ctx, "Calculator", {10, 10, 180, 250}, flags) then

      nk.layout_row_dynamic(ctx, 35, 1)
      local out_text = nk.edit_string(ctx, nk.EDIT_SIMPLE, fmt("%.2f", ab[current]), 255, 'float')
      ab[current] = tonumber(out_text)

      nk.layout_row_dynamic(ctx, 35, 4)
      button(ctx, "7", digit)
      button(ctx, "8", digit)
      button(ctx, "9", digit)
      button(ctx, "+", operation)
      button(ctx, "4", digit)
      button(ctx, "5", digit)
      button(ctx, "6", digit)
      button(ctx, "-", operation)
      button(ctx, "1", digit)
      button(ctx, "2", digit)
      button(ctx, "3", digit)
      button(ctx, "*", operation)
      button(ctx, "C", cancel)
      button(ctx, "0", digit)
      button(ctx, "=", equals)
      button(ctx, "/", operation)
   end

   nk.window_end(ctx)
end

