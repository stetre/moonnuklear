-- overview.lua

local nk = require("moonnuklear")

-- window flags 
local window_flags = 0
local show_menu = true
local titlebar = true
local border = true
local resize = true
local movable = true
local no_scrollbar = false
local scale_left = false
local minimizable = true

-- popups 
local show_app_about = false

local LEFT, CENTERED, RIGHT  = nk.TEXT_LEFT, nk.TEXT_CENTERED, nk.TEXT_RIGHT
local fmt = function(...) return string.format(...) end
local floor, abs = math.floor, math.abs
local cos, sin = math.cos, math.sin

local STEP = 2*math.pi/32

-------------------------------------------------------------------------------
-- Menubar
-------------------------------------------------------------------------------

local menu1 = { prog=40, slider=10, check=true }
local menu2 = { state='NONE', values={26.0,13.0,30.0,15.0,25.0,10.0,20.0,40.0,12.0,8.0,22.0,28.0} }
local menuwidgets = { prog = 60, slider = 10, check = true }

local function Menubar(ctx)
   nk.menubar_begin(ctx)
   local state = menu2.state
   -- menu #1 -------------------------------------
   nk.layout_row_begin(ctx, 'static', 25, 5)
   nk.layout_row_push(ctx, 45)
   if nk.menu_begin(ctx, nil, "MENU", LEFT, {120, 200}) then
      nk.layout_row_dynamic(ctx, 25, 1)
      if nk.menu_item(ctx, nil, "Hide", LEFT) then show_menu = false end
      if nk.menu_item(ctx, nil, "About", LEFT) then show_app_about = true end
      menu1.prog = nk.progress(ctx, menu1.prog, 100, 'modifiable')
      menu1.slider = nk.slider(ctx, 0, menu1.slider, 16, 1)
      menu1.check = nk.checkbox(ctx, "check", menu1.check)
      nk.menu_end(ctx)
   end
   -- menu #2 -----------------------------------
   nk.layout_row_push(ctx, 60)
   if nk.menu_begin(ctx, nil, "ADVANCED", LEFT, {200, 600}) then
      if nk.tree_state_push(ctx, 'tab', "FILE", state=='FILE' and 'maximized' or 'minimized') then
         state = 'FILE'
         nk.menu_item(ctx, nil, "New", LEFT)
         nk.menu_item(ctx, nil, "Open", LEFT)
         nk.menu_item(ctx, nil, "Save", LEFT)
         nk.menu_item(ctx, nil, "Close", LEFT)
         nk.menu_item(ctx, nil, "Exit", LEFT)
         nk.tree_pop(ctx)
      elseif state == 'FILE' then state = 'NONE'
      elseif nk.tree_state_push(ctx, 'tab', "EDIT", state=='EDIT' and 'maximized' or 'minimized') then
         state = 'EDIT'
         nk.menu_item(ctx, nil, "Copy", LEFT)
         nk.menu_item(ctx, nil, "Delete", LEFT)
         nk.menu_item(ctx, nil, "Cut", LEFT)
         nk.menu_item(ctx, nil, "Paste", LEFT)
         nk.tree_pop(ctx)
      elseif state == 'EDIT' then state = 'NONE'
      elseif nk.tree_state_push(ctx, 'tab', "VIEW", state=='VIEW' and 'maximized' or 'minimized') then
         state = 'VIEW'
         nk.menu_item(ctx, nil, "About", LEFT)
         nk.menu_item(ctx, nil, "Options", LEFT)
         nk.menu_item(ctx, nil, "Customize", LEFT)
         nk.tree_pop(ctx)
      elseif state == 'VIEW' then state = 'NONE'
      elseif nk.tree_state_push(ctx, 'tab', "CHART", state=='CHART' and 'maximized' or 'minimized') then
         state = 'CHART'
         local values = menu2.values
         nk.layout_row_dynamic(ctx, 150, 1)
         nk.chart_begin(ctx, 'column', #values, 0, 50)
         for i = 1, #values do nk.chart_push(ctx, values[i]) end
         nk.chart_end(ctx)
         nk.tree_pop(ctx)
      elseif state == 'VIEW' then state = 'NONE' 
      end
      nk.menu_end(ctx)
   end
   -- menu widgets ------------------------------
   nk.layout_row_push(ctx, 70)
   menuwidgets.prog = nk.progress(ctx, menuwidgets.prog, 100, 'modifiable')
   menuwidgets.slider = nk.slider(ctx, 0, menuwidgets.slider, 16, 1)
   menuwidgets.check = nk.checkbox(ctx, "check", menuwidgets.check)
   ----------------------------------------------
   menu2.state = state
   nk.menubar_end(ctx)
end 

-------------------------------------------------------------------------------
-- Popup
-------------------------------------------------------------------------------

local function About(ctx)
   if nk.popup_begin(ctx, 'static', "About", nk.WINDOW_CLOSABLE, {20, 100, 300, 190}) then
      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "Nuklear", LEFT)
      nk.label(ctx, "By Micha Mettke", LEFT)
      nk.label(ctx, "nuklear is licensed under the",  LEFT)
      nk.label(ctx, "public domain License.",  LEFT)
      nk.popup_end(ctx)
   else 
      show_app_about = false
   end
end

-------------------------------------------------------------------------------
-- Checkbox
-------------------------------------------------------------------------------

local function WindowFlagsCheckbox(ctx)
   if nk.tree_push(ctx, 'tab', "Window", 'minimized', 'window_flags_checkbox') then
      nk.layout_row_dynamic(ctx, 30, 2)
      titlebar = nk.checkbox(ctx, "Titlebar", titlebar)
      show_menu = nk.checkbox(ctx, "Menu", show_menu)
      border = nk.checkbox(ctx, "Border", border)
      resize = nk.checkbox(ctx, "Resizable", resize)
      movable = nk.checkbox(ctx, "Movable", movable)
      no_scrollbar = nk.checkbox(ctx, "No Scrollbar", no_scrollbar)
      minimizable = nk.checkbox(ctx, "Minimizable", minimizable)
      scale_left = nk.checkbox(ctx, "Scale Left", scale_left)
      nk.tree_pop(ctx)
   end
end
 
-------------------------------------------------------------------------------
-- Widgets
-------------------------------------------------------------------------------

local function Text(ctx)
   if nk.tree_push(ctx, 'node', "Text", 'minimized', 'widgets text') then 
      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "Label aligned left", LEFT)
      nk.label(ctx, "Label aligned centered", CENTERED)
      nk.label(ctx, "Label aligned right", RIGHT)
      nk.label(ctx, "Blue text", LEFT, {0, 0 , 1, 1}) -- colored
      nk.label(ctx, "Yellow text", LEFT, {1,1,0}) -- colored
      nk.label(ctx, "Text without /0", RIGHT)
      nk.layout_row_static(ctx, 100, 200, 1)
      nk.label_wrap(ctx, "This is a very long line to hopefully get this text to be wrapped into multiple lines to show line wrapping")
      nk.layout_row_dynamic(ctx, 100, 1)
      nk.label_wrap(ctx, "This is another long text to show dynamic window changes on multiline text")
      nk.tree_pop(ctx)
   end
end

-------------------------------------------------

