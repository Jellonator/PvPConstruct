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

function math.minmax(...)
	return math.min(...), math.max(...);
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

local function get_intersection(fDst1, fDst2, P1, P2)
	if (fDst1 * fDst2) >= 0.0 then
		return false
	end
	if fDst1 == fDst2 then
		return false
	end
	local hit = vector.add(P1, vector.multiply(
			vector.subtract(P2, P1), ( -fDst1/(fDst2-fDst1) )));
	return true, hit;
end

local function in_box(hit, B1, B2, Axis)
	if Axis == 1 then
		return hit.z > B1.z and hit.z < B2.z and hit.y > B1.y and hit.y < B2.y
	elseif Axis == 2 then
		return hit.z > B1.z and hit.z < B2.z and hit.x > B1.x and hit.x < B2.x
	elseif Axis == 3 then
		return hit.x > B1.x and hit.x < B2.x and hit.y > B1.y and hit.y < B2.y
	end
	return false
end

-- returns true if line (L1, L2) intersects with the box (B1, B2)
function jutil.check_line_box(B1, B2, L1, L2)
	if (L2.x < B1.x and L1.x < B1.x) then return false end
	if (L2.x > B2.x and L1.x > B2.x) then return false end
	if (L2.y < B1.y and L1.y < B1.y) then return false end
	if (L2.y > B2.y and L1.y > B2.y) then return false end
	if (L2.z < B1.z and L1.z < B1.z) then return false end
	if (L2.z > B2.z and L1.z > B2.z) then return false end

	-- line is inside of box
	if (L1.x > B1.x and L1.x < B2.x and
			L1.y > B1.y and L1.y < B2.y and
			L1.z > B1.z and L1.z < B2.z) then
		return true, L1
	end

	-- check each face
	for axis, name in pairs({'x', 'y', 'z'}) do
		local did_hit_a, ret_a = get_intersection(
				L1[name]-B1[name], L2[name]-B1[name], L1, L2)
		if did_hit_a and in_box(ret_a, B1, B2, axis) then
			return true, ret_a;
		end

		local did_hit_b, ret_b = get_intersection(
				L1[name]-B2[name], L2[name]-B2[name], L1, L2)
		if did_hit_b and in_box(ret_b, B1, B2, axis) then
			return true, ret_b;
		end
	end

	return false;
end

function jutil.check_box_box(A1, A2, B1, B2)
	return A1.x <= B2.x and A2.x >= B1.x and
	       A1.y <= B2.y and A2.y >= B1.y and
	       A1.z <= B2.z and A2.z >= B1.z;
end

function jutil.get_entity_box(entity)
	local b1, b2;
	if entity:is_player() then
		-- assuming player is 0.8x1.8x0.8
		b1 = {x = -0.4, y = 0.0, z = -0.4}
		b2 = {x =  0.4, y = 1.8, z =  0.4}
	else
		local lua_entity = entity:get_luaentity();
		if lua_entity then
			local ent_name = lua_entity.name;
			-- print(ent_name);
			local ent_name = lua_entity.name;
			local ent_def = minetest.registered_entities[ent_name];
			local ent_col = ent_def.collisionbox;
			b1 = {x = ent_col[1], y = ent_col[2], z = ent_col[3]}
			b2 = {x = ent_col[4], y = ent_col[5], z = ent_col[6]}
		end
	end

	b1, b2 = vector.add(b1, entity:getpos()), vector.add(b2, entity:getpos())
	b1.x, b2.x = math.minmax(b1.x, b2.x);
	b1.y, b2.y = math.minmax(b1.y, b2.y);
	b1.z, b2.z = math.minmax(b1.z, b2.z);
	return b1, b2
end

function jutil.raytrace_entity(a, b, filter)
	--make sure that view isn't blocked
	--maybe replace line_of_sight with something a little better...?
	local is_blocked, new_pos = minetest.line_of_sight(a, b);
	if new_pos and not is_blocked then
		-- reposition newpos along line
		local diff = vector.normalize(vector.subtract(b, a));
		local len = vector.distance(new_pos, a);
		b = vector.add(a, vector.multiply(diff, len))
	end

	local len = vector.distance(a, b);
	local mid = vector.divide(vector.add(a, b), 2);
	local all_objects = minetest.get_objects_inside_radius(mid, len/2);
	local ret_ent, ret_pos;
	for _,entity in pairs(all_objects) do
		local can_check = true;
		if filter then
			if type(filter) == "table" then
				for k,v in pairs(filter) do
					if v == entity then
						can_check = false;
						break;
					end
				end
			else
				can_check = filter(entity);
			end
		end

		local b1, b2 = jutil.get_entity_box(entity);
		if b1 and b2 and can_check then
			local did_collide, pos = jutil.check_line_box(b1, b2, a, b)
			if did_collide then
				if not ret_pos or vector.distance(a, pos) <
						vector.distance(a, ret_pos) then
					ret_ent = entity;
					ret_pos = pos;
				end
			end
		end
	end
	return ret_ent, ret_pos;
end

function jutil.get_nearest_entity(list, pos, filter)
	local ret_ent, ret_pos;
	-- print("Near: " .. tostring(#list))
	for _,entity in pairs(list) do
		local can_check = true;
		if filter then
			if type(filter) == "table" then
				for k,v in pairs(filter) do
					if v == entity then
						can_check = false;
						break;
					end
				end
			else
				can_check = filter(entity);
			end
		end

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
