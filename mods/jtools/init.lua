minetest.register_tool("jtools:destructinator", {
	description = "Deletes objects",
	inventory_image = "creative_trash_icon.png",
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "node" then
			minetest.remove_node(pointed_thing.under);
		elseif pointed_thing.type == "object" then
			local object = pointed_thing.ref;
			if object:is_player() then
				object:set_hp(0);
			else
				object:remove();
			end
		end
	end,
	range = 20
});


--[[
Editor tool
Allows for a player to edit an entity's contained data
Currently only supports editing strings, numbers, and booleans
--]]
local editor_refs = {}
local editor_name = "jtools:editor"
local editor_inc = 1;
minetest.register_tool(editor_name, {
	description = "Modifies Objects",
	inventory_image = "bubble.png",
	on_use = function(itemstack, user, pointed_thing)
		if not user:is_player() then return end;
		local player_name = user:get_player_name();
		if pointed_thing.type == "object" then
			local object = pointed_thing.ref;
			if object:is_player() then return end
			local lua_ent = object:get_luaentity();
			if not lua_ent then return end
			local formspec = "";
			local width = 8;
			local pos_y = 1;
			local def = lua_ent.jtool_variables or lua_ent;
			for k,_ in pairs(def) do
				local v = lua_ent[k];
				if type(v) == "number" then
					formspec = formspec .. string.format(
						"field[1,%d;%d,1;i%s;%s;%s]", pos_y, width-2,
						tostring(k), tostring(k) .. ":Number", tostring(v));
				elseif type(v) == "string" then
					formspec = formspec .. string.format(
						"field[1,%d;%d,1;s%s;%s;%s]", pos_y, width-2,
						tostring(k), tostring(k) .. ":String", v:sanatize());
				elseif type(v) == "boolean" then
					formspec = formspec .. string.format(
						"field[1,%d;%d,1;b%s;%s;%s]", pos_y, width-2,
						tostring(k), tostring(k) .. ":Boolean", v and 'true' or 'false');
				else
					pos_y = pos_y - 1;
				end
				pos_y = pos_y + 1;
			end
			formspec = string.format("size[%d,%d]", width, pos_y + 1) ..
					formspec .. string.format("button_exit[%d,%d;%d,1;qexit;Apply]",
					width / 4, pos_y, width / 2);

			editor_refs[editor_inc] = object;
			minetest.show_formspec(player_name,
					editor_name .. tostring(editor_inc), formspec);
			editor_inc = editor_inc + 1;
		end
	end,
	range = 20
});

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:sub(1, editor_name:len()) == editor_name then
		local formdata = tonumber(formname:sub(editor_name:len()+1));
		local ref = editor_refs[formdata];
		if ref == nil then return end
		editor_refs[formdata] = nil;
		local lua_ent = ref:get_luaentity();
		if fields.qexit and lua_ent then
			for k,value in pairs(fields) do
				local vtype = k:sub(1, 1);
				local vname = k:sub(2);
				if vtype == 's' then
					lua_ent[vname] = value;
				elseif vtype == 'i' then
					lua_ent[vname] = tonumber(value) or lua_ent[vname];
				elseif vtype == 'b' then
					if value:lower() == 'true' then
						lua_ent[vname] = true;
					elseif value:lower() == 'false' then
						lua_ent[vname] = false;
					end
				end
			end
		end
		return true;
	end
end)
