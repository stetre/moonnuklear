-- GL/GLFW backend/application template for small example apps,
-- derived from the original examples that come with Nuklear.
local backend = {} -- module table

local glfw = require("moonglfw")
local gl = require("moongl")
local nk = require("moonnuklear")

local floor = math.floor

local TITLE = "Example"
local BGCOLOR = {.2, .2, .2, 1.0} -- default background color
local W, H  -- window width and height
local DISPLAY_W, DISPLAY_H -- display width and height
local VBO_SIZE = 512 * 1024 -- size of vertex buffer
local EBO_SIZE = 128 * 1024 -- size of element buffer
local DOUBLE_CLICK_LO, DOUBLE_CLICK_HI = .02, .2

local FLOATSZ, BYTESZ, USHORTSZ = gl.sizeof('float'), gl.sizeof('byte'), gl.sizeof('ushort')

local window, prog, uniform_proj
local cmds, vbuf, ebuf, vao, vbo, ebo
local ctx, atlas, font, font_tex

-- Input state as recorded within GLFW callbacks:
local key_down = {} -- indexed by Nuklear keys
local mouse = { 
   left=false, middle=false, right=false, x=0, y=0, 
   double=false, double_x=0, double_y=0, last_click=0, 
}
local scroll_x, scroll_y = 0, 0
local text_input = {} -- array of codepoints

local scale_x, scale_y = 0, 0
local ortho = { -- base projection matrix, will becompleted in rescale()
   {0.0, 0.0, 0.0,-1.0},
   {0.0, 0.0, 0.0, 1.0},
   {0.0, 0.0,-1.0, 0.0},
   {0.0, 0.0, 0.0, 1.0},
}

local function rescale() 
-- Updates viewport and projection matrix based on current window size.
   scale_x, scale_y = DISPLAY_W/W, DISPLAY_H/H
   gl.viewport(0, 0, DISPLAY_W, DISPLAY_H)
   ortho[1][1] = 2.0/W
   ortho[2][2] = -2.0/H
   gl.use_program(prog)
   gl.uniform_matrix4f(uniform_proj, true, ortho)
end

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