local function Buttons(ctx)
   if nk.tree_push(ctx, 'node', "Button", 'minimized', 'widgets buttons') then
      nk.layout_row_static(ctx, 30, 100, 3)
      if nk.button(ctx, nil, "Button") then print("Button pressed!") end
      nk.button_set_behavior(ctx, 'repeater')
      if nk.button(ctx, nil, "Repeater") then print("Repeater is being pressed!") end
      nk.button_set_behavior(ctx, 'default')
      nk.button(ctx, {0, 0, 1, 1})
      nk.layout_row_static(ctx, 25, 25, 8)
      nk.button(ctx, 'circle solid')
      nk.button(ctx, 'circle outline')
      nk.button(ctx, 'rect solid')
      nk.button(ctx, 'rect outline')
      nk.button(ctx, 'triangle up')
      nk.button(ctx, 'triangle down')
      nk.button(ctx, 'triangle left')
      nk.button(ctx, 'triangle right')
      nk.layout_row_static(ctx, 30, 100, 2)
      nk.button(ctx, 'triangle left', "prev", RIGHT)
      nk.button(ctx, 'triangle right', "next", LEFT)
      nk.tree_pop(ctx)
   end
end

-------------------------------------------------

local basic = { -- state for basic widgets
   checkbox = false,
   option = 'A', -- 'A'|'B'|'C'
   int_slider = 5, float_slider = 2.5,
   prog_value = 40, property_float = 2, property_int = 10, property_neg = 10,
   range_float_min = 0, range_float_max = 100, range_float_value = 50,
   range_int_min = 0, range_int_value = 2048, range_int_max = 4096,
   ratio = {120, 150},
}

local function Basic(ctx)
   if nk.tree_push(ctx, 'node', "Basic", 'minimized', 'widgets basic') then
      nk.layout_row_static(ctx, 30, 100, 1)
      basic.checkbox = nk.checkbox(ctx, "Checkbox", basic.checkbox)
      nk.layout_row_static(ctx, 30, 80, 3)
      basic.option = nk.option(ctx, "optionA", basic.option=='A') and 'A' or basic.option
      basic.option = nk.option(ctx, "optionB", basic.option=='B') and 'B' or basic.option
      basic.option = nk.option(ctx, "optionC", basic.option=='C') and 'C' or basic.option
      nk.layout_row(ctx, 'static', 30, basic.ratio)
      nk.label(ctx, "Slider int", LEFT)
      basic.int_slider = nk.slider(ctx, 0, basic.int_slider, 10, 1)
      nk.label(ctx, "Slider float", LEFT)
      basic.float_slider = nk.slider(ctx, 0, basic.float_slider, 5.0, 0.5)
      nk.label(ctx, fmt("Progressbar: %u" , basic.prog_value), LEFT)
      basic.prog_value = nk.progress(ctx, basic.prog_value, 100, 'modifiable')
      nk.layout_row(ctx, 'static', 25, basic.ratio)
      nk.label(ctx, "Property float:", LEFT)
      basic.property_float = nk.property(ctx, "Float:", 0, basic.property_float, 64.0, 0.1, 0.2)
      nk.label(ctx, "Property int:", LEFT)
      basic.property_int = nk.property(ctx, "Int:", 0, basic.property_int, 100.0, 1, 1)
      nk.label(ctx, "Property neg:", LEFT)
      basic.property_neg = nk.property(ctx, "Neg:", -10, basic.property_neg, 10, 1, 1)
      nk.layout_row_dynamic(ctx, 25, 1)
      nk.label(ctx, "Range:", LEFT)
      nk.layout_row_dynamic(ctx, 25, 3)
      basic.range_float_min = nk.property(ctx, "#min:", 
               0, basic.range_float_min, basic.range_float_max, 1.0, 0.2)
      basic.range_float_value = nk.property(ctx, "#float:", 
            basic.range_float_min, basic.range_float_value, basic.range_float_max, 1.0, 0.2)
      basic.range_float_max = nk.property(ctx, "#max:", 
            basic.range_float_min, basic.range_float_max, 100, 1.0, 0.2)
      basic.range_int_min = nk.property(ctx, "#min:", 
               -2^31, basic.range_int_min, basic.range_int_max, 1, 10)
      basic.range_int_value = nk.property(ctx, "#neg:", 
            basic.range_int_min, basic.range_int_value, basic.range_int_max, 1, 10)
      basic.range_int_max = nk.property(ctx, "#max:", 
            basic.range_int_min, basic.range_int_max, 2^31-1, 1, 10)
      nk.tree_pop(ctx)
   end
end

-------------------------------------------------

local selectable_list = {false, false, true, false}
local selectable_grid = {
   true,false,false,false,
   false,true,false,false,
   false,false,true,false,
   false,false,false,true
}

local function Selectable(ctx)
   if nk.tree_push(ctx, 'node', "Selectable", 'minimized', 'widgets selectable') then
      if nk.tree_push(ctx, 'node', "List", 'minimized', 'widgets selectable list') then
         nk.layout_row_static(ctx, 18, 100, 1)
         selectable_list[1] = nk.selectable(ctx, nil, "Selectable", LEFT, selectable_list[1])
         selectable_list[2] = nk.selectable(ctx, nil, "Selectable", LEFT, selectable_list[2])
         nk.label(ctx, "Not Selectable", LEFT)
         selectable_list[3] = nk.selectable(ctx, nil, "Selectable", LEFT, selectable_list[3])
         selectable_list[4] = nk.selectable(ctx, nil, "Selectable", LEFT, selectable_list[4])
         nk.tree_pop(ctx)
      end
      if nk.tree_push(ctx, 'node', "Grid", 'minimized', 'widgtes selectable grid') then
         nk.layout_row_static(ctx, 50, 50, 4)
         for i = 0, 15 do
            local changed
            selectable_grid[i+1], changed = nk.selectable(ctx, nil, "Z", CENTERED, selectable_grid[i+1])
            if changed then
               local x, y = i%4, floor(i/4)
               if x > 0 then selectable_grid[i] = not selectable_grid[i] end
               if x < 3 then selectable_grid[i+2] = not selectable_grid[i+2] end
               if y > 0 then selectable_grid[i-3] = not selectable_grid[i-3] end
               if y < 3 then selectable_grid[i+5] = not selectable_grid[i+5] end
            end
         end
         nk.tree_pop(ctx)
      end 
      nk.tree_pop(ctx)
   end
end

-------------------------------------------------

local MONTH = {"January", "February", "March", "April", "May", "June", "July", 
            "August", "September", "October", "November", "December"}
local DAY = {"SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"}
local MONTH_DAYS = {31,28,31,30,31,30,31,31,30,31,30,31}

local function firstdayof(year, month)
-- Returns the index (1-7, 1=Sun) for the first day of the given month (1-12) of the year (YYYY)
   local year = month < 3 and year-1 or year
   local y, c = year%100, floor(year/100)
   local y4, c4 = floor(y/4), floor(c/4)
   local m = floor(floor(2.6*((month+9)%12+1)) -.2)
   return ((2+m+y+y4+c4-2*c)%7+7)%7 + 1
end

local combo = {
   weapons = {"Fist","Pistol","Shotgun","Plasma","BFG"},
   current_weapon = 1, -- index in weapons
   color = nk.color_from_bytes(130, 50, 50, 255),
   color2 = {0.509, 0.705, 0.2, 1.0},
   col_mode = 'RGB',
   prog_a =  20, prog_b = 40, prog_c = 10, prog_d = 90,
   check_values = {false, false, false, false, false},
   position = {0, 0, 0},
   time_selected = false,
   date_selected = false,
   date = os.date("*t"),
   chart_selection = 8.0,
   chart_values = {26.0,13.0,30.0,15.0,25.0,10.0,20.0,40.0, 12.0, 8.0, 22.0, 28.0, 5.0},
}

