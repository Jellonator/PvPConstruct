--[[
Destruction tool
removes anything that is moused over, including blocks and entities.
Players are simply killed.
--]]
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

local function edit_entity(player_name, object)
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

minetest.register_tool(editor_name, {
	description = "Modifies Objects",
	inventory_image = "bubble.png",
	on_use = function(itemstack, user, pointed_thing)
		if not user:is_player() then return end;
		local player_name = user:get_player_name();
		if pointed_thing.type == "object" then
			local object = pointed_thing.ref;
			edit_entity(player_name, object);
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

		if not fields.qexit or not lua_ent then
			return true
		end

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

		return true;
	end
end)

--[[
Positioning tool
allows for the editing of an object's position, speed, rotation, and health
--]]
local positioning_refs = {};
local positioning_name = "jtools:positioning_tool";
local positioning_inc = 1;

local function position_entity(player_name, object)
	-- if object:is_player() then return end
	local lua_ent = object:get_luaentity();
	if not lua_ent then return end

	local epos = object:getpos();
	local eveloc = object:getvelocity();
	local eaccel = object:getacceleration();
	local yaw = math.deg(object:getyaw() or 0);
	local health = object:get_hp();

	local formspec =
		"label[0.7,0;Position:]" ..
		"field[1,1;2,1;posx;x;" .. math.round(epos.x, 1e-5) .. "]" ..
		"field[3,1;2,1;posy;y;" .. math.round(epos.y, 1e-5) .. "]" ..
		"field[5,1;2,1;posz;z;" .. math.round(epos.z, 1e-5) .. "]";

	if not object:is_player() then
		formspec = formspec .. "label[0.7,1.5;Velocity:]" ..
		"field[1,2.5;2,1;velx;x;" .. math.round(eveloc.x, 1e-5) .. "]" ..
		"field[3,2.5;2,1;vely;y;" .. math.round(eveloc.y, 1e-5) .. "]" ..
		"field[5,2.5;2,1;velz;z;" .. math.round(eveloc.z, 1e-5) .. "]" ..

		"label[0.7,3;Acceleration:]" ..
		"field[1,4;2,1;accx;x;" .. math.round(eaccel.x, 1e-5) .. "]" ..
		"field[3,4;2,1;accy;y;" .. math.round(eaccel.y, 1e-5) .. "]" ..
		"field[5,4;2,1;accz;z;" .. math.round(eaccel.z, 1e-5) .. "]" ..

		"field[1,5.5;3,1;yawa;Rotation:;" .. math.round(yaw, 1e-5) .. "]";
	end
	formspec = formspec ..
		"field[4,5.5;3,1;htpa;Health:;" .. math.round(health, 1e-5) .. "]";

	local width = 8;
	local height = 8;

	formspec = string.format("size[%d,%d]", width, height) ..
			formspec .. string.format("button_exit[%d,%d;%d,1;qexit;Apply]",
			width / 4, height - 1, width / 2);

	positioning_refs[positioning_inc] = object;
	minetest.show_formspec(player_name,
			positioning_name .. tostring(positioning_inc), formspec);
	positioning_inc = positioning_inc + 1;
end

minetest.register_tool(positioning_name, {
	description = "Positions Objects",
	inventory_image = "gui_furnace_arrow_fg.png",
	on_use = function(itemstack, user, pointed_thing)
		if not user:is_player() then return end;
		local player_name = user:get_player_name();
		if pointed_thing.type == "object" then
			local object = pointed_thing.ref;
			position_entity(player_name, object);
		end
	end,
	range = 20
});

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname:sub(1, positioning_name:len()) == positioning_name then
		local formdata = tonumber(formname:sub(positioning_name:len()+1));
		print("Got form: '" .. formdata .. "'")
		local ref = positioning_refs[formdata];
		if ref == nil then return end
		positioning_refs[formdata] = nil;
		local lua_ent = ref:get_luaentity();

		if not fields.qexit or not lua_ent then
			return true
		end

		local pos = ref:getpos();
		local veloc = ref:getvelocity();
		local accel = ref:getacceleration();
		local yaw = ref:getyaw() or 0;
		local health = ref:get_hp();

		for k,v in pairs(fields) do
			local k_name = k:sub(1,3);
			local k_key = k:sub(4);
			if k_name == 'pos' then
				pos[k_key] = tonumber(v) or pos[k_key];
			elseif k_name == 'vel' then
				veloc[k_key] = tonumber(v) or veloc[k_key];
			elseif k_name == 'acc' then
				accel[k_key] = tonumber(v) or accel[k_key];
			elseif k_name == 'yaw' then
				local new_yaw = tonumber(v);
				print("New yaw: " .. tostring(new_yaw or 'nil'))
				if new_yaw then
					yaw = math.rad(new_yaw);
				end
			elseif k_name == 'htp' then
				health = tonumber(v) or health;
			end
		end

		ref:setpos(pos);
		ref:set_hp(health);
		if not ref:is_player() then
			ref:setvelocity(veloc);
			ref:setacceleration(accel);
			ref:setyaw(yaw);
		end

		return true;
	end
end)
