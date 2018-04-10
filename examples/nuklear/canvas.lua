#!/usr/bin/env lua

local glfw = require("moonglfw")
local gl = require("moongl")
local nk = require("moonnuklear")

local floor = math.floor
local abs, sin, cos = math.abs, math.sin, math.cos

local FONT_PATH = arg[1]
local ANTI_ALIASING = true
if arg[2] == "no-aa" then ANTI_ALIASING = false end

local TITLE = "Canvas example"
local FPS = 30 -- frames per second
local W, H= 1200, 800 -- window width and height
local DISPLAY_W, DISPLAY_H= W, H
local SCALE = {0, 0}
local VBO_SIZE = 512 * 1024 -- size of vertex buffer
local EBO_SIZE = 128 * 1024 -- size of element buffer
local ORTHO = { -- base projection matrix (completed in rescale())
   {0.0, 0.0, 0.0,-1.0},
   {0.0, 0.0, 0.0, 1.0},
   {0.0, 0.0,-1.0, 0.0},
   {0.0, 0.0, 0.0, 1.0},
}

local FLOATSZ, BYTESZ, USHORTSZ = gl.sizeof('float'), gl.sizeof('byte'), gl.sizeof('ushort')
local STEP = 2*math.pi/32

local window, prog, uniform_proj
local cmds, vbuf, ebuf, vao, vbo, ebo
local ctx, atlas, font, font_tex
local gui = { -- GUI state
   window_flags = nk.WINDOW_BORDER|nk.WINDOW_MOVABLE|nk.WINDOW_TITLE,
   slider = 10,
   field = "",
   prog_value = 60,
   current_weapon = 1,
   weapons = {"Fist","Pistol","Shotgun","Plasma","BFG"},
   pos = 0.0,
   check1 = false,
   check2 = false,
   option = false,
   selected = {false,false,false,false,false,false,false,false,},
}

local vertex_shader = [[
#version 330 core
uniform mat4 ProjMtx;
in vec2 Position;
in vec2 TexCoord;
in vec4 Color;
out vec2 Frag_UV;
out vec4 Frag_Color;
void main() {
   Frag_UV = TexCoord;
   Frag_Color = Color;
   gl_Position = ProjMtx * vec4(Position.xy, 0, 1);
}]]

local fragment_shader = [[
#version 330 core
precision mediump float;
uniform sampler2D Texture;
in vec2 Frag_UV;
in vec4 Frag_Color;
out vec4 Out_Color;
void main(){
   Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
}]]

--------- MAIN ----------------------------------------------------------------
    
