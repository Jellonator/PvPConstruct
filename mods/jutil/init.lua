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

function math.round(num, mult)
	local mult = mult or 1;
	return math.floor(num / mult + 0.5) * mult
end

local sanatize_badchars = {";", ",", "[", "]"}
function string.sanatize(str)
	str = str:gsub("\\", "\\\\");
	for k,v in pairs(sanatize_badchars) do
		str = str:gsub(v, "\\%1");
	end
	return str;
end

function jutil.get_player_yaw(player)
	local value = player:get_look_yaw() - math.pi/2;
	return math.round(value, math.pi/2);
end

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

function jutil.mod(a, n)
	return a - math.floor(a/n) * n
end

function jutil.angle_diff(a, b)
	local ret = a - b;
	ret = jutil.mod(ret + math.pi, math.pi*2) - math.pi
	return ret;
end

function jutil.angle_to(from, to, speed)
	local diff = jutil.angle_diff(to, from);
	if math.abs(diff) < speed then return to end
	diff = diff * speed / math.abs(diff);
	from = from + diff;
	return jutil.mod(from, math.pi*2);
end

function jutil.check_node_property(property, value, x, y, z)
	if y and z then
		x = {
			x = x,
			y = y,
			z = z
		};
	end
	local node = minetest.get_node(x);
	local def = minetest.registered_nodes[node.name];
	return def[property] == value, node;
end

function jutil.check_node(name, x, y, z)
	if y and z then
		x = {
			x = x,
			y = y,
			z = z
		};
	end
	local node = minetest.get_node(x);
	if type(name) == "table" then
		for k,v in pairs(name) do
			if v == node.name then
				return true, node;
			end
		end
		return false, node;
	end
	return node.name == name, node;
end

function jutil.serialize_safe(obj, ignore)
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

function jutil.deserialize_to(str, obj)
	if str == "" then return end;
	local data = minetest.deserialize(str);
	for k,v in pairs(data) do
		obj[k] = v
	end
end

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

local function _block_iter(state, prev_var)
	if state.first then
		state.first = false;
		return state.start;
	end
	local x_diff = state.stop.x - state.var.x;
	local y_diff = state.stop.y - state.var.y;
	local z_diff = state.stop.z - state.var.z;

	if x_diff == 0 and y_diff == 0 and z_diff == 0 then
		return nil
	end

	local len = math.sqrt(x_diff^2 + y_diff^2 + z_diff^2);
	if len < state.step then
		state.var.x = state.stop.x;
		state.var.y = state.stop.y;
		state.var.z = state.stop.z;
		local ret = state.var;
		if ret.x == prev_var.x and ret.y == prev_var.y and ret.z == prev_var.z then
			return nil;
		end
		return ret;
	end
	local nx = x_diff / len;
	local ny = y_diff / len;
	local nz = z_diff / len;
	state.var.x = state.var.x + nx * state.step;
	state.var.y = state.var.y + ny * state.step;
	state.var.z = state.var.z + nz * state.step;
	local ret = {
		x = math.round(state.var.x),
		y = math.round(state.var.y),
		z = math.round(state.var.z),
	}
	if ret.x == prev_var.x and ret.y == prev_var.y and ret.z == prev_var.z then
		return _block_iter(state, prev_var);
	end
	return ret;
end

function jutil.block_iter(pos1, pos2, step, skip_first)
	if skip_first == nil then skip_first = false end
	local step = step or 1;
	local pos1 = {
		x = math.round(pos1.x),
		y = math.round(pos1.y),
		z = math.round(pos1.z),
	}
	local pos2 = {
		x = math.round(pos2.x),
		y = math.round(pos2.y),
		z = math.round(pos2.z),
	}
	return _block_iter, {start = pos1, stop = pos2, step = step,
			first = not skip_first, var = {x=pos1.x,y=pos1.y,z=pos1.z}},
			{x=pos1.x,y=pos1.y,z=pos1.z};
end
