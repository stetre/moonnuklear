-- node_editor.lua
--
-- This is a simple node editor just to show a simple implementation and that
-- it is possible to achieve it with this library. While all nodes inside this
-- example use a simple color modifier as content you could change them
-- to have your custom content depending on the node time.
-- Biggest difference to most usual implementation is that this example does
-- not have connectors on the right position of the property that it links.
-- This is mainly done out of laziness and could be implemented as well but
-- requires calculating the position of all rows and add connectors.
-- In addition adding and removing nodes is quite limited at the
-- moment since it is based on a simple fixed array. If this is to be converted
-- into something more serious it is probably best to extend it.

local nk = require("moonnuklear")

local GRID_SIZE, GRID_COLOR = 32.0, { 50/255, 50/255, 50/255, 1}
local CONNECTOR_COLOR = {100/255, 100/255, 100/255, 1}
local WINDOW_FLAGS = nk.WINDOW_BORDER|nk.WINDOW_NO_SCROLLBAR|nk.WINDOW_MOVABLE|nk.WINDOW_CLOSABLE
local NODE_WINDOW_FLAGS = nk.WINDOW_MOVABLE|nk.WINDOW_NO_SCROLLBAR|nk.WINDOW_BORDER|nk.WINDOW_TITLE

local Editor = {}
local function editor_init()
   local editor = setmetatable({}, {__index = Editor})
   editor.IDs = 1
   editor.node_count = 0
   editor.links = {}
   editor.nodes = {} -- indexed by id
   editor.scrolling = {0, 0}
   editor.show_grid = true
   editor.linking = { active=false, node=nil, input_id=0, input_slot=0}
   editor.bounds = {0, 0, 0, 0}
   editor.selected = nil
   editor.first, editor.last = nil, nil -- nodes list
   editor:add("Source", {40, 10, 180, 220}, {1, 0, 0, 1}, 0, 1)
   editor:add("Source", {40, 260, 180, 220}, {0, 1, 0, 1}, 0, 1)
   editor:add("Combine", {400, 100, 180, 220}, {0,0,1, 1}, 2, 2)
   editor:link(1, 1, 3, 1)
   editor:link(2, 1, 3, 2)
   return editor
end

function Editor.push(editor, node)
   if not editor.first then
      node.next, node.prev = nil, nil
      editor.first, editor.last = node, node
   else
      node.prev = editor.last
      if editor.last then editor.last.next = node end
      node.next = nil
      editor.last = node
   end
end

function Editor.pop(editor, node)
   if node.next then node.next.prev = node.prev end
   if node.prev then node.prev.next = node.next end
   if editor.last == node then editor.last = node.prev end
   if editor.first== node then editor.first= node.next end
   node.next, node.prev = nil, nil
end

function Editor.find(editor, id) return editor.nodes[id] end

function Editor.add(editor, name, bounds, color, in_count, out_count)
   local node = {
      ID = editor.IDs,
      name = name,
      value = 0,
      bounds = bounds,
      color = color or {1, 0, 0, 1},
      input_count = in_count,
      output_count = out_count,
   }
   editor.nodes[node.ID] = node
   editor:push(node)
   editor.IDs = editor.IDs + 1
   editor.node_count = editor.node_count + 1
end

function Editor.link(editor, in_id, in_slot, out_id, out_slot)
   table.insert(editor.links, {
      input_id = in_id, 
      input_slot = in_slot,
      output_id = out_id,
      output_slot = out_slot,
   })
end


local nodedit = editor_init()

