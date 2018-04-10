-- MoonGL/MoonGLFW backend renderer for MoonNuklear - renderer.lua

local glfw = require("moonglfw")
local gl = require("moongl")
local nk = require("moonnuklear")

local floor = math.floor

local vertex_shader = [[
#version 330 core
uniform mat4 ProjMtx;
in vec2 Position;
in vec2 TexCoord;
in vec4 Color;
out vec2 Frag_UV;
out vec4 Frag_Color;

void main()
   {
   Frag_UV = TexCoord;
   Frag_Color = Color;
   gl_Position = ProjMtx * vec4(Position.xy, 0, 1);
   }
]]

local fragment_shader = [[
#version 330 core
precision mediump float;
uniform sampler2D Texture;
in vec2 Frag_UV;
in vec4 Frag_Color;
out vec4 Out_Color;

void main()
   {
   Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
   }
]]

local window, width, height, display_width, display_height, scale_x, scale_y
local vao, vbo, ebo, prog, uniform_tex, uniform_proj, font_tex
local ctx, atlas, cmds
local scroll_x, scroll_y, char_text
local last_button_click, double_click_pos, is_double_click_down
local vbo_size, ebo_size, anti_aliasing_on
local vbuf, ebuf

local DOUBLE_CLICK_LO, DOUBLE_CLICK_HI = 0.02, 0.2
local MOUSE_GRABBING = true
local USHORTSZ = gl.sizeof('ushort')

-------------------------------------------------------------------------------
local function device_create(ctx)
   cmds = nk.new_buffer("dynamic")
   prog, vsh, fsh = gl.make_program_s('vertex', vertex_shader, 'fragment', fragment_shader)
   gl.delete_shaders(vsh, fsh)

   uniform_tex = gl.get_uniform_location(prog, "Texture")
   uniform_proj = gl.get_uniform_location(prog, "ProjMtx")
   local attrib_pos = gl.get_attrib_location(prog, "Position")
   local attrib_uv = gl.get_attrib_location(prog, "TexCoord")
   local attrib_col = gl.get_attrib_location(prog, "Color")

   -- buffer setup 
   vao = gl.new_vertex_array()
   vbo = gl.new_buffer('array')
   gl.buffer_data('array', vbo_size, 'stream draw')

   gl.enable_vertex_attrib_array(attrib_pos)
   gl.enable_vertex_attrib_array(attrib_uv)
   gl.enable_vertex_attrib_array(attrib_col)

   -- struct vertex { float position[2]; float uv[2]; nk_byte col[4]; }
   local stride = 4*gl.sizeof('float')+ 4*gl.sizeof('ubyte') 
   local pos_offset, uv_offset, col_offset = 0, 2*gl.sizeof('float'), 4*gl.sizeof('float')
   gl.vertex_attrib_pointer(attrib_pos, 2, 'float', false, stride, pos_offset)
   gl.vertex_attrib_pointer(attrib_uv, 2, 'float', false, stride, uv_offset)
   gl.vertex_attrib_pointer(attrib_col, 4, 'ubyte', true, stride, col_offset)

   ebo = gl.new_buffer('element array')
   gl.buffer_data('element array', ebo_size, 'stream draw')

   gl.unbind_texture('2d')
   gl.unbind_buffer('array')
   gl.unbind_buffer('element array')
   gl.unbind_vertex_array()

   -- fill convert configuration
   ctx:config_vertex_layout({
      { 'position', 'float', pos_offset },
      { 'texcoord', 'float', uv_offset },
      { 'color', 'r8g8b8a8', col_offset },
   })
   ctx:config_vertex_size(stride)
   ctx:config_vertex_alignment(4) --@@
   ctx:config_circle_segment_count(22)
   ctx:config_curve_segment_count(22)
   ctx:config_arc_segment_count(22)
   ctx:config_global_alpha(1.0)
   if anti_aliasing_on then
      ctx:config_line_aa(true)
      ctx:config_shape_aa(true)
   end

   vbuf = nk.new_buffer("fixed")
   ebuf = nk.new_buffer("fixed")
end


-------------------------------------------------------------------------------
local ortho = {
   { 2.0,  0.0,  0.0, -1.0},
   { 0.0, -2.0,  0.0,  1.0},
   { 0.0,  0.0, -1.0,  0.0},
   { 0.0,  0.0,  0.0,  1.0},
}


