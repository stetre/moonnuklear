-- style.lua

local nk = require("moonnuklear")

local colortable = {}
local rgba = nk.color_from_bytes

colortable.white = {
   text = rgba(70, 70, 70, 255),
   window = rgba(175, 175, 175, 255),
   header = rgba(175, 175, 175, 255),
   border = rgba(0, 0, 0, 255),
   button = rgba(185, 185, 185, 255),
   button_hover = rgba(170, 170, 170, 255),
   button_active = rgba(160, 160, 160, 255),
   toggle = rgba(150, 150, 150, 255),
   toggle_hover = rgba(120, 120, 120, 255),
   toggle_cursor = rgba(175, 175, 175, 255),
   select = rgba(190, 190, 190, 255),
   select_active = rgba(175, 175, 175, 255),
   slider = rgba(190, 190, 190, 255),
   slider_cursor = rgba(80, 80, 80, 255),
   slider_cursor_hover = rgba(70, 70, 70, 255),
   slider_cursor_active = rgba(60, 60, 60, 255),
   property = rgba(175, 175, 175, 255),
   edit = rgba(150, 150, 150, 255),
   edit_cursor = rgba(0, 0, 0, 255),
   combo = rgba(175, 175, 175, 255),
   chart = rgba(160, 160, 160, 255),
   chart_color = rgba(45, 45, 45, 255),
   chart_color_highlight = rgba( 255, 0, 0, 255),
   scrollbar = rgba(180, 180, 180, 255),
   scrollbar_cursor = rgba(140, 140, 140, 255),
   scrollbar_cursor_hover = rgba(150, 150, 150, 255),
   scrollbar_cursor_active = rgba(160, 160, 160, 255),
   tab_header = rgba(180, 180, 180, 255),
}

colortable.red = {
   text = rgba(190, 190, 190, 255),
   window = rgba(30, 33, 40, 215),
   header = rgba(181, 45, 69, 220),
   border = rgba(51, 55, 67, 255),
   button = rgba(181, 45, 69, 255),
   button_hover = rgba(190, 50, 70, 255),
   button_active = rgba(195, 55, 75, 255),
   toggle = rgba(51, 55, 67, 255),
   toggle_hover = rgba(45, 60, 60, 255),
   toggle_cursor = rgba(181, 45, 69, 255),
   select = rgba(51, 55, 67, 255),
   select_active = rgba(181, 45, 69, 255),
   slider = rgba(51, 55, 67, 255),
   slider_cursor = rgba(181, 45, 69, 255),
   slider_cursor_hover = rgba(186, 50, 74, 255),
   slider_cursor_active = rgba(191, 55, 79, 255),
   property = rgba(51, 55, 67, 255),
   edit = rgba(51, 55, 67, 225),
   edit_cursor = rgba(190, 190, 190, 255),
   combo = rgba(51, 55, 67, 255),
   chart = rgba(51, 55, 67, 255),
   chart_color = rgba(170, 40, 60, 255),
   chart_color_highlight = rgba( 255, 0, 0, 255),
   scrollbar = rgba(30, 33, 40, 255),
   scrollbar_cursor = rgba(64, 84, 95, 255),
   scrollbar_cursor_hover = rgba(70, 90, 100, 255),
   scrollbar_cursor_active = rgba(75, 95, 105, 255),
   tab_header = rgba(181, 45, 69, 220),
}

colortable.blue = {
   text = rgba(20, 20, 20, 255),
   window = rgba(202, 212, 214, 215),
   header = rgba(137, 182, 224, 220),
   border = rgba(140, 159, 173, 255),
   button = rgba(137, 182, 224, 255),
   button_hover = rgba(142, 187, 229, 255),
   button_active = rgba(147, 192, 234, 255),
   toggle = rgba(177, 210, 210, 255),
   toggle_hover = rgba(182, 215, 215, 255),
   toggle_cursor = rgba(137, 182, 224, 255),
   select = rgba(177, 210, 210, 255),
   select_active = rgba(137, 182, 224, 255),
   slider = rgba(177, 210, 210, 255),
   slider_cursor = rgba(137, 182, 224, 245),
   slider_cursor_hover = rgba(142, 188, 229, 255),
   slider_cursor_active = rgba(147, 193, 234, 255),
   property = rgba(210, 210, 210, 255),
   edit = rgba(210, 210, 210, 225),
   edit_cursor = rgba(20, 20, 20, 255),
   combo = rgba(210, 210, 210, 255),
   chart = rgba(210, 210, 210, 255),
   chart_color = rgba(137, 182, 224, 255),
   chart_color_highlight = rgba( 255, 0, 0, 255),
   scrollbar = rgba(190, 200, 200, 255),
   scrollbar_cursor = rgba(64, 84, 95, 255),
   scrollbar_cursor_hover = rgba(70, 90, 100, 255),
   scrollbar_cursor_active = rgba(75, 95, 105, 255),
   tab_header = rgba(156, 193, 220, 255),
}
 
colortable.dark = {
   text = rgba(210, 210, 210, 255),
   window = rgba(57, 67, 71, 215),
   header = rgba(51, 51, 56, 220),
   border = rgba(46, 46, 46, 255),
   button = rgba(48, 83, 111, 255),
   button_hover = rgba(58, 93, 121, 255),
   button_active = rgba(63, 98, 126, 255),
   toggle = rgba(50, 58, 61, 255),
   toggle_hover = rgba(45, 53, 56, 255),
   toggle_cursor = rgba(48, 83, 111, 255),
   select = rgba(57, 67, 61, 255),
   select_active = rgba(48, 83, 111, 255),
   slider = rgba(50, 58, 61, 255),
   slider_cursor = rgba(48, 83, 111, 245),
   slider_cursor_hover = rgba(53, 88, 116, 255),
   slider_cursor_active = rgba(58, 93, 121, 255),
   property = rgba(50, 58, 61, 255),
   edit = rgba(50, 58, 61, 225),
   edit_cursor = rgba(210, 210, 210, 255),
   combo = rgba(50, 58, 61, 255),
   chart = rgba(50, 58, 61, 255),
   chart_color = rgba(48, 83, 111, 255),
   chart_color_highlight = rgba(255, 0, 0, 255),
   scrollbar = rgba(50, 58, 61, 255),
   scrollbar_cursor = rgba(48, 83, 111, 255),
   scrollbar_cursor_hover = rgba(53, 88, 116, 255),
   scrollbar_cursor_active = rgba(58, 93, 121, 255),
   tab_header = rgba(48, 83, 111, 255),
}

return function(ctx, theme)
   local t = colortable[theme]
   if t then
      nk.style_from_table(ctx, t)
   else -- unknown theme, use default
      nk.style_default(ctx)
   end
end