return function(ctx)
    if nk.window_begin(ctx, "NodeEdit", {0, 0, 800, 600}, WINDOW_FLAGS) then
      -- allocate complete window space
      --@@ print("A", nk.window_get_panel(ctx))
      local canvas = nk.window_get_canvas(ctx)
      local total_space = nk.window_get_content_region(ctx)
      nk.layout_space_begin(ctx, 'static', total_space[4], nodedit.node_count)
      local sx, sy, sw, sh = table.unpack(nk.layout_space_bounds(ctx))

      if nodedit.show_grid then
         local x = (sx - nodedit.scrolling[1]) % GRID_SIZE
         while x < sw do
            canvas:stroke_line(x+sx, sy, x+sx, sy+sh, 1.0, GRID_COLOR)
            x = x + GRID_SIZE
         end
         local y = (sy - nodedit.scrolling[2])%GRID_SIZE
         while y < sh do
            canvas:stroke_line(sx, y+sy, sx+sw, y+sy, 1.0, GRID_COLOR)
            y = y + GRID_SIZE
         end
      end

      -- execute each node as a movable group 
      local updated
      local node = nodedit.first
      local panel
      while node do
         -- calculate scrolled node window position and size 
         nk.layout_space_push(ctx, { node.bounds[1] - nodedit.scrolling[1],
                    node.bounds[2] - nodedit.scrolling[2], node.bounds[3], node.bounds[4]})

       --@@ print("B", nk.window_get_panel(ctx))
         -- execute node window 
         if nk.group_begin(ctx, node.name, NODE_WINDOW_FLAGS) then
            -- always have last selected node on top 
            panel = nk.window_get_panel(ctx)
       --@@ print("C", nk.window_get_panel(ctx))
            local panel_bounds =  panel:get_bounds()
            if ctx:mouse_clicked('left', panel_bounds)
               and not (node.prev and 
                   ctx:mouse_clicked('left', nk.layout_space_rect_to_screen(ctx, panel_bounds))) 
               and nodedit.last ~= node
               then updated = node
            end
            -- ================= NODE CONTENT =====================
            nk.layout_row_dynamic(ctx, 25, 1)
            nk.button(ctx, node.color)
            local r, g, b, a = nk.color_bytes(node.color)
            r = nk.property(ctx, "#R:", 0, r, 255, 1,1)
            g = nk.property(ctx, "#G:", 0, g, 255, 1,1)
            b = nk.property(ctx, "#B:", 0, b, 255, 1,1)
            a = nk.property(ctx, "#A:", 0, a, 255, 1,1)
            node.color = nk.color_from_bytes(r,g,b,a)
            -- ====================================================
            nk.group_end(ctx)
         end

      --@@ print("D", nk.window_get_panel(ctx))
         -- node connector and linking 
         local px, py, pw, ph = table.unpack(panel:get_bounds())
         local bounds = nk.layout_space_rect_to_local(ctx, {px, py, pw, ph})
         --local bounds = nk.layout_space_rect_to_local(ctx, panel:get_bounds())
         bounds[1] = bounds[1] + nodedit.scrolling[1]
         bounds[2] = bounds[2] + nodedit.scrolling[2]
         node.bounds = bounds

         -- output connector 
         local space = ph/(node.output_count + 1)
         for n = 1, node.output_count do
            local circle = { px + pw-4, py + space*n, 8, 8}
            canvas:fill_circle(circle, CONNECTOR_COLOR)
            -- start linking process 
            if ctx:has_mouse_click_down_in_rect('left', circle, true) then
               nodedit.linking.active = true
               nodedit.linking.node = node 
               nodedit.linking.input_id = node.ID
               nodedit.linking.input_slot = n
            end
            -- draw curve from linked node slot to mouse position
            if nodedit.linking.active and nodedit.linking.node == node and 
                     nodedit.linking.input_slot == n then
               local x0, y0 = circle[1] + 3, circle[2] + 3
               local x1, y1 = ctx:mouse_pos()
               canvas:stroke_curve(x0, y0, x0+50, y0, x1-50, y1, x1, y1, 1, CONNECTOR_COLOR)
            end
         end

         -- input connector 
         local space = ph/(node.input_count+1)
         for n = 1, node.input_count do
            local circle = { px-4, py + space*n, 8, 8}
            canvas:fill_circle(circle, CONNECTOR_COLOR)
            if ctx:is_mouse_released('left') and   ctx:is_mouse_hovering_rect(circle)
                  and nodedit.linking.active and nodedit.linking.node ~= node then
               nodedit.linking.active = false
               nodedit:link(nodedit.linking.input_id, nodedit.linking.input_slot, node.ID, n)
            end
         end

         node = node.next
      end

      -- reset linking connection 
      if nodedit.linking.active and ctx:is_mouse_released('left') then
         nodedit.linking.active = false
         nodedit.linking.node = nil
         print("linking failed")
      end

      -- draw each link 
      for _, link in ipairs(nodedit.links) do
         local px, py, pw, ph = table.unpack(panel:get_bounds())
         local ni = nodedit:find(link.input_id)
         local no = nodedit:find(link.output_id)
         local spacei = ph/(ni.output_count + 1)
         local spaceo = ph/(no.input_count + 1)
         local nx, ny, nw, nh = table.unpack(ni.bounds)
         local x0, y0 = table.unpack(nk.layout_space_to_screen(ctx, 
                  { nx+nw, 3 + ny + spacei*link.input_slot}))
         local nx, ny, nw, nh = table.unpack(no.bounds)
         local x1, y1 = table.unpack(nk.layout_space_to_screen(ctx,
                  {nx, 3 + ny + spaceo*link.output_slot}))
         x0 = x0 - nodedit.scrolling[1]
         y0 = y0 - nodedit.scrolling[2]
         x1 = x1 - nodedit.scrolling[1]
         y1 = y1 - nodedit.scrolling[2]
         canvas:stroke_curve(x0, y0, x0 + 50, y0, x1 - 50, y1, x1, y1, 1, CONNECTOR_COLOR)
      end

      if updated then -- reshuffle nodes to have least recently selected node on top 
         nodedit:pop(updated)
         nodedit:push(updated)
      end

      -- node selection 
      if ctx:mouse_clicked('left', nk.layout_space_bounds(ctx)) then
         local node = nodedit.first
         nodedit.selected = nil
         local mx, my = ctx:mouse_pos()
         nodedit.bounds = {mx, my, 100, 200}
         while node do
            local b = nk.layout_space_rect_to_screen(ctx, node.bounds)
            b[1] = b[1] - nodedit.scrolling[1]
            b[2] = b[2] - nodedit.scrolling[2]
            if ctx:is_mouse_hovering_rect( b) then
               nodedit.selected = node
            end
            node = node.next
         end
      end

      -- contextual menu 
      if nk.contextual_begin(ctx, 0, {100, 220}, nk.window_get_bounds(ctx)) then
         nk.layout_row_dynamic(ctx, 25, 1)
         if nk.contextual_item(ctx, nil, "New", nk.TEXT_CENTERED) then
            nodedit:add("New", {400, 260, 180, 220}, {1, 1, 1, 1}, 1, 2)
         end
         local name = nodedit.show_grid and "Hide Grid" or "Show Grid"
         if nk.contextual_item(ctx, nil, name, nk.TEXT_CENTERED) then
            nodedit.show_grid = not nodedit.show_grid
         end
         nk.contextual_end(ctx)
      end

      nk.layout_space_end(ctx)

      -- window content scrolling 
      if ctx:is_mouse_hovering_rect(nk.window_get_bounds(ctx)) and
            ctx:is_mouse_down('middle') then 
         local dx, dy = ctx:mouse_delta()
         nodedit.scrolling[1] = nodedit.scrolling[1] + dx
         nodedit.scrolling[2] = nodedit.scrolling[2] + dy
      end
   end
   nk.window_end(ctx)
   return not nk.window_is_closed(ctx, "NodeEdit")
end