-------------------------------------------------------------------------------
function backend.init(width, height, title, anti_aliasing, font_path)
-------------------------------------------------------------------------------
-- Initializes the backend.
-- width, height: initial dimensions of the window
-- title: window title
-- anti_aliasing: if =true then AA is turned on
-- font_path: optional full path filename of a ttf file
   W, H = width, height

   -- Init GLFW and OpenGL
   glfw.version_hint(3, 3, 'core')
   window = glfw.create_window(W, H, title or TITLE)
   glfw.make_context_current(window)
   gl.init()

   -- Setup fonts
   atlas = nk.new_font_atlas()
   atlas:begin()
   font = atlas:add(13.0, font_path) -- if font_path==nil, uses the default
   local pixels, w, h = atlas:bake('rgba32') 
   font_tex = gl.new_texture('2d')
   gl.texture_parameter('2d', 'min filter', 'linear')
   gl.texture_parameter('2d', 'mag filter', 'linear')
   gl.texture_image('2d', 0, 'rgba', 'rgba', 'ubyte', pixels, w, h)
   local null_tex, null_uv = atlas:done(font_tex)

   -- Create the Nuklear context
   ctx = nk.init(font)

   -- Build the shader program
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

   -- Setup OpenGL buffers
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

   -- Setup Nuklear buffers
   cmds = nk.new_buffer("dynamic") -- buffer for Nuklear commands
   vbuf = nk.new_buffer("fixed") -- buffer for Nuklear to write vertex data to
   ebuf = nk.new_buffer("fixed") -- buffer for Nuklear to write element indices to

   -- Convert configuration
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
   if anti_aliasing then
      ctx:config_shape_aa(anti_aliasing)
      ctx:config_line_aa(anti_aliasing)
   end

   -- Set GLFW callbacks

   glfw.set_window_size_callback(window, function(window, w, h)
      W, H = w, h
      rescale()
   end)

   glfw.set_framebuffer_size_callback(window, function(window, w, h)
      DISPLAY_W, DISPLAY_H = w, h
      rescale()
   end)

   glfw.set_key_callback(window, function(window, key, scancode, action, shift, control, alt, super)
      if key == 'escape' and action == 'press' then
         -- exiting with ESC is nice when fiddling with the examples...
         glfw.set_window_should_close(window, true)
         return
      end
      -- translate GLFW key events to Nuklear key events:
      local down = action ~= 'release'
      if     key == 'left shift' then key_down['shift'] = down
      elseif key == 'right shift' then key_down['shift'] = down
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

   glfw.set_mouse_button_callback(window, function(window, button, action)
      mouse[button] = action == 'press'
      if button == 'left' then
         if action == 'press' then
            local now = glfw.get_time()
            local dt = now - mouse.last_click
            mouse.last_click = now
            if dt > DOUBLE_CLICK_LO and dt < DOUBLE_CLICK_HI then
               mouse.double = true
               mouse.double_x, mouse.double_y = glfw.get_cursor_pos(window)
            end
         else
            mouse.double = false
         end
      end
   end)

   glfw.set_cursor_pos_callback(window, function(window, x, y)
      mouse.x, mouse.y = x, y
   end)

   glfw.set_scroll_callback(window, function(window, xofs, yofs)
      scroll_x, scroll_y = scroll_x + xofs, scroll_y + yofs
   end)

   glfw.set_char_callback(window, function(window, codepoint)
      table.insert(text_input, codepoint)
   end)

   ctx:set_clipboard_copy(function(text)
      if #text>0 then glfw.set_clipboard_string(window, text) end
   end)

   ctx:set_clipboard_paste(function(edit)
      local text = glfw.get_clipboard_string(window)
      if #text>0 then edit:paste(text) end
   end)

   -- Initialize viewport
   W, H = glfw.get_window_size(window)
   DISPLAY_W, DISPLAY_H = glfw.get_framebuffer_size(window)
   rescale()
end


-------------------------------------------------------------------------------
function backend.loop(guifunc, bgcolor, fps)
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

   collectgarbage()
   collectgarbage('stop')
   while not glfw.window_should_close(window) do
      glfw.wait_events_timeout(1/fps) -- glfw.poll_events()

      -- Input mirroring
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
      nk.input_button(ctx, 'double', mouse.double_x, mouse.double_y, mouse.double)
      nk.input_unicode(ctx, table.unpack(text_input))
      text_input = {}
      nk.input_scroll(ctx, scroll_x, scroll_y)
      scroll_x, scroll_y = 0, 0
      nk.input_end(ctx)

      -- Execute the front-end
      guifunc(ctx)

      -- Clear the framebuffer
      gl.clear('color')
      gl.clear_color(bgcolor)

      -- Setup global state
      gl.enable('blend')
      gl.blend_equation('add')
      gl.blend_func('src alpha', 'one minus src alpha')
      gl.disable('cull face')
      gl.disable('depth test')
      gl.enable('scissor test')
      gl.active_texture(0)

      gl.use_program(prog)

      -- Convert from command queue into draw list
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

      -- Iterate over and execute each draw command
      local offset, elem_count = 0, 0
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
      nk.clear_buffers(cmds, vbuf, ebuf)
      ctx:clear(ctx)

      -- Restore the default OpenGL state
      gl.use_program(0)
      gl.unbind_buffer('array')
      gl.unbind_buffer('element array')
      gl.unbind_vertex_array()
      gl.disable('blend')
      gl.disable('scissor test')

      -- Finally, swap front and back buffers:
      glfw.swap_buffers(window)
      collectgarbage()
   end

   -- Cleanups
   gl.delete_program(prog)
   gl.delete_textures(font_tex)
   gl.delete_vertex_arrays(vao)
   gl.delete_buffers(vbo, ebo)
   cmds:free()
   atlas:free()
end

-------------------------------------------------------------------------------

return backend

