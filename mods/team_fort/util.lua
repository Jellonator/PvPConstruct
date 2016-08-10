util = {};

function math.round(num, mult)
	local mult = mult or 1;
  return math.floor(num / mult + 0.5) * mult
end

function util.get_player_yaw(player)
	local value = player:get_look_yaw() - math.pi/2;
	return math.round(value, math.pi/2);
end

function util.recipe_format(t, lookup)
	for k,v in pairs(t) do
		if type(v) == "table" then
			util.recipe_format(v, lookup);
		else
			t[k] = lookup[v] or '';
		end
	end

	return t;
end

function util.mod(a, n)
	return a - math.floor(a/n) * n
end

function util.angle_diff(a, b)
	local ret = a - b;
	ret = util.mod(ret + math.pi, math.pi*2) - math.pi
	return ret;
end

function util.angle_to(from, to, speed)
	local diff = util.angle_diff(to, from);
	if math.abs(diff) < speed then return to end
	diff = diff * speed / math.abs(diff);
	from = from + diff;
	return util.mod(from, math.pi*2);
end

function util.check_node_property(property, value, x, y, z)
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

function util.check_node(name, x, y, z)
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

function util.serialize_safe(obj, ignore)
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

function util.deserialize_to(str, obj)
	if str == "" then return end;
	local data = minetest.deserialize(str);
	for k,v in pairs(data) do
		obj[k] = v
	end
end

dofile(minetest.get_modpath("team_fort") .. "/direction.lua");