local function render()
-- IMPORTANT: render() modifies some global OpenGL state with blending, scissor, 
-- face culling, depth test and viewport and defaults everything back into a 
-- default state. Make sure to either a.) save and restore or b.) reset your own
-- state after rendering the UI.
   ortho[1][1] = 2/width
   ortho[2][2] = -2/height

   -- setup global state
   gl.enable('blend')
   gl.blend_equation('add')
   gl.blend_func('src alpha', 'one minus src alpha')
   gl.disable('cull face')
   gl.disable('depth test')
   gl.enable('scissor test')
   gl.active_texture(0)

   -- setup program
   gl.use_program(prog)
   gl.uniformi(uniform_tex, 0)
   gl.uniform_matrix4f(uniform_proj, true, ortho)
   gl.viewport(0,0,display_width,display_height)

   -- convert from command queue into draw list and draw to screen
   -- load draw vertices & elements directly into vertex + element buffer
   gl.bind_vertex_array(vao)
   gl.bind_buffer('array', vbo)
   gl.bind_buffer('element array', ebo)
   local vertices = gl.map_buffer('array', 'write only')
   local elements = gl.map_buffer('element array', 'write only')
   --print("vertices", vertices, vbo_size)
   --print("elements", elements, ebo_size)
   vbuf:init(vertices, vbo_size)
   ebuf:init(elements, ebo_size)
   ctx:convert(cmds, vbuf, ebuf)
   gl.unmap_buffer('array')
   gl.unmap_buffer('element array')

   -- iterate over and execute each draw command
   local offset = 0
   local commands = ctx:draw_commands(cmds)
   for i, cmd in ipairs(commands) do
      local elem_count = cmd.elem_count
      if elem_count > 0 then
         gl.bind_texture('2d', cmd.texture_id)
         local x, y, w, h = table.unpack(cmd.clip_rect)
         x = floor(x * scale_x)
         y = floor((height - (y + h))*scale_y)
         w = floor(w * scale_x)
         h = floor(h * scale_y)
         gl.scissor(x, y, w, h)
         --print("cmd="..i.." ec="..elem_count.." ofs="..offset.." id="..cmd.texture_id.." xywh="..x..","..y..","..w..","..h)
         gl.draw_elements('triangles', elem_count, 'ushort', offset)
         offset = offset + elem_count*USHORTSZ
      end
   end
   nk.clear_buffers(cmds, vbuf, ebuf) -- needed since Nuklear 4.00.0
   ctx:clear(ctx)

   -- restore default OpenGL state
   gl.use_program(0)
   gl.unbind_buffer('array')
   gl.unbind_buffer('element array')
   gl.unbind_vertex_array()
   gl.disable('blend')
   gl.disable('scissor test')
end

-------------------------------------------------------------------------------
local function char_callback(_, codepoint)
   table.insert(char_text, codepoint)
end

local function scroll_callback(_, xoffset, yoffset)
   scroll_x, scroll_y = scroll_x + xoffset, scroll_y + yoffset
end

local function mouse_button_callback(window, button, action, shift, control, alt, super)
   if button ~= 'left' then return end
   if action == 'press' then 
      local now = glfw.get_time()
      local dt = now - last_button_click
      last_button_click = now
      if dt > DOUBLE_CLICK_LO and dt < DOUBLE_CLICK_HI then
         is_double_click_down = true
         double_click_pos = { glfw.get_cursor_pos(window) }
      end
   else 
      is_double_click_down = false
   end
end

local keys = {}
local keys_cb = {
   ['delete'] = function(down, control) keys.del = down end,
   ['enter'] = function(down, control) keys.enter = down end,
   ['tab'] = function(down, control) keys.tab = down end,
   ['backspace'] = function(down, control) keys.backspace = down end,
   ['up'] = function(down, control) keys.up = down end,
   ['down'] = function(down, control) keys.down = down end,
   ['home'] = function(down, control) keys.text_start, keys.scroll_start = down, down end,
   ['end'] = function(down, control) keys.text_end, keys.scroll_end = down, down end,
   ['page down'] = function(down, control) keys.scroll_down = down end,
   ['page up'] = function(down, control) keys.scroll_up = down end,
   ['left shift'] = function(down, control) keys.shift = down end,
   ['right shift'] = function(down, control) keys.shift = down end,
   ['c'] = function(down, control) keys.copy = down and control end,
   ['v'] = function(down, control) keys.paste = down and control end,
   ['x'] = function(down, control) keys.cut = down and control end,
   ['z'] = function(down, control) keys.text_undo = down and control end,
   ['r'] = function(down, control) keys.text_redo = down and control end,
   ['left'] = function(down, control) 
               if control then keys.text_word_left = down else keys.left = down end
            end,
   ['right'] = function(down, control)
               if control then keys.text_word_right = down else keys.right = down end
            end,
   ['b'] = function(down, control) keys.text_line_start = down and control end,
   ['e'] = function(down, control) keys.text_line_end = down and control end,
}