do -- Initializations 
   -- GLFW/GL inits -----------------------
   glfw.version_hint(3, 3, 'core')
   window = glfw.create_window(W, H, TITLE)
   glfw.make_context_current(window)
   gl.init()

   -- setup fonts ----------------------
   atlas = nk.new_font_atlas()
   atlas:begin()
   font = atlas:add(13.0, FONT_PATH) -- if FONT_PATH==nil, uses the default
   local pixels, w, h = atlas:bake('rgba32') 
   -- create texture 
   font_tex = gl.new_texture('2d')
   gl.texture_parameter('2d', 'min filter', 'linear')
   gl.texture_parameter('2d', 'mag filter', 'linear')
   gl.texture_image('2d', 0, 'rgba', 'rgba', 'ubyte', pixels, w, h)
   local null_tex, null_uv = atlas:done(font_tex)

   -- create Nuklear context
   ctx = nk.init(font)

   -- build shader program -------------
   local vsh, fsh
   prog, vsh, fsh = gl.make_program_s('vertex', vertex_shader, 'fragment', fragment_shader)
   gl.delete_shaders(vsh, fsh)
   uniform_proj = gl.get_uniform_location(prog, "ProjMtx")
   local uniform_tex = gl.get_uniform_location(prog, "Texture")
   local attrib_pos = gl.get_attrib_location(prog, "Position")
   local attrib_uv = gl.get_attrib_location(prog, "TexCoord")
   local attrib_col = gl.get_attrib_location(prog, "Color")
   
   gl.use_program(prog)
   gl.uniformi(uniform_tex, 0)

   -- OpenGL buffers --------------------
   vao = gl.new_vertex_array()
   vbo = gl.new_buffer('array')
   gl.buffer_data('array', VBO_SIZE, 'stream draw')

   -- We'll store vertex data in the vbo as follows:
   -- struct vertex { float pos[2]; float uv[2]; ubyte col[4]; }
   local stride = 4*FLOATSZ + 4*BYTESZ
   local pos_offset, uv_offset, col_offset = 0, 2*FLOATSZ, 4*FLOATSZ
   gl.enable_vertex_attrib_array(attrib_pos)
   gl.enable_vertex_attrib_array(attrib_uv)
   gl.enable_vertex_attrib_array(attrib_col)
   gl.vertex_attrib_pointer(attrib_pos, 2, 'float', false, stride, pos_offset)
   gl.vertex_attrib_pointer(attrib_uv, 2, 'float', false, stride, uv_offset)
   gl.vertex_attrib_pointer(attrib_col, 4, 'ubyte', true, stride, col_offset)

   ebo = gl.new_buffer('element array')
   gl.buffer_data('element array', EBO_SIZE, 'stream draw')

   gl.unbind_texture('2d')
   gl.unbind_buffer('array')
   gl.unbind_buffer('element array')
   gl.unbind_vertex_array()

   -- Nuklear buffers -----------------------
   cmds = nk.new_buffer("dynamic") -- buffer for Nuklear commands
   vbuf = nk.new_buffer("fixed") -- buffer for Nuklear to write vertex data to
   ebuf = nk.new_buffer("fixed") -- buffer for Nuklear to write element indices to

   -- Convert configuration -----------------
   ctx:config_vertex_layout({
      { 'position', 'float', pos_offset },
      { 'texcoord', 'float', uv_offset },
      { 'color', 'r8g8b8a8', col_offset },
   })
   ctx:config_vertex_size(stride)
   ctx:config_vertex_alignment(4)
   ctx:config_null_texture(null_tex, null_uv)
   ctx:config_circle_segment_count(22)
   ctx:config_curve_segment_count(22)
   ctx:config_arc_segment_count(22)
   ctx:config_global_alpha(1.0)
   ctx:config_shape_aa(ANTI_ALIASING)
   ctx:config_line_aa(ANTI_ALIASING)
end

-- set GLFW callbacks -------------------------------

local function rescale() -- updates viewport and projection matrix
   SCALE = {DISPLAY_W/W, DISPLAY_H/H} 
   gl.viewport(0, 0, DISPLAY_W, DISPLAY_H)
   ORTHO[1][1] = 2.0/W
   ORTHO[2][2] = -2.0/H
   gl.use_program(prog)
   gl.uniform_matrix4f(uniform_proj, true, ORTHO)
end

glfw.set_window_size_callback(window, function(window, w, h)
   W, H = w, h
   rescale()
end)

glfw.set_framebuffer_size_callback(window, function(window, w, h)
   DISPLAY_W, DISPLAY_H = w, h
   rescale()
end)

local key_down = {} -- indexed by Nuklear keys
glfw.set_key_callback(window, function(window, key, scancode, action, shift, control, alt, super)
   -- translate GLFW key events to Nuklear key events:
   local down = action ~= 'release'
   if key == 'left shift' or key == 'right shift' then key_down['shift'] = down
   elseif key == 'delete' then key_down['del'] = down
   elseif key == 'enter' then key_down['enter'] = down
   elseif key == 'tab' then key_down['tab'] = down
   elseif key == 'backspace' then key_down['backspace'] = down
   elseif key == 'left' then key_down['left'] = down
   elseif key == 'right' then key_down['right'] = down
   elseif key == 'up' then key_down['up'] = down
   elseif key == 'down' then key_down['down'] = down
   elseif key == 'c' then key['copy'] = control and down
   elseif key == 'v' then key['paste'] = control and down
   elseif key == 'x' then key['cut'] = control and down
   elseif key == 'z' then key['text undo'] = control and down
   elseif key == 'r' then key['text redo'] = control and down
   end
end)

local mouse = { left=false, middle=false, right=false, x=0, y=0 }
glfw.set_mouse_button_callback(window, function(window, button, action)
   mouse[button] = action == 'press'
end)
glfw.set_cursor_pos_callback(window, function(window, x, y)
   mouse.x, mouse.y = x, y
end)

local scroll_x, scroll_y = 0, 0
glfw.set_scroll_callback(window, function(window, xofs, yofs)
   scroll_x, scroll_y = scroll_x + xofs, scroll_y + yofs
end)

