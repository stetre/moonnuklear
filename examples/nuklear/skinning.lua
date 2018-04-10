#!/usr/bin/env lua

local glfw = require("moonglfw")
local gl = require("moongl")
local nk = require("moonnuklear")
local mi = require("moonimage")

local floor = math.floor
local abs, sin, cos = math.abs, math.sin, math.cos

local FONT_PATH = arg[1]
local ANTI_ALIASING = true
if arg[2] == "no-aa" then ANTI_ALIASING = false end
local SKIN = "images/gwen.png"

local TITLE = "Skinning example"
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
};]]

local fragment_shader = [[
#version 330 core
precision mediump float;
uniform sampler2D Texture;
in vec2 Frag_UV;
in vec4 Frag_Color;
out vec4 Out_Color;
void main(){
   Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
};]]

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
   font = atlas:add(13.0, FONT_PATH, {}) -- if FONT_PATH==nil, uses the default
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

   -- create skin -------------------------------------------------
   -- load the sprites atlas and create texture
   local data, w, h = mi.load(SKIN, 'rgba')
   skin = gl.new_texture('2d')
   gl.texture_parameter('2d', 'min filter', 'linear mipmap nearest')
   gl.texture_parameter('2d', 'mag filter', 'nearest')
   gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
   gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
   gl.texture_image('2d', 0, 'rgba8', 'rgba', 'ubyte', data, w, h)
   gl.generate_mipmap('2d')

   -- create sprites
   local sprite = {}
   sprite.check = nk.new_subimage(skin, 512,512, {464,32,15,15})
   sprite.check_cursor = nk.new_subimage(skin, 512,512, {450,34,11,11})
   sprite.option = nk.new_subimage(skin, 512,512, {464,64,15,15})
   sprite.option_cursor = nk.new_subimage(skin, 512,512, {451,67,9,9})
   sprite.header = nk.new_subimage(skin, 512,512, {128,0,127,24})
   sprite.window = nk.new_subimage(skin, 512,512, {128,23,127,104})
   sprite.scrollbar_inc_button = nk.new_subimage(skin, 512,512, {464,256,15,15})
   sprite.scrollbar_inc_button_hover = nk.new_subimage(skin, 512,512, {464,320,15,15})
   sprite.scrollbar_dec_button = nk.new_subimage(skin, 512,512, {464,224,15,15})
   sprite.scrollbar_dec_button_hover = nk.new_subimage(skin, 512,512, {464,288,15,15})
   sprite.button = nk.new_subimage(skin, 512,512, {384,336,127,31})
   sprite.button_hover = nk.new_subimage(skin, 512,512, {384,368,127,31})
   sprite.button_active = nk.new_subimage(skin, 512,512, {384,400,127,31})
   sprite.tab_minimize = nk.new_subimage(skin, 512,512, {451, 99, 9, 9})
   sprite.tab_maximize = nk.new_subimage(skin, 512,512, {467,99,9,9})
   sprite.slider = nk.new_subimage(skin, 512,512, {418,33,11,14})
   sprite.slider_hover = nk.new_subimage(skin, 512,512, {418,49,11,14})
   sprite.slider_active = nk.new_subimage(skin, 512,512, {418,64,11,14})

   -- set style fields
   local rgb = nk.color_from_bytes -- this automatically sets a=1.0 (255)
   local TRANSPARENT = {0, 0, 0, 0}
   -- window
   nk.style_set_color(ctx, 'window.background', rgb(204,204,204))
   nk.style_set_style_item(ctx, 'window.fixed_background', sprite.window)
   nk.style_set_color(ctx, 'window.border_color', rgb(67,67,67))
   nk.style_set_color(ctx, 'window.combo_border_color', rgb(67,67,67))
   nk.style_set_color(ctx, 'window.contextual_border_color', rgb(67,67,67))
   nk.style_set_color(ctx, 'window.menu_border_color', rgb(67,67,67))
   nk.style_set_color(ctx, 'window.group_border_color', rgb(67,67,67))
   nk.style_set_color(ctx, 'window.tooltip_border_color', rgb(67,67,67))
   nk.style_set_vec2(ctx, 'window.scrollbar_size', {16,16})
   nk.style_set_color(ctx, 'window.border_color', TRANSPARENT)
   nk.style_set_vec2(ctx, 'window.padding', {8,4})
   nk.style_set_float(ctx, 'window.border', 3)
   -- window header
   nk.style_set_style_item(ctx, 'window.header.normal', sprite.header)
   nk.style_set_style_item(ctx, 'window.header.hover', sprite.header)
   nk.style_set_style_item(ctx, 'window.header.active', sprite.header)
   nk.style_set_color(ctx, 'window.header.label_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'window.header.label_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'window.header.label_active', rgb(95,95,95))
   -- scrollbar
   nk.style_set_style_item(ctx, 'scrollv.normal', rgb(184,184,184))
   nk.style_set_style_item(ctx, 'scrollv.hover', rgb(184,184,184))
   nk.style_set_style_item(ctx, 'scrollv.active', rgb(184,184,184))
   nk.style_set_style_item(ctx, 'scrollv.cursor_normal', rgb(220,220,220))
   nk.style_set_style_item(ctx, 'scrollv.cursor_hover', rgb(235,235,235))
   nk.style_set_style_item(ctx, 'scrollv.cursor_active', rgb(99,202,255))
   nk.style_set_symbol_type(ctx, 'scrollv.dec_symbol', 'none')
   nk.style_set_symbol_type(ctx, 'scrollv.inc_symbol', 'none')
   nk.style_set_boolean(ctx, 'scrollv.show_buttons', true)
   nk.style_set_color(ctx, 'scrollv.border_color', rgb(81,81,81))
   nk.style_set_color(ctx, 'scrollv.cursor_border_color', rgb(81,81,81))
   nk.style_set_float(ctx, 'scrollv.border', 1)
   nk.style_set_float(ctx, 'scrollv.rounding', 0)
   nk.style_set_float(ctx, 'scrollv.border_cursor', 1)
   nk.style_set_float(ctx, 'scrollv.rounding_cursor', 2)
   -- scrollbar buttons
   nk.style_set_style_item(ctx, 'scrollv.inc_button.normal', sprite.scrollbar_inc_button)
   nk.style_set_style_item(ctx, 'scrollv.inc_button.hover', sprite.scrollbar_inc_button_hover)
   nk.style_set_style_item(ctx, 'scrollv.inc_button.active', sprite.scrollbar_inc_button_hover)
   nk.style_set_color(ctx, 'scrollv.inc_button.border_color', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.inc_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.inc_button.text_normal', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.inc_button.text_hover', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.inc_button.text_active', TRANSPARENT)
   nk.style_set_float(ctx, 'scrollv.inc_button.border', 0.0)
   nk.style_set_style_item(ctx, 'scrollv.dec_button.normal', sprite.scrollbar_dec_button)
   nk.style_set_style_item(ctx, 'scrollv.dec_button.hover', sprite.scrollbar_dec_button_hover)
   nk.style_set_style_item(ctx, 'scrollv.dec_button.active', sprite.scrollbar_dec_button_hover)
   nk.style_set_color(ctx, 'scrollv.dec_button.border_color', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.dec_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.dec_button.text_normal', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.dec_button.text_hover', TRANSPARENT)
   nk.style_set_color(ctx, 'scrollv.dec_button.text_active', TRANSPARENT)
   nk.style_set_float(ctx, 'scrollv.dec_button.border', 0.0)
   -- checkbox toggle
   nk.style_set_style_item(ctx, 'checkbox.normal', sprite.check)
   nk.style_set_style_item(ctx, 'checkbox.hover', sprite.check)
   nk.style_set_style_item(ctx, 'checkbox.active', sprite.check)
   nk.style_set_style_item(ctx, 'checkbox.cursor_normal', sprite.check_cursor)
   nk.style_set_style_item(ctx, 'checkbox.cursor_hover', sprite.check_cursor)
   nk.style_set_color(ctx, 'checkbox.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'checkbox.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'checkbox.text_active', rgb(95,95,95))
   -- option toggle
   nk.style_set_style_item(ctx, 'option.normal', sprite.option)
   nk.style_set_style_item(ctx, 'option.hover', sprite.option)
   nk.style_set_style_item(ctx, 'option.active', sprite.option)
   nk.style_set_style_item(ctx, 'option.cursor_normal', sprite.option_cursor)
   nk.style_set_style_item(ctx, 'option.cursor_hover', sprite.option_cursor)
   nk.style_set_color(ctx, 'option.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'option.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'option.text_active', rgb(95,95,95))
   -- default button
   nk.style_set_style_item(ctx, 'button.normal', sprite.button)
   nk.style_set_style_item(ctx, 'button.hover', sprite.button_hover)
   nk.style_set_style_item(ctx, 'button.active', sprite.button_active)
   nk.style_set_color(ctx, 'button.border_color', TRANSPARENT)
   nk.style_set_color(ctx, 'button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'button.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'button.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'button.text_active', rgb(95,95,95))
   -- default text
   nk.style_set_color(ctx, 'text.color', rgb(95,95,95))
   -- contextual button
   nk.style_set_style_item(ctx, 'contextual_button.normal', rgb(206,206,206))
   nk.style_set_style_item(ctx, 'contextual_button.hover', rgb(229,229,229))
   nk.style_set_style_item(ctx, 'contextual_button.active', rgb(99,202,255))
   nk.style_set_color(ctx, 'contextual_button.border_color', TRANSPARENT)
   nk.style_set_color(ctx, 'contextual_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'contextual_button.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'contextual_button.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'contextual_button.text_active', rgb(95,95,95))
   -- menu button
   nk.style_set_style_item(ctx, 'menu_button.normal', rgb(206,206,206))
   nk.style_set_style_item(ctx, 'menu_button.hover', rgb(229,229,229))
   nk.style_set_style_item(ctx, 'menu_button.active', rgb(99,202,255))
   nk.style_set_color(ctx, 'menu_button.border_color', TRANSPARENT)
   nk.style_set_color(ctx, 'menu_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'menu_button.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'menu_button.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'menu_button.text_active', rgb(95,95,95))
   -- tree
   nk.style_set_color(ctx, 'tab.text', rgb(95,95,95))
   nk.style_set_style_item(ctx, 'tab.tab_minimize_button.normal', sprite.tab_minimize)
   nk.style_set_style_item(ctx, 'tab.tab_minimize_button.hover', sprite.tab_minimize)
   nk.style_set_style_item(ctx, 'tab.tab_minimize_button.active', sprite.tab_minimize)
   nk.style_set_color(ctx, 'tab.tab_minimize_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.tab_minimize_button.text_normal', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.tab_minimize_button.text_hover', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.tab_minimize_button.text_active', TRANSPARENT)
   nk.style_set_style_item(ctx, 'tab.tab_maximize_button.normal', sprite.tab_maximize)
   nk.style_set_style_item(ctx, 'tab.tab_maximize_button.hover', sprite.tab_maximize)
   nk.style_set_style_item(ctx, 'tab.tab_maximize_button.active', sprite.tab_maximize)
   nk.style_set_color(ctx, 'tab.tab_maximize_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.tab_maximize_button.text_normal', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.tab_maximize_button.text_hover', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.tab_maximize_button.text_active', TRANSPARENT)
   nk.style_set_style_item(ctx, 'tab.node_minimize_button.normal', sprite.tab_minimize)
   nk.style_set_style_item(ctx, 'tab.node_minimize_button.hover', sprite.tab_minimize)
   nk.style_set_style_item(ctx, 'tab.node_minimize_button.active', sprite.tab_minimize)
   nk.style_set_color(ctx, 'tab.node_minimize_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.node_minimize_button.text_normal', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.node_minimize_button.text_hover', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.node_minimize_button.text_active', TRANSPARENT)
   nk.style_set_style_item(ctx, 'tab.node_maximize_button.normal', sprite.tab_maximize)
   nk.style_set_style_item(ctx, 'tab.node_maximize_button.hover', sprite.tab_maximize)
   nk.style_set_style_item(ctx, 'tab.node_maximize_button.active', sprite.tab_maximize)
   nk.style_set_color(ctx, 'tab.node_maximize_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.node_maximize_button.text_normal', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.node_maximize_button.text_hover', TRANSPARENT)
   nk.style_set_color(ctx, 'tab.node_maximize_button.text_active', TRANSPARENT)
   -- selectable
   nk.style_set_style_item(ctx, 'selectable.normal', rgb(206,206,206))
   nk.style_set_style_item(ctx, 'selectable.hover', rgb(206,206,206))
   nk.style_set_style_item(ctx, 'selectable.pressed', rgb(206,206,206))
   nk.style_set_style_item(ctx, 'selectable.normal_active', rgb(185,205,248))
   nk.style_set_style_item(ctx, 'selectable.hover_active', rgb(185,205,248))
   nk.style_set_style_item(ctx, 'selectable.pressed_active', rgb(185,205,248))
   nk.style_set_color(ctx, 'selectable.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'selectable.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'selectable.text_pressed', rgb(95,95,95))
   nk.style_set_color(ctx, 'selectable.text_normal_active', rgb(95,95,95))
   nk.style_set_color(ctx, 'selectable.text_hover_active', rgb(95,95,95))
   nk.style_set_color(ctx, 'selectable.text_pressed_active', rgb(95,95,95))
   -- slider
   nk.style_set_style_item(ctx, 'slider.normal', 'hide')
   nk.style_set_style_item(ctx, 'slider.hover', 'hide')
   nk.style_set_style_item(ctx, 'slider.active', 'hide')
   nk.style_set_color(ctx, 'slider.bar_normal', rgb(156,156,156))
   nk.style_set_color(ctx, 'slider.bar_hover', rgb(156,156,156))
   nk.style_set_color(ctx, 'slider.bar_active', rgb(156,156,156))
   nk.style_set_color(ctx, 'slider.bar_filled', rgb(156,156,156))
   nk.style_set_style_item(ctx, 'slider.cursor_normal', sprite.slider)
   nk.style_set_style_item(ctx, 'slider.cursor_hover', sprite.slider_hover)
   nk.style_set_style_item(ctx, 'slider.cursor_active', sprite.slider_active)
   nk.style_set_vec2(ctx, 'slider.cursor_size', {16.5,21})
   nk.style_set_float(ctx, 'slider.bar_height', 1)
   -- progressbar
   nk.style_set_style_item(ctx, 'progress.normal', rgb(231,231,231))
   nk.style_set_style_item(ctx, 'progress.hover', rgb(231,231,231))
   nk.style_set_style_item(ctx, 'progress.active', rgb(231,231,231))
   nk.style_set_style_item(ctx, 'progress.cursor_normal', rgb(63,242,93))
   nk.style_set_style_item(ctx, 'progress.cursor_hover', rgb(63,242,93))
   nk.style_set_style_item(ctx, 'progress.cursor_active', rgb(63,242,93))
   nk.style_set_color(ctx, 'progress.border_color', rgb(114,116,115))
   nk.style_set_vec2(ctx, 'progress.padding', {0,0})
   nk.style_set_float(ctx, 'progress.border', 2)
   nk.style_set_float(ctx, 'progress.rounding', 1)
   -- combo
   nk.style_set_style_item(ctx, 'combo.normal', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'combo.hover', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'combo.active', rgb(216,216,216))
   nk.style_set_color(ctx, 'combo.border_color', rgb(95,95,95))
   nk.style_set_color(ctx, 'combo.label_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'combo.label_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'combo.label_active', rgb(95,95,95))
   nk.style_set_float(ctx, 'combo.border', 1)
   nk.style_set_float(ctx, 'combo.rounding', 1)
   -- combo button
   nk.style_set_style_item(ctx, 'combo.button.normal', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'combo.button.hover', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'combo.button.active', rgb(216,216,216))
   nk.style_set_color(ctx, 'combo.button.text_background', rgb(216,216,216))
   nk.style_set_color(ctx, 'combo.button.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'combo.button.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'combo.button.text_active', rgb(95,95,95))
   -- property
   nk.style_set_style_item(ctx, 'property.normal', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.hover', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.active', rgb(216,216,216))
   nk.style_set_color(ctx, 'property.border_color', rgb(81,81,81))
   nk.style_set_color(ctx, 'property.label_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.label_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.label_active', rgb(95,95,95))
   nk.style_set_symbol_type(ctx, 'property.sym_left', 'triangle left')
   nk.style_set_symbol_type(ctx, 'property.sym_right', 'triangle right')
   nk.style_set_float(ctx, 'property.rounding', 10)
   nk.style_set_float(ctx, 'property.border', 1)
   -- edit
   nk.style_set_style_item(ctx, 'edit.normal', rgb(240,240,240))
   nk.style_set_style_item(ctx, 'edit.hover', rgb(240,240,240))
   nk.style_set_style_item(ctx, 'edit.active', rgb(240,240,240))
   nk.style_set_color(ctx, 'edit.border_color', rgb(62,62,62))
   nk.style_set_color(ctx, 'edit.cursor_normal', rgb(99,202,255))
   nk.style_set_color(ctx, 'edit.cursor_hover', rgb(99,202,255))
   nk.style_set_color(ctx, 'edit.cursor_text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'edit.cursor_text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'edit.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'edit.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'edit.text_active', rgb(95,95,95))
   nk.style_set_color(ctx, 'edit.selected_normal', rgb(99,202,255))
   nk.style_set_color(ctx, 'edit.selected_hover', rgb(99,202,255))
   nk.style_set_color(ctx, 'edit.selected_text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'edit.selected_text_hover', rgb(95,95,95))
   nk.style_set_float(ctx, 'edit.border', 1)
   nk.style_set_float(ctx, 'edit.rounding', 2)
   -- property buttons
   nk.style_set_style_item(ctx, 'property.dec_button.normal', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.dec_button.hover', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.dec_button.active', rgb(216,216,216))
   nk.style_set_color(ctx, 'property.dec_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'property.dec_button.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.dec_button.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.dec_button.text_active', rgb(95,95,95))
   nk.style_set_style_item(ctx, 'property.inc_button.normal', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.inc_button.hover', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.inc_button.active', rgb(216,216,216))
   nk.style_set_color(ctx, 'property.inc_button.text_background', TRANSPARENT)
   nk.style_set_color(ctx, 'property.inc_button.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.inc_button.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.inc_button.text_active', rgb(95,95,95))
   -- property edit
   nk.style_set_style_item(ctx, 'property.edit.normal', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.edit.hover', rgb(216,216,216))
   nk.style_set_style_item(ctx, 'property.edit.active', rgb(216,216,216))
   nk.style_set_color(ctx, 'property.edit.border_color', TRANSPARENT)
   nk.style_set_color(ctx, 'property.edit.cursor_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.edit.cursor_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.edit.cursor_text_normal', rgb(216,216,216))
   nk.style_set_color(ctx, 'property.edit.cursor_text_hover', rgb(216,216,216))
   nk.style_set_color(ctx, 'property.edit.text_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.edit.text_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.edit.text_active', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.edit.selected_normal', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.edit.selected_hover', rgb(95,95,95))
   nk.style_set_color(ctx, 'property.edit.selected_text_normal', rgb(216,216,216))
   nk.style_set_color(ctx, 'property.edit.selected_text_hover', rgb(216,216,216))
   -- chart
   nk.style_set_style_item(ctx, 'chart.background', rgb(216,216,216))
   nk.style_set_color(ctx, 'chart.border_color', rgb(81,81,81))
   nk.style_set_color(ctx, 'chart.color', rgb(95,95,95))
   nk.style_set_color(ctx, 'chart.selected_color', rgb(255,0,0))
   nk.style_set_float(ctx, 'chart.border', 1)
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
   if nk.window_begin(ctx, TITLE, {50, 50, 300, 400}, gui.window_flags) then
      nk.layout_row_static(ctx, 30, 120, 1)
      if nk.button(ctx, nil, "button") then print("button pressed") end

      nk.layout_row_dynamic(ctx, 20, 1)
      nk.label(ctx, "Label", nk.TEXT_LEFT)
      nk.layout_row_dynamic(ctx, 30, 2)
      gui.check1 = nk.check(ctx, "inactive", gui.check1)
      gui.check2 = nk.check(ctx, "active", gui.check2)
      gui.option = nk.option(ctx, "active", gui.option)
      gui.option = not nk.option(ctx, "inactive", not gui.option)

      nk.layout_row_dynamic(ctx, 30, 1)
      gui.slider = nk.slider(ctx, 0, gui.slider, 16, 1)

      nk.layout_row_dynamic(ctx, 20, 1)
      gui.prog_value = nk.progress(ctx, gui.prog_value, 100, 'modifiable')


      nk.layout_row_dynamic(ctx, 25, 1)
      gui.field = nk.edit_string(ctx, nk.EDIT_FIELD, gui.field, 64, 'default')
      gui.pos = nk.property(ctx, "#X:", -1024.0, gui.pos, 1024.0, 1, 1)
      gui.current_weapon = nk.combo(ctx, gui.weapons, gui.current_weapon, 25, {nk.widget_width(ctx),200})

      nk.layout_row_dynamic(ctx, 100, 1)
      if nk.chart_begin(ctx, 'lines', 32, 0.0, 1.0, {1,0,0}, {150/255,0,0}) then -- slot 1
         nk.chart_add_slot(ctx, 'lines', 32, -1.0, 1.0, {0,0,1}, {0,0,150/255})  -- slot 2
         nk.chart_add_slot(ctx, 'lines', 32, -1.0, 1.0, {0,1, 0}, {0,150/255,0}) -- slot 3
         local id = 0
         for i = 1, 32 do
            nk.chart_push(ctx, abs(sin(id)), 1)
            nk.chart_push(ctx, cos(id), 2)
            nk.chart_push(ctx, sin(id), 3)
            id = id + STEP
         end
      end
      nk.chart_end(ctx)

      nk.layout_row_dynamic(ctx, 250, 1)
      if nk.group_begin(ctx, "Standard", nk.WINDOW_BORDER) then
         if nk.tree_push(ctx, 'node', "Window", 'maximized', 'tree window') then
            local s = gui.selected
            if nk.tree_push(ctx, 'node', "Next", 'maximized', 'tree next') then
               nk.layout_row_dynamic(ctx, 20, 1)
               for i = 1, 4 do
                  s[i] = nk.selectable(ctx, nil, s[i] and "Selected" or "Unselected", nk.TEXT_LEFT, s[i])
               end
               nk.tree_pop(ctx)
            end
            if nk.tree_push(ctx, 'node', "Previous", 'maximized', 'tree previous') then
               nk.layout_row_dynamic(ctx, 20, 1)
               for i = 5, 8 do
                  s[i] = nk.selectable(ctx, nil, s[i] and "Selected" or "Unselected", nk.TEXT_LEFT, s[i])
               end
               nk.tree_pop(ctx)
            end
            nk.tree_pop(ctx)
         end
         nk.group_end(ctx)
      end
   end
   nk.window_end(ctx)
   -- =========================================================================

   -- Draw ---------------------------------------
   gl.clear('color')
   gl.clear_color(0.5882, 0.6666, 0.6666, 1.0)

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
gl.delete_textures(skin, font_tex)
gl.delete_vertex_arrays(vao)
gl.delete_buffers(vbo, ebo)
cmds:free()
atlas:free()