local function key_callback(window, key, scancode, action, shift, control, alt, super)
   local cb = keys_cb[key]
   if cb then cb(action ~= 'release', control) end
end

local function clipboard_paste(edit)
   local text = glfw.get_clipboard_string(window)
   if #text>0 then edit:paste(text) end
end

local function clipboard_copy(text)
   if #text > 0 then glfw.set_clipboard_string(window, text) end
end

-------------------------------------------------------------------------------
local function init(glfw_window, vbosize, ebosize, aa_on, install_callbacks)
   assert(ctx == nil, "double init")
   window = glfw_window
   vbo_size = vbosize or 512*1024
   ebo_size = ebosize or 128*1024
   anti_aliasing_on = aa_on and true or false

   last_button_click = 0
   is_double_click_down = false
   double_click_pos = {0, 0}
   char_text = {}
   scroll_x, scroll_y = 0, 0

   ctx = nk.init()
   ctx:set_clipboard_copy(clipboard_copy)
   ctx:set_clipboard_paste(clipboard_paste)

   if install_callbacks then
      glfw.set_scroll_callback(window, scroll_callback)
      glfw.set_char_callback(window, char_callback)
      glfw.set_mouse_button_callback(window, mouse_button_callback)
      glfw.set_key_callback(window, key_callback)
   end

   device_create(ctx)
   return ctx
end

-------------------------------------------------------------------------------
local function font_stash_begin()
    atlas = nk.new_font_atlas()
    atlas:begin()
    return atlas
end

local function font_stash_end(ctx, font)
   local image, w, h = atlas:bake('rgba32')
   font_tex = gl.new_texture('2d')
   gl.texture_parameter('2d', 'min filter', 'linear')
   gl.texture_parameter('2d', 'mag filter', 'linear')
   gl.texture_image('2d', 0, 'rgba', 'rgba', 'ubyte', image, w, h)
   local null_tex, null_uv = atlas:done(font_tex)
   ctx:config_null_texture(null_tex, null_uv)
   local font = font or atlas:default_font()
   if font then nk.style_set_font(ctx, font) end
end


-------------------------------------------------------------------------------


local function new_frame()
   width, height = glfw.get_window_size(window)
   display_width, display_height = glfw.get_framebuffer_size(window)
   scale_x = display_width/width
   scale_y = display_height/height

   nk.input_begin(ctx)
   if #char_text > 0 then nk.input_unicode(ctx, table.unpack(char_text)) end
   char_text = {}

   if MOUSE_GRABBING then -- optional grabbing behavior
      if ctx:mouse_grab() then
         glfw.set_input_mode(window, 'cursor', 'hidden')
      elseif ctx:mouse_ungrab() then
         glfw.set_input_mode(window, 'cursor', 'normal')
      end
   end

   nk.input_keys(ctx, keys)

   local x, y = glfw.get_cursor_pos(window)
   nk.input_motion(ctx, x, y)

   if MOUSE_GRABBING and ctx:mouse_grabbed() then
      local prev_, prev_y = ctx:mouse_prev()
      glfw.set_cursor_pos(window, prev_x, prev_y)
      input_mouse_pos(ctx, prev_x, prev_y)
   end

   nk.input_button(ctx, 'left', x, y, glfw.get_mouse_button(window, 'left') == 'press')
   nk.input_button(ctx, 'middle', x, y, glfw.get_mouse_button(window, 'middle') == 'press')
   nk.input_button(ctx, 'right', x, y, glfw.get_mouse_button(window, 'right') == 'press')
   nk.input_button(ctx, 'double', double_click_pos[1], double_click_pos[2], is_double_click_down)
   nk.input_scroll(ctx, scroll_x, scroll_y)
   scroll_x, scroll_y = 0, 0

   nk.input_end(ctx)
end

-------------------------------------------------------------------------------
local function shutdown()
   if ctx then
      atlas:free()
      ctx:free()
      gl.delete_program(prog)
      gl.delete_textures(font_tex)
      gl.delete_buffers(vbo, ebo)
      gl.delete_vertex_arrays(vao)
      cmds:free()
      ctx, atlas, cmds = nil
   end
end

-------------------------------------------------------------------------------
return {
   init = init,
   font_stash_begin = font_stash_begin,
   font_stash_end = font_stash_end,
   new_frame = new_frame,
   render = render,
   shutdown = shutdown,
}

