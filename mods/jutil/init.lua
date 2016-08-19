jutil = {}
jutil.cmd = dofile(minetest.get_modpath("jutil") .. "/cmd.lua");
jutil.direction = dofile(minetest.get_modpath("jutil") .. "/direction.lua");
jutil.color = {
	red     = 0xffff0000,
	green   = 0xff00ff00,
	blue    = 0xff0000ff,
	yellow  = 0xffff0000,
	magenta = 0xffff00ff,
	cyan    = 0xff00ffff,
	orange  = 0xffff8000,
	brown   = 0xff996633,
	white   = 0xffffffff,
	black   = 0xff000000,
	purple  = 0xffac00e6,
	pink    = 0xffff3399,
	grey    = 0xff666666,
}

function jutil.gen_uuid(bytes)
	local bytes = bytes or 16;
	local ret = '0x';
	for i = 1, bytes*2 do
		ret = ret .. string.format("%X", math.random(0, 15));
	end
	return ret;
end

--[[
Get the yaw of a player
--]]
function jutil.get_player_yaw(player)
	local value = player:get_look_yaw() - math.pi/2;
	return math.round(value, math.pi/2);
end

--[[
Generate a crafting recipe by substitution, e.g.
jutil.recipe_format({
	{0, 1, 0},
	{1, 2, 1},
	{3, 3, 3}
}, {"default:stone", "default:mese", "default:obsidian_shard"})
--]]
function jutil.recipe_format(t, lookup)
	for k,v in pairs(t) do
		if type(v) == "table" then
			jutil.recipe_format(v, lookup);
		else
			t[k] = lookup[v] or '';
		end
	end

	return t;
end

--[[
Safely serialize a string, ignoring any unrecognized types
--]]
function jutil.serialize_safe(obj, ignore)
	local ignore = ignore or {}
	local val = {}
	for k,v in pairs(obj) do
		if type(v) ~= "userdata" then
			local is_ignore = false;
			for _, ignore_val in pairs(ignore) do
				if ignore_val == k then
					is_ignore = true;
					break;
				end
			end
			if not is_ignore then
				val[k] = v
			end
		end
	end
	return minetest.serialize(val);
end

--[[
Deserializes a string in-place to an object
--]]
function jutil.deserialize_to(str, obj)
	if str == "" then return end;
	local data = minetest.deserialize(str);
	for k,v in pairs(data) do
		obj[k] = v
	end
end

--[[
Run a command 'command' for player 'player', optionally using priveledges for
the 'owner'
--]]
function jutil.run_command(player, command, owner)
	command = string.trim(command)
	command = command:gsub("@", player)
	if command:sub(1, 1) == '/' then
		command = command:sub(2);
	end

	local owner = owner or player;
	local cmd_name, cmd_value;
	local space_s, space_e = command:find("%s");
	if space_s and space_e then
		cmd_name = command:sub(1, space_s - 1);
		cmd_value = command:sub(space_e + 1) or "";
	else
		cmd_name = command;
		cmd_value = "";
	end

	local command_table = minetest.chatcommands[cmd_name];
	if not command_table then
		print("No such command of name " .. cmd_name .. "!");
		return
	end
	if not minetest.check_player_privs(owner, command_table.privs) then
		print("Owner, " .. owner .. ", does not have the necessary priveleges to run this command.");
		return
	end

	command_table.func(player, cmd_value);
end

--[[
Get the nearest entity to a point from a list of entities
--]]
function jutil.get_nearest_entity(list, pos, filter)
	local ret_ent, ret_pos;
	-- print("Near: " .. tostring(#list))
	for _,entity in pairs(list) do
		local can_check = not jutil.filter.match(filter, entity);

		if can_check then
			local new_pos = entity:getpos();
			if not ret_pos or vector.distance(pos, new_pos) <
					vector.distance(pos, ret_pos) then
				ret_ent = entity;
				ret_pos = new_pos;
			end
		end
	end
	return ret_ent, ret_pos;
end

--[[
converts a direction into a unit single axis-aligned unit direction
accepts directions and strings in the format 'x+' or 'z-'
--]]
function jutil.vec_unit(dir)
	if type(dir) == "string" then
		if dir == 'x-' then
			return {x = -1, y =  0, z =  0};
		elseif dir == 'x+' then
			return {x =  1, y =  0, z =  0};
		elseif dir == 'y-' then
			return {x =  0, y = -1, z =  0};
		elseif dir == 'y+' then
			return {x =  0, y =  1, z =  0};
		elseif dir == 'z-' then
			return {x =  0, y =  0, z = -1};
		elseif dir == 'z+' then
			return {x =  0, y =  0, z =  1};
		end
		return {x =  0, y =  0, z =  0};
	end
	-- local min, max = math.minmax(dir.x, dir.y, dir.z);

	local val = minetest.dir_to_wallmounted(dir);
	if val == 3 then
		return {x = -1, y =  0, z =  0};
	elseif val == 2 then
		return {x =  1, y =  0, z =  0};
	elseif val == 1 then
		return {x =  0, y = -1, z =  0};
	elseif val == 0 then
		return {x =  0, y =  1, z =  0};
	elseif val == 5 then
		return {x =  0, y =  0, z = -1};
	elseif val == 4 then
		return {x =  0, y =  0, z =  1};
	end

	return {x =  0, y =  0, z =  0};
end

--[[
Gets the axis of a block based on the angle it is being viewed from
--]]
function jutil.get_axis(from, to, b1, b2)
	local did, pos, axis = jutil.raycast.check_line_box(b1, b2, from, to);
	if not axis then return end
	return jutil.vec_unit(axis);
end

jutil.filter = dofile(minetest.get_modpath("jutil") .. "/filter.lua");
jutil.math = dofile(minetest.get_modpath("jutil") .. "/math.lua");
jutil.raycast = dofile(minetest.get_modpath("jutil") .. "/raycast.lua");
jutil.string = dofile(minetest.get_modpath("jutil") .. "/string.lua");
jutil.table = dofile(minetest.get_modpath("jutil") .. "/table.lua");
jutil.node = dofile(minetest.get_modpath("jutil") .. "/node.lua");