local function Combo(ctx)
-- Combobox Widgets
-- In this library comboboxes are not limited to being a popup list of 
-- selectable text. Instead it is a abstract concept of having something 
-- that is *selected* or displayed, a popup window which opens if something
-- needs to be modified and the content of the popup which causes the 
-- *selected* or displayed value to change or if wanted close the combobox.
--
-- While strange at first handling comboboxes in a abstract way solves the
-- problem of overloaded window content. For example changing a color value
-- requires 4 value modifier (slider, property,...) for RGBA then you need
-- a label and ways to display the current color.
-- If you want to go fancy you even add rgb and hsv ratio boxes.
-- While fine for one color if you have a lot of them it because tedious to
-- look at and quite wasteful in space. You could add a popup which modifies
-- the color but this does not solve the fact that it still requires a lot 
-- of cluttered space to do.
--
-- In these kind of instance abstract comboboxes are quite handy. All value
-- modifiers are hidden inside the combobox popup and only the color is shown
-- if not open. This combines the clarity of the popup with the ease of use 
-- of just using the space for modifiers.
-- 
-- Other instances are for example time and especially date picker, which only
-- show the currently activated time/data and hide the selection logic inside
-- the combobox popup.
                 
   if nk.tree_push(ctx, 'node', "Combo", 'minimized', 'widgets combo') then
      -- default combobox ---------------------------------
      nk.layout_row_static(ctx, 25, 200, 1)
      combo.current_weapon = nk.combo(ctx, combo.weapons, combo.current_weapon, 25, {200,200})
      -- slider color combobox 
      if nk.combo_begin(ctx, combo.color, nil, {200,200}) then
         nk.layout_row(ctx, 'dynamic', 30, {0.15, 0.85})
         local r, g, b, a = table.unpack(combo.color)
         nk.label(ctx, "R:", LEFT)
         r = nk.slider(ctx, 0, r, 1.0, 5/255)
         nk.label(ctx, "G:", LEFT)
         g = nk.slider(ctx, 0, g, 1.0, 5/255)
         nk.label(ctx, "B:", LEFT)
         b = nk.slider(ctx, 0, b, 1.0, 5/255)
         nk.label(ctx, "A:", LEFT)
         a = nk.slider(ctx, 0, a, 1.0, 5/255)
         combo.color = {r, g, b, a}
         nk.combo_end(ctx)
      end
      -- complex color combobox ---------------------------
      if nk.combo_begin(ctx, combo.color2, nil, {200,400}) then
         nk.layout_row_dynamic(ctx, 120, 1)
         combo.color2 = nk.color_picker(ctx, combo.color2, 'rgba')
         nk.layout_row_dynamic(ctx, 25, 2)
         combo.col_mode = nk.option(ctx, "RGB", combo.col_mode == 'RGB') and 'RGB' or combo.col_mode
         combo.col_mode = nk.option(ctx, "HSV", combo.col_mode == 'HSV') and 'HSV' or combo.col_mode
         nk.layout_row_dynamic(ctx, 25, 1)
         if combo.col_mode == 'RGB' then
            local r, g, b, a = table.unpack(combo.color2)
            r = nk.property(ctx, "#R:", 0, r, 1.0, 0.01,0.005)
            g = nk.property(ctx, "#G:", 0, g, 1.0, 0.01,0.005)
            b = nk.property(ctx, "#B:", 0, b, 1.0, 0.01,0.005)
            a = nk.property(ctx, "#A:", 0, a, 1.0, 0.01,0.005)
            combo.color2 = { r, g, b, a }
         else
            local h, s, v, a = table.unpack(nk.rgba_to_hsva(combo.color2))
            h = nk.property(ctx, "#H:", 0, h, 1.0, 0.01,0.05)
            s = nk.property(ctx, "#S:", 0, s, 1.0, 0.01,0.05)
            v = nk.property(ctx, "#V:", 0, v, 1.0, 0.01,0.05)
            a = nk.property(ctx, "#A:", 0, a, 1.0, 0.01,0.05)
            combo.color2 = nk.hsva_to_rgba({h, s, v, a})
         end
         nk.combo_end(ctx)
      end
      -- progressbar combobox -----------------------------
      local sum = combo.prog_a + combo.prog_b + combo.prog_c + combo.prog_d
      if nk.combo_begin(ctx, nil, fmt("%u", sum), {200,200}) then
         nk.layout_row_dynamic(ctx, 30, 1)
         combo.prog_a = nk.progress(ctx, combo.prog_a, 100, 'modifiable')
         combo.prog_b = nk.progress(ctx, combo.prog_b, 100, 'modifiable')
         combo.prog_c = nk.progress(ctx, combo.prog_c, 100, 'modifiable')
         combo.prog_d = nk.progress(ctx, combo.prog_d, 100, 'modifiable')
         nk.combo_end(ctx)
      end

      -- checkbox combobox --------------------------------
      sum = 0
      for i, val in ipairs(combo.check_values) do if val then sum = sum + 1 end end
      if nk.combo_begin(ctx, nil, fmt("%u", sum), {200,200}) then
         nk.layout_row_dynamic(ctx, 30, 1)
         combo.check_values[1] = nk.checkbox(ctx, combo.weapons[1], combo.check_values[1])
         combo.check_values[2] = nk.checkbox(ctx, combo.weapons[2], combo.check_values[2])
         combo.check_values[3] = nk.checkbox(ctx, combo.weapons[3], combo.check_values[3])
         combo.check_values[4] = nk.checkbox(ctx, combo.weapons[4], combo.check_values[4])
         nk.combo_end(ctx)
      end
      -- complex text combobox ----------------------------
      local x, y, z = table.unpack(combo.position)
      if nk.combo_begin(ctx, nil, fmt("%.2f, %.2f, %.2f", x, y, z), {200,200}) then
         nk.layout_row_dynamic(ctx, 25, 1)
         x = nk.property(ctx, "#X:", -1024.0, x, 1024.0, 1,0.5)
         y = nk.property(ctx, "#Y:", -1024.0, y, 1024.0, 1,0.5)
         z = nk.property(ctx, "#Z:", -1024.0, z, 1024.0, 1,0.5)
         combo.position = {x, y, z}
         nk.combo_end(ctx)
      end
      -- chart combobox -----------------------------------
      if nk.combo_begin(ctx, nil, fmt("%.1f", combo.chart_selection), {200,250}) then
         nk.layout_row_dynamic(ctx, 150, 1)
         nk.chart_begin(ctx, 'column', #combo.chart_values, 0, 50)
            for i, value in ipairs(combo.chart_values) do
               local flags = nk.chart_push(ctx, value)
                  if flags & nk.CHART_CLICKED ~= 0 then
                     combo.chart_selection = value
                     nk.combo_close(ctx)
                  end
            end
         nk.chart_end(ctx)
         nk.combo_end(ctx)
      end

      local date, now = combo.date, os.date("*t")
      if not combo.time_selected then
         date.hour, date.min, date.sec = now.hour, now.min, now.sec
      end
      if not combo.date_selected then
         date.year, date.month, date.day = now.year, now.month, now.day
      end
      -- time combobox ------------------------------------
      local text = fmt("%02d:%02d:%02d", date.hour, date.min, date.sec)
      if nk.combo_begin(ctx, nil, text, {200,250}) then
         combo.time_selected = true
         nk.layout_row_dynamic(ctx, 25, 1)
         date.sec = nk.property(ctx, "#S:", 0, date.sec, 59, 1, 1)
         date.min = nk.property(ctx, "#M:", 0, date.min, 59, 1, 1)
         date.hour = nk.property(ctx, "#H:", 0, date.hour, 23, 1, 1)
         nk.combo_end(ctx)
      end
      -- date combobox ------------------------------------
      text = fmt("%02d-%02d-%02d", date.day, date.month, date.year)
      if nk.combo_begin(ctx, nil, text, {350,400}) then
         local days, year = MONTH_DAYS[date.month], date.year
         if date.month == 2 and ((year%4 == 0 and year%100 ~= 0) or (year%400 == 0)) then
            days = days + 1 -- leap year
         end
         -- header with month and year 
         combo.date_selected = true
         nk.layout_row_begin(ctx, 'dynamic', 20, 3)
         nk.layout_row_push(ctx, 0.05)
         if nk.button(ctx, 'triangle left') then
            if date.month == 1 then
               date.month, date.year = 12, math.max(0, date.year-1)
            else
               date.month = date.month - 1
            end
         end
         nk.layout_row_push(ctx, 0.9)
         nk.label(ctx, fmt("%s %d", MONTH[date.month], date.year), CENTERED)
         nk.layout_row_push(ctx, 0.05)
         if nk.button(ctx, 'triangle right') then
            if date.month == 12 then
               date.month, date.year = 1, date.year+1
            else
               date.month = date.month + 1
            end
         end
         nk.layout_row_end(ctx)
         -- weekdays
         local week_day = firstdayof(date.year, date.month)
         nk.layout_row_dynamic(ctx, 35, 7)
         for i = 1, 7 do
            nk.label(ctx, DAY[i], CENTERED)
         end
         if week_day > 1 then nk.spacing(ctx, week_day-1) end
         for i = 1, days do
            if nk.button(ctx, nil, fmt("%d", i)) then
               date.day = i
               nk.combo_close(ctx)
            end
         end
      nk.combo_end(ctx)
   end
   nk.tree_pop(ctx)
   end
end

-------------------------------------------------

local input = {
   text = {"", "", "", "", "", ""},
   password = "",
   field = "",
   box = "",
   submit = "",
   flags = 0,
}

local function Input(ctx)
   if nk.tree_push(ctx, 'node', "Input", 'minimized', 'input') then
      local ratio = {120, 150}
      nk.layout_row(ctx, 'static', 25, ratio)
      nk.label(ctx, "Default:", LEFT)
      input.text[1] = nk.edit_string(ctx, nk.EDIT_SIMPLE, input.text[1], 64, 'default')
      nk.label(ctx, "Int:", LEFT)
      input.text[2] = nk.edit_string(ctx, nk.EDIT_SIMPLE, input.text[2], 64, 'decimal')
      nk.label(ctx, "Float:", LEFT)
      input.text[3] = nk.edit_string(ctx, nk.EDIT_SIMPLE, input.text[3], 64, 'float')
      nk.label(ctx, "Hex:", LEFT)
      input.text[4] = nk.edit_string(ctx, nk.EDIT_SIMPLE, input.text[4], 64, 'hex')
      nk.label(ctx, "Octal:", LEFT)
      input.text[5] = nk.edit_string(ctx, nk.EDIT_SIMPLE, input.text[5], 64, 'oct')
      nk.label(ctx, "Binary:", LEFT)
      input.text[6] = nk.edit_string(ctx, nk.EDIT_SIMPLE, input.text[6], 64, 'binary')
      nk.label(ctx, "Password:", LEFT) --@@ rivedere
      local mask = string.rep('*', #input.password)
      input.password = nk.edit_string(ctx, nk.EDIT_FIELD, mask, 64, 'default')
--    nk.label(ctx, "Password: "..input.password, LEFT)
      nk.label(ctx, "Field:", LEFT)
      input.field = nk.edit_string(ctx, nk.EDIT_FIELD, input.field, 64, 'default')
      nk.label(ctx, "Box:", LEFT)
      nk.layout_row_static(ctx, 180, 278, 1)
      input.box = nk.edit_string(ctx, nk.EDIT_BOX, input.box, 512, 'default')
      nk.layout_row(ctx, 'static', 25, ratio)
      input.submit, input.flags = 
         nk.edit_string(ctx, nk.EDIT_FIELD|nk.EDIT_SIG_ENTER, input.submit, 64,  'ascii')
      if nk.button(ctx, nil, "Submit") or (input.flags & nk.EDIT_COMMITED ~= 0) then
         input.box = input.box..input.submit..'\n'
         input.submit = ""
      end
      nk.tree_pop(ctx)
   end
end

-------------------------------------------------------------------------------


local chart = {
   line_index = 0,
   col_index = 0,
}

local function Chart(ctx)
-- Chart Widgets
-- This library has two different rather simple charts. The line and the column chart.
-- Both provide a simple way of visualizing values and have a retained mode and immediate
-- mode API version. For the retain mode version `nk.plot` and `nk.plot_function` you
-- either provide an array or a callback to call to handle drawing the graph.
-- For the immediate mode version you start by calling `nk.chart_begin` and need to
-- provide min and max values for scaling on the Y-axis and then call `nk.chart_push`
-- to push values into the chart.
-- Finally `nk.chart_end` needs to be called to end the process. 
   if nk.tree_push(ctx, 'tab', "Chart", 'minimized', "widgets chart") then
      -- line chart ---------------------------------------
      local id, index = 0, 0
      nk.layout_row_dynamic(ctx, 100, 1)
      local bounds = nk.widget_bounds(ctx)
      if nk.chart_begin(ctx, 'lines', 32, -1.0, 1.0) then
         for i = 1, 32 do
            local res = nk.chart_push(ctx, cos(id))
            if res & nk.CHART_HOVERING ~= 0 then index = i end
            if res & nk.CHART_CLICKED ~= 0 then chart.line_index = i end
            id = id + STEP
         end
         nk.chart_end(ctx)
      end
      if index ~= 0 then nk.tooltip(ctx, fmt("Value: %.2f", cos((index-1)*STEP))) end
      if chart.line_index ~= 0 then
         nk.layout_row_dynamic(ctx, 20, 1)
         nk.label(ctx, fmt("Selected value: %.2f", cos((index-1)*STEP)), LEFT)
      end
      -- column chart -------------------------------------
      id, index = 0, 0
      nk.layout_row_dynamic(ctx, 100, 1)
      bounds = nk.widget_bounds(ctx)
      if nk.chart_begin(ctx, 'column', 32, 0.0, 1.0) then
         for i = 1, 32 do
            local res = nk.chart_push(ctx, abs(sin(id)))
            if res & nk.CHART_HOVERING ~= 0 then index = i end
            if res & nk.CHART_CLICKED ~= 0 then chart.col_index = i end
            id = id + STEP
         end
         nk.chart_end(ctx)
      end
      if index ~= 0 then nk.tooltip(ctx, fmt("Value: %.2f", abs(sin(STEP*(index-1))))) end
      if chart.col_index ~= 0 then
         nk.layout_row_dynamic(ctx, 20, 1)
         nk.label(ctx, fmt("Selected value: %.2f", abs(sin(STEP*(chart.col_index-1)))), LEFT)
      end
      -- mixed chart --------------------------------------
      nk.layout_row_dynamic(ctx, 100, 1)
      bounds = nk.widget_bounds(ctx)
      if nk.chart_begin(ctx, 'column', 32, 0.0, 1.0) then -- slot 1
         nk.chart_add_slot(ctx, 'lines', 32, -1.0, 1.0)   -- slot 2
         nk.chart_add_slot(ctx, 'lines', 32, -1.0, 1.0)   -- slot 3
         id = 0
         for i = 1, 32 do
            nk.chart_push(ctx, abs(sin(id)), 1) 
            nk.chart_push(ctx, cos(id), 2)
            nk.chart_push(ctx, sin(id), 3)
            id = id + STEP
         end
      end
      nk.chart_end(ctx)
      -- mixed colored chart ------------------------------
      nk.layout_row_dynamic(ctx, 100, 1)
      bounds = nk.widget_bounds(ctx)
      if nk.chart_begin(ctx, 'lines', 32, 0.0, 1.0, {1,0,0}, {150/255,0,0}) then   -- slot 1
         nk.chart_add_slot(ctx, 'lines',32, -1.0, 1.0, {0, 0, 1}, {0, 0, 150/255}) -- slot 2
         nk.chart_add_slot(ctx, 'lines', 32, -1.0, 1.0, {0,1,0}, {0,150/255,0})    -- slot 3
         id = 0
         for i = 1, 32 do
            nk.chart_push(ctx, abs(sin(id)), 1)
            nk.chart_push(ctx, cos(id), 2)
            nk.chart_push(ctx, sin(id), 3)
            id = id + STEP
         end
      end
      nk.chart_end(ctx)
      nk.tree_pop(ctx)
   end
end
 
-------------------------------------------------------------------------------

local popup = {
   color = {1, 0,0, 1},
   select = {false, false, false, false},
   active = false,
   prog = 40,
   slider = 10,
}

local function Popup(ctx) 
   if nk.tree_push(ctx, 'tab', "Popup", 'minimized', 'popup') then
      -- menu contextual ----------------------------------
      nk.layout_row_static(ctx, 30, 160, 1)
      local bounds = nk.widget_bounds(ctx)
      nk.label(ctx, "Right click me for menu", LEFT)
      if nk.contextual_begin(ctx, 0, {100, 300}, bounds) then
         nk.layout_row_dynamic(ctx, 25, 1)
         show_menu = nk.checkbox(ctx, "Menu", show_menu)
         popup.prog = nk.progress(ctx, popup.prog, 100, 'modifiable')
         popup.slider = nk.slider(ctx, 0, popup.slider, 16, 1)
         if nk.contextual_item(ctx, nil, "About", CENTERED) then  show_app_about = true end
         local sel = popup.select
         sel[1] = nk.selectable(ctx, nil, sel[1] and "Unselect" or "Select", LEFT, sel[1])
         sel[2] = nk.selectable(ctx, nil, sel[2] and "Unselect" or "Select", LEFT, sel[2])
         sel[3] = nk.selectable(ctx, nil, sel[3] and "Unselect" or "Select", LEFT, sel[3])
         sel[4] = nk.selectable(ctx, nil, sel[4] and "Unselect" or "Select", LEFT, sel[4])
         nk.contextual_end(ctx)
      end
      -- color contextual ---------------------------------
      nk.layout_row_begin(ctx, 'static', 30, 2)
      nk.layout_row_push(ctx, 120)
      nk.label(ctx, "Right Click here:", LEFT)
      nk.layout_row_push(ctx, 50)
      bounds = nk.widget_bounds(ctx)
      nk.button(ctx, popup.color)
      nk.layout_row_end(ctx)
      if nk.contextual_begin(ctx, 0, {350, 60}, bounds) then
         nk.layout_row_dynamic(ctx, 30, 4)
         local r, g, b, a = nk.color_bytes(popup.color)
         r = nk.property(ctx, "#r", 0, r, 255, 1, 1)
         g = nk.property(ctx, "#g", 0, g, 255, 1, 1)
         b = nk.property(ctx, "#b", 0, b, 255, 1, 1)
         a = nk.property(ctx, "#a", 0, a, 255, 1, 1)
         popup.color = nk.color_from_bytes(r,g,b,a)
         nk.contextual_end(ctx)
      end
      -- popup --------------------------------------------
      nk.layout_row_begin(ctx, 'static', 30, 2)
      nk.layout_row_push(ctx, 120)
      nk.label(ctx, "Popup:", LEFT)
      nk.layout_row_push(ctx, 50)
      if nk.button(ctx, nil, "Popup") then popup.active = true end
      nk.layout_row_end(ctx)
      if popup.active then
         if nk.popup_begin(ctx, 'static', "Error", 0, {20, 100, 220, 90}) then
            nk.layout_row_dynamic(ctx, 25, 1)
            nk.label(ctx, "A terrible error as occured", LEFT)
            nk.layout_row_dynamic(ctx, 25, 2)
            if nk.button(ctx, nil, "OK") then
               popup.active = false
               nk.popup_close(ctx)
            end
            if nk.button(ctx, nil, "Cancel") then
               popup.active = false
               nk.popup_close(ctx)
            end
            nk.popup_end(ctx)
         else 
            popup.active = false
         end
      end

      -- tooltip ------------------------------------------
      nk.layout_row_static(ctx, 30, 150, 1)
      bounds = nk.widget_bounds(ctx)
      nk.label(ctx, "Hover me for tooltip", LEFT)
      if ctx:is_mouse_hovering_rect(bounds) then
         nk.tooltip(ctx, "This is a tooltip")
      end

      nk.tree_pop(ctx)
   end
end


--------------------------------------------------------------------------------

local layout = {
   group_titlebar = false,
   group_border = true,
   group_no_scrollbar = false,
   group_width = 320,
   group_height = 200,
   group_selected = { false,false,false,false,false,false,false,false,
                false,false,false,false,false,false,false,false},
   current_tab = "Lines",
   tab_names = {"Lines", "Columns", "Mixed"},
   selected_left = {},
   selected_right_top = {},
   selected_right_center = {},
   selected_right_bottom = {},
   vertical = { a = 100, b = 100, c = 100 },
   horizontal = { a = 100, b = 100, c = 100 },
   root_selected = false,
   selected = { false,false,false,false,false,false,false,false },
   sel_nodes = { false,false,false,false },
}

local function Layout(ctx)
   if nk.tree_push(ctx, 'tab', "Layout", 'minimized', 'layout') then
      -----------------------------------------------------
      if nk.tree_push(ctx, 'node', "Widget", 'minimized', 'layout widget') then
         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "Dynamic fixed column layout with generated position and size:", LEFT)
         nk.layout_row_dynamic(ctx, 30, 3)
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")

         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "static fixed column layout with generated position and size:", LEFT)
         nk.layout_row_static(ctx, 30, 100, 3)
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")

         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "Dynamic array-based custom column layout with generated position and custom size:",LEFT)
         nk.layout_row(ctx, 'dynamic', 30, {0.2, 0.6, 0.2})
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")

         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "Static array-based custom column layout with generated position and custom size:",LEFT )
         nk.layout_row(ctx, 'static', 30, {100, 200, 50})
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")

         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "Dynamic immediate mode custom column layout with generated position and custom size:",LEFT)
         nk.layout_row_begin(ctx, 'dynamic', 30, 3)
         nk.layout_row_push(ctx, 0.2)
         nk.button(ctx, nil, "button")
         nk.layout_row_push(ctx, 0.6)
         nk.button(ctx, nil, "button")
         nk.layout_row_push(ctx, 0.2)
         nk.button(ctx, nil, "button")
         nk.layout_row_end(ctx)

         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "Static immediate mode custom column layout with generated position and custom size:", LEFT)
         nk.layout_row_begin(ctx, 'static', 30, 3)
         nk.layout_row_push(ctx, 100)
         nk.button(ctx, nil, "button")
         nk.layout_row_push(ctx, 200)
         nk.button(ctx, nil, "button")
         nk.layout_row_push(ctx, 50)
         nk.button(ctx, nil, "button")
         nk.layout_row_end(ctx)

         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "Static free space with custom position and custom size:", LEFT)
         nk.layout_space_begin(ctx, 'static', 60, 4)
         nk.layout_space_push(ctx, {100, 0, 100, 30})
         nk.button(ctx, nil, "button")
         nk.layout_space_push(ctx, {0, 15, 100, 30})
         nk.button(ctx, nil, "button")
         nk.layout_space_push(ctx, {200, 15, 100, 30})
         nk.button(ctx, nil, "button")
         nk.layout_space_push(ctx, {100, 30, 100, 30})
         nk.button(ctx, nil, "button")
         nk.layout_space_end(ctx)

         nk.layout_row_dynamic(ctx, 30, 1)
         nk.label(ctx, "Row template:", LEFT)
         nk.layout_row_template_begin(ctx, 30)
         nk.layout_row_template_push_dynamic(ctx)
         nk.layout_row_template_push_variable(ctx, 80)
         nk.layout_row_template_push_static(ctx, 80)
         nk.layout_row_template_end(ctx)
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")
         nk.button(ctx, nil, "button")
         nk.tree_pop(ctx)
      end

      -----------------------------------------------------
      if nk.tree_push(ctx, 'node', "Group", 'minimized', 'layout group') then
         local flags = 0
         if layout.group_border then flags = flags | nk.WINDOW_BORDER end
         if layout.group_no_scrollbar then flags = flags | nk.WINDOW_NO_SCROLLBAR end
         if layout.group_titlebar then flags = flags | nk.WINDOW_TITLE end
         nk.layout_row_dynamic(ctx, 30, 3)
         layout.group_titlebar =  nk.checkbox(ctx, "Titlebar", layout.group_titlebar)
         layout.group_border = nk.checkbox(ctx, "Border", layout.group_border)
         layout.group_no_scrollbar = nk.checkbox(ctx, "No Scrollbar", layout.group_no_scrollbar)
         nk.layout_row_begin(ctx, 'static', 22, 3)
         nk.layout_row_push(ctx, 50)
         nk.label(ctx, "size:", LEFT)
         nk.layout_row_push(ctx, 130)
         layout.group_width = nk.property(ctx, "#Width:", 100, layout.group_width, 500, 10, 1)
         nk.layout_row_push(ctx, 130)
         layout.group_height = nk.property(ctx, "#Height:", 100, layout.group_height, 500, 10, 1)
         nk.layout_row_end(ctx)

         nk.layout_row_static(ctx, layout.group_height, layout.group_width, 2)
         if nk.group_begin(ctx, "Group", flags) then
            nk.layout_row_static(ctx, 18, 100, 1)
            local sel = layout.group_selected
            for i = 1,16 do
               sel[i] = nk.selectable(ctx, nil, sel[i] and "Selected" or "Unselected", CENTERED, sel[i])
            end
           nk.group_end(ctx)
         end
         nk.tree_pop(ctx)
      end
      -----------------------------------------------------
      if nk.tree_push(ctx, 'node', "Tree", 'minimized', 'layout tree') then
         local sel, ok = layout.root_selected, nil
         ok, sel = nk.tree_element_push(ctx, 'node', "Root", 'minimized', sel, "layout tree root")
         if ok then
            if sel ~= layout.root_selected then
               layout.root_selected = sel
               for i=1, 8 do layout.selected[i] = sel end
            end
            local sel = layout.selected[1]
            ok, sel = nk.tree_element_push(ctx, 'node', "Node", 'minimized', sel, "layout tree node")
            if ok then
               if sel ~= layout.selected[1] then
                  layout.selected[1] = sel
                  for i=1,4 do layout.sel_nodes[i] = sel end
               end
                  nk.layout_row_static(ctx, 18, 100, 1)
                  sel = layout.sel_nodes
                  for i=1,4 do
                     sel[i] = nk.selectable(ctx, 'circle solid', sel[i] and "Selected" or "Unselected", RIGHT, sel[i])
                  end
               nk.tree_element_pop(ctx)
            end
            nk.layout_row_static(ctx, 18, 100, 1)
            sel = layout.selected
            for i=1,8 do
               sel[i] = nk.selectable(ctx, 'circle solid', sel[i] and "Selected" or "Unselected", RIGHT, sel[i])
            end
            nk.tree_element_pop(ctx)
         end
         nk.tree_pop(ctx)
      end
      -----------------------------------------------------
      if nk.tree_push(ctx, 'node', "Notebook", 'minimized', 'layout notebook') then
         -- Header 
         nk.style_push_vec2(ctx, "window.spacing", {0,0})
         nk.style_push_float(ctx, "button.rounding", 0)
         nk.layout_row_begin(ctx, 'static', 20, 3)
         for _, name in ipairs(layout.tab_names) do
            local f = ctx:font()
            -- make sure button perfectly fits text 
            local text_width = f:width(f:height(), name)
            local widget_width = text_width + 3 * nk.style_get_vec2(ctx, "button.padding")[1]
            nk.layout_row_push(ctx, widget_width)
            if layout.current_tab == name then
               -- active tab gets highlighted 
               local button_color = nk.style_get_style_item(ctx, "button.normal")
               local act = nk.style_get_style_item(ctx, "button.active")
               nk.style_set_style_item(ctx, "button.normal", nk.style_get_style_item(ctx, "button.active"))
               layout.current_tab = nk.button(ctx, nil, name) and name or layout.current_tab
               nk.style_set_style_item(ctx, "button.normal", button_color)
            else 
               layout.current_tab = nk.button(ctx, nil, name) and name or layout.current_tab
            end
         end
         nk.style_pop_float(ctx)
         nk.style_pop_vec2(ctx)
         -- Body 
         nk.layout_row_dynamic(ctx, 140, 1)
         if nk.group_begin(ctx, "Notebook", nk.WINDOW_BORDER) then
            if layout.current_tab == "Lines" then
               nk.layout_row_dynamic(ctx, 100, 1)
               local bounds = nk.widget_bounds(ctx)
               if nk.chart_begin(ctx, 'lines', 32, 0.0, 1.0, {1, 0, 0}, {150/255, 0, 0}) then
                  nk.chart_add_slot(ctx, 'lines',32, -1.0, 1.0, {0, 0, 1}, {0, 0,150/255})
                  local id = 0
                  for i = 1, 32 do
                     nk.chart_push(ctx, abs(sin(id)), 1)
                     nk.chart_push(ctx, cos(id), 2)
                     id = id + STEP
                  end
               end 
               nk.chart_end(ctx)
            elseif layout.current_tab == "Columns" then
               nk.layout_row_dynamic(ctx, 100, 1)
               local bounds = nk.widget_bounds(ctx)
               if nk.chart_begin(ctx, 'column', 32, 0.0, 1.0, {1, 0, 0}, {150/255,0,0}) then
                  local id = 0
                  for i = 1, 32 do
                     nk.chart_push(ctx, abs(sin(id)), 1)
                     id = id + STEP
                  end
               end
               nk.chart_end(ctx)
            elseif layout.current_tab == "Mixed" then
               nk.layout_row_dynamic(ctx, 100, 1)
               local bounds = nk.widget_bounds(ctx)
               if nk.chart_begin(ctx, 'lines', 32, 0.0, 1.0, {1, 0, 0}, {150/255,0,0}) then
                  nk.chart_add_slot(ctx, 'lines',32, -1.0, 1.0, {0,0,1}, {0,0,150/255})
                  nk.chart_add_slot(ctx, 'column', 32, 0.0, 1.0, {0,1,0}, {0,150/255,0})
                  local id = 0
                  for i = 1, 32 do
                     nk.chart_push(ctx, abs(sin(id)), 1)
                     nk.chart_push(ctx, abs(cos(id)), 2)
                     nk.chart_push(ctx, abs(sin(id)), 3)
                     id = id + STEP
                  end
               end
               nk.chart_end(ctx)
            end
            nk.group_end(ctx)
         end
         nk.tree_pop(ctx)
      end
      -----------------------------------------------------
      if nk.tree_push(ctx, 'node', "Simple", 'minimized', 'layout simple') then
         nk.layout_row_dynamic(ctx, 300, 2)
         if nk.group_begin(ctx, "Group_Without_Border", 0) then
            nk.layout_row_static(ctx, 18, 150, 1)
            for i = 0, 63 do
               nk.label(ctx, fmt("0x%02x: scrollable region", i), LEFT)
            end
            nk.group_end(ctx)
         end
         if (nk.group_begin(ctx, "Group_With_Border", nk.WINDOW_BORDER)) then
            nk.layout_row_dynamic(ctx, 25, 2)
            for i = 0, 63 do
               --nk.button(ctx, nil, fmt("%08d", floor(((((i%7)*10)^32))+(64+(i%2)*2)))) @@
               nk.button(ctx, nil, fmt("%08d", 1<<i))
            end
            nk.group_end(ctx)
         end
         nk.tree_pop(ctx)
      end
      -----------------------------------------------------
      if nk.tree_push(ctx, 'node', "Complex", 'minimized', 'layout complex') then
         nk.layout_space_begin(ctx, 'static', 500, 64)
         nk.layout_space_push(ctx, {0,0,150,500})
         if nk.group_begin(ctx, "Group_left", nk.WINDOW_BORDER) then
            local sel = layout.selected_left
            nk.layout_row_static(ctx, 18, 100, 1)
            for i = 1, 32 do
               sel[i] = nk.selectable(ctx, nil, sel[i] and "Selected" or "Unselected", CENTERED, sel[i] or false)
            end
            nk.group_end(ctx)
         end
         nk.layout_space_push(ctx, {160,0,150,240})
         if nk.group_begin(ctx, "Group_top", nk.WINDOW_BORDER) then
            nk.layout_row_dynamic(ctx, 25, 1)
            nk.button(ctx, nil, "#FFAA")
            nk.button(ctx, nil, "#FFBB")
            nk.button(ctx, nil, "#FFCC")
            nk.button(ctx, nil, "#FFDD")
            nk.button(ctx, nil, "#FFEE")
            nk.button(ctx, nil, "#FFFF")
            nk.group_end(ctx)
         end
         nk.layout_space_push(ctx, {160,250,150,250})
         if nk.group_begin(ctx, "Group_buttom", nk.WINDOW_BORDER) then
            nk.layout_row_dynamic(ctx, 25, 1)
            nk.button(ctx, nil, "#FFAA")
            nk.button(ctx, nil, "#FFBB")
            nk.button(ctx, nil, "#FFCC")
            nk.button(ctx, nil, "#FFDD")
            nk.button(ctx, nil, "#FFEE")
            nk.button(ctx, nil, "#FFFF")
            nk.group_end(ctx)
         end 
         nk.layout_space_push(ctx, {320,0,150,150})
         if nk.group_begin(ctx, "Group_right_top", nk.WINDOW_BORDER)  then
            local sel = layout.selected_right_top
            nk.layout_row_static(ctx, 18, 100, 1)
            for i = 1, 4 do
               sel[i] = nk.selectable(ctx, nil, sel[i] and "Selected" or "Unselected", CENTERED, sel[i] or false)
            end
            nk.group_end(ctx)
         end
         nk.layout_space_push(ctx, {320,160,150,150})
         if nk.group_begin(ctx, "Group_right_center", nk.WINDOW_BORDER) then
            local sel = layout.selected_right_center
            nk.layout_row_static(ctx, 18, 100, 1)
            for i = 1, 4 do
               sel[i] = nk.selectable(ctx, nil, sel[i] and "Selected" or "Unselected", CENTERED, sel[i] or false)
            end
            nk.group_end(ctx)
         end
         nk.layout_space_push(ctx, {320,320,150,150})
         if nk.group_begin(ctx, "Group_right_bottom", nk.WINDOW_BORDER) then
            local sel = layout.selected_right_bottom
            nk.layout_row_static(ctx, 18, 100, 1)
            for i = 1, 4 do
               sel[i] = nk.selectable(ctx, nil, sel[i] and "Selected" or "Unselected", CENTERED, sel[i] or false)
            end
            nk.group_end(ctx)
         end
         nk.layout_space_end(ctx)
         nk.tree_pop(ctx)
      end
      -----------------------------------------------------
      if nk.tree_push(ctx, 'node', "Splitter", 'minimized', 'tree splitter') then
         nk.layout_row_static(ctx, 20, 320, 1)
         nk.label(ctx, "Use slider and spinner to change tile size", LEFT)
         nk.label(ctx, "Drag the space between tiles to change tile ratio", LEFT)
         if nk.tree_push(ctx, 'node', "Vertical", 'minimized', 'tree splitted vertical') then
            local vert = layout.vertical
            local row_layout = { vert.a, 8, vert.b, 8, vert.c }
            -- header 
            nk.layout_row_static(ctx, 30, 100, 2)
            nk.label(ctx, "left:", LEFT)
            vert.a = nk.slider(ctx, 10.0, vert.a, 200.0, 10.0)
            nk.label(ctx, "middle:", LEFT)
            vert.b = nk.slider(ctx, 10.0, vert.b, 200.0, 10.0)
            nk.label(ctx, "right:", LEFT)
            vert.c = nk.slider(ctx, 10.0, vert.c, 200.0, 10.0)
            -- tiles 
            nk.layout_row(ctx, 'static', 200, row_layout)
            -- left space 
            if nk.group_begin(ctx, "left", 
                     nk.WINDOW_NO_SCROLLBAR|nk.WINDOW_BORDER|nk.WINDOW_NO_SCROLLBAR) then
               nk.layout_row_dynamic(ctx, 25, 1)
               nk.button(ctx, nil, "#FFAA")
               nk.button(ctx, nil, "#FFBB")
               nk.button(ctx, nil, "#FFCC")
               nk.button(ctx, nil, "#FFDD")
               nk.button(ctx, nil, "#FFEE")
               nk.button(ctx, nil, "#FFFF")
               nk.group_end(ctx)
            end
            -- scaler 
            local bounds = nk.widget_bounds(ctx)
            nk.spacing(ctx, 1)
            if (ctx:is_mouse_hovering_rect(bounds) or ctx:is_mouse_prev_hovering_rect(bounds)) 
                  and ctx:is_mouse_down('left') then
               local dx = ctx:mouse_delta()
               vert.a = row_layout[1] + dx
               vert.b = row_layout[3] - dx
            end
            -- middle space 
            if nk.group_begin(ctx, "center", nk.WINDOW_BORDER|nk.WINDOW_NO_SCROLLBAR) then
               nk.layout_row_dynamic(ctx, 25, 1)
               nk.button(ctx, nil, "#FFAA")
               nk.button(ctx, nil, "#FFBB")
               nk.button(ctx, nil, "#FFCC")
               nk.button(ctx, nil, "#FFDD")
               nk.button(ctx, nil, "#FFEE")
               nk.button(ctx, nil, "#FFFF")
               nk.group_end(ctx)
            end
            -- scaler 
            local bounds = nk.widget_bounds(ctx)
            nk.spacing(ctx, 1)
            if (ctx:is_mouse_hovering_rect(bounds) or ctx:is_mouse_prev_hovering_rect(bounds)) 
                   and ctx:is_mouse_down('left') then
               local dx = ctx:mouse_delta()
               vert.b = row_layout[3] + dx
               vert.c = row_layout[5] - dx
            end
            -- right space 
            if nk.group_begin(ctx, "right", nk.WINDOW_BORDER|nk.WINDOW_NO_SCROLLBAR) then
               nk.layout_row_dynamic(ctx, 25, 1)
               nk.button(ctx, nil, "#FFAA")
               nk.button(ctx, nil, "#FFBB")
               nk.button(ctx, nil, "#FFCC")
               nk.button(ctx, nil, "#FFDD")
               nk.button(ctx, nil, "#FFEE")
               nk.button(ctx, nil, "#FFFF")
               nk.group_end(ctx)
            end
            nk.tree_pop(ctx)
         end
         if nk.tree_push(ctx, 'node', "Horizontal", 'minimized', 'widget tree horizontal') then
            local hor = layout.horizontal
            -- header 
            nk.layout_row_static(ctx, 30, 100, 2)
            nk.label(ctx, "top:", LEFT)
            hor.a = nk.slider(ctx, 10.0, hor.a, 200.0, 10.0)
            nk.label(ctx, "middle:", LEFT)
            hor.b = nk.slider(ctx, 10.0, hor.b, 200.0, 10.0)
            nk.label(ctx, "bottom:", LEFT)
            hor.c = nk.slider(ctx, 10.0, hor.c, 200.0, 10.0)
            -- top space 
            nk.layout_row_dynamic(ctx, hor.a, 1)
            if nk.group_begin(ctx, "top", nk.WINDOW_NO_SCROLLBAR|nk.WINDOW_BORDER) then
               nk.layout_row_dynamic(ctx, 25, 3)
               nk.button(ctx, nil, "#FFAA")
               nk.button(ctx, nil, "#FFBB")
               nk.button(ctx, nil, "#FFCC")
               nk.button(ctx, nil, "#FFDD")
               nk.button(ctx, nil, "#FFEE")
               nk.button(ctx, nil, "#FFFF")
               nk.group_end(ctx)
            end
            -- scaler 
            nk.layout_row_dynamic(ctx, 8, 1)
            local bounds = nk.widget_bounds(ctx)
            nk.spacing(ctx, 1)
            if (ctx:is_mouse_hovering_rect(bounds) or ctx:is_mouse_prev_hovering_rect(bounds))
                  and ctx:is_mouse_down('left') then
               local dx, dy = ctx:mouse_delta()
               hor.a = hor.a + dy
               hor.b = hor.b - dy
            end
            -- middle space 
            nk.layout_row_dynamic(ctx, hor.b, 1)
            if nk.group_begin(ctx, "middle", nk.WINDOW_NO_SCROLLBAR|nk.WINDOW_BORDER) then
               nk.layout_row_dynamic(ctx, 25, 3)
               nk.button(ctx, nil, "#FFAA")
               nk.button(ctx, nil, "#FFBB")
               nk.button(ctx, nil, "#FFCC")
               nk.button(ctx, nil, "#FFDD")
               nk.button(ctx, nil, "#FFEE")
               nk.button(ctx, nil, "#FFFF")
               nk.group_end(ctx)
            end
            -- scaler 
            nk.layout_row_dynamic(ctx, 8, 1)
            local bounds = nk.widget_bounds(ctx)
            if (ctx:is_mouse_hovering_rect(bounds) or ctx:is_mouse_prev_hovering_rect(bounds)) 
                  and ctx:is_mouse_down('left') then
               local dx, dy = ctx:mouse_delta()
               hor.b = hor.b + dy
               hor.c = hor.c - dy
            end
            -- bottom space 
            nk.layout_row_dynamic(ctx, hor.c, 1)
            if nk.group_begin(ctx, "bottom", nk.WINDOW_NO_SCROLLBAR|nk.WINDOW_BORDER) then
               nk.layout_row_dynamic(ctx, 25, 3)
               nk.button(ctx, nil, "#FFAA")
               nk.button(ctx, nil, "#FFBB")
               nk.button(ctx, nil, "#FFCC")
               nk.button(ctx, nil, "#FFDD")
               nk.button(ctx, nil, "#FFEE")
               nk.button(ctx, nil, "#FFFF")
               nk.group_end(ctx)
            end
            nk.tree_pop(ctx)
         end
         nk.tree_pop(ctx)
      end
   nk.tree_pop(ctx)
   end