local text_input = {} -- array of codepoints
glfw.set_char_callback(window, function(window, codepoint)
   table.insert(text_input, codepoint)
end)

-- Initialize viewport -----------------------------------
W, H = glfw.get_window_size(window)
DISPLAY_W, DISPLAY_H = glfw.get_framebuffer_size(window)
rescale()

-- Event loop ---------------------------------------------
collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   --glfw.poll_events()
   glfw.wait_events_timeout(1/FPS)

   -- Input mirroring -------------------------------------
   nk.input_begin(ctx)
   nk.input_key(ctx, 'shift', key_down['shift'])
   nk.input_key(ctx, 'del', key_down['del'])
   nk.input_key(ctx, 'enter', key_down['enter'])
   nk.input_key(ctx, 'tab', key_down['tab'])
   nk.input_key(ctx, 'backspace', key_down['backspace'])
   nk.input_key(ctx, 'left', key_down['left'])
   nk.input_key(ctx, 'right', key_down['right'])
   nk.input_key(ctx, 'up', key_down['up'])
   nk.input_key(ctx, 'down', key_down['down'])
   nk.input_key(ctx, 'copy', key_down['copy'])
   nk.input_key(ctx, 'paste', key_down['paste'])
   nk.input_key(ctx, 'cut', key_down['cut'])
   nk.input_key(ctx, 'text undo', key_down['text undo'])
   nk.input_key(ctx, 'text redo', key_down['text redo'])

   local x, y = mouse.x, mouse.y
   nk.input_motion(ctx, x, y)
   nk.input_button(ctx, 'left', x, y, mouse.left)
   nk.input_button(ctx, 'middle', x, y, mouse.middle)
   nk.input_button(ctx, 'right', x, y, mouse.right)
   nk.input_unicode(ctx, table.unpack(text_input))
   text_input = {}
   nk.input_scroll(ctx, scroll_x, scroll_y)
   scroll_x, scroll_y = 0, 0
   nk.input_end(ctx)

   -- == GUI (front-end) ======================================================
   do
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
         canvas:draw_text({30, 30, 150, 20}, "Text to draw", font, rgb(188,174,118), rgb(0,0,0))

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
   -- =========================================================================

   -- Draw ---------------------------------------
   gl.clear('color')
   gl.clear_color(0.2, 0.2, 0.2, 1.0)

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

   -- convert from command queue into draw list and draw to screen
   gl.bind_vertex_array(vao)
   gl.bind_buffer('array', vbo)
   gl.bind_buffer('element array', ebo)
   -- load draw vertices & elements directly into vertex + element buffer
   local vertices = gl.map_buffer('array', 'write only')
   local elements = gl.map_buffer('element array', 'write only')
   -- setup buffers to load vertices and elements
   vbuf:init(vertices, VBO_SIZE)
   ebuf:init(elements, EBO_SIZE)
   ctx:convert(cmds, vbuf, ebuf)
   gl.unmap_buffer('array')
   gl.unmap_buffer('element array')

   -- iterate over and execute each draw command
   local offset, elem_count = 0, 0
   local scale_x, scale_y = SCALE[1], SCALE[2]
   local commands = ctx:draw_commands(cmds)
   for _, cmd in ipairs(commands) do
      elem_count = cmd.elem_count
      if elem_count > 0 then
         gl.bind_texture('2d', cmd.texture_id)
         local x, y, w, h = table.unpack(cmd.clip_rect)
         x, y, w, h = floor(x*scale_x), floor(H-(y+h)*scale_y), floor(w*scale_x), floor(h*scale_y)
         gl.scissor(x, y, w, h)
         gl.draw_elements('triangles', elem_count, 'ushort', offset)
         offset = offset + elem_count*USHORTSZ
      end
   end
   cmds:clear()
   vbuf:clear()
   ebuf:clear()
   ctx:clear(ctx)

   -- default OpenGL state
   gl.use_program(0)
   gl.unbind_buffer('array')
   gl.unbind_buffer('element array')
   gl.unbind_vertex_array()
   gl.disable('blend')
   gl.disable('scissor test')

   glfw.swap_buffers(window)
   collectgarbage()
end

-- cleanups
gl.delete_program(prog)
gl.delete_textures(font_tex)
gl.delete_vertex_arrays(vao)
gl.delete_buffers(vbo, ebo)
cmds:free()
atlas:free()