end


-------------------------------------------------------------------------------

return function(ctx)
   window_flags = 0
   nk.style_set_flags(ctx, "window.header.align", nk.HEADER_RIGHT)
   if border then window_flags = window_flags | nk.WINDOW_BORDER end
   if resize then window_flags = window_flags | nk.WINDOW_SCALABLE end
   if movable then window_flags = window_flags | nk.WINDOW_MOVABLE end
   if no_scrollbar then window_flags = window_flags | nk.WINDOW_NO_SCROLLBAR end
   if scale_left then window_flags = window_flags | nk.WINDOW_SCALE_LEFT end
   if minimizable then window_flags = window_flags | nk.WINDOW_MINIMIZABLE end

   if nk.window_begin(ctx, "Overview", {10, 10, 400, 600}, window_flags) then
      if show_menu then Menubar(ctx) end
      if show_app_about then About(ctx) end
      WindowFlagsCheckbox(ctx)
      if nk.tree_push(ctx,'tab', "Widgets", 'minimized', 'widgets tree') then
         Text(ctx)
         Buttons(ctx)
         Basic(ctx)
         Selectable(ctx)
         Combo(ctx)
         Input(ctx)
         nk.tree_pop(ctx)
      end
      Chart(ctx)
      Popup(ctx)
      Layout(ctx)
   end

   nk.window_end(ctx)
   return not nk.window_is_closed(ctx, "Overview")
end
