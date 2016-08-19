local Raycast = {};

-- actual iterator function
local function _block_iter(state, prev_var)
	if state.first then
		state.first = false;
		return state.start, state.start;
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
		return ret, ret;
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
	return ret, state.var;
end

--[[
Iterates through all axis-aligned positions along a path
--]]
function Raycast.block_iter(pos1, pos2, step, skip_first)
	if skip_first == nil then skip_first = false end
	local step = step or 1;
	return _block_iter, {start = pos1, stop = pos2, step = step,
			first = not skip_first, var = {x=pos1.x,y=pos1.y,z=pos1.z}},
			{x=pos1.x,y=pos1.y,z=pos1.z};
end

--[[
Returns the intersection of a line and a face, provided they touch
--]]
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

--[[
Returns if a point is inside a box
--]]
function Raycast.check_point_box(hit, B1, B2, Axis)
	if Axis == 1 then
		return hit.z > B1.z and hit.z < B2.z and hit.y > B1.y and hit.y < B2.y
	elseif Axis == 2 then
		return hit.z > B1.z and hit.z < B2.z and hit.x > B1.x and hit.x < B2.x
	elseif Axis == 3 then
		return hit.x > B1.x and hit.x < B2.x and hit.y > B1.y and hit.y < B2.y
	else
		return hit.x > B1.x and hit.x < B2.x and hit.y > B1.y and hit.y < B2.y
				and hit.z > B1.z and hit.z < B2.z
	end
	-- return false
end

--[[
Checks if a line intersects a box
returns if they intersect, where they intersect, axis
--]]
function Raycast.check_line_box(B1, B2, L1, L2)
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
		if did_hit_a and Raycast.check_point_box(ret_a, B1, B2, axis) then
			return true, ret_a, name .. '-';
		end

		local did_hit_b, ret_b = get_intersection(
				L1[name]-B2[name], L2[name]-B2[name], L1, L2)
		if did_hit_b and Raycast.check_point_box(ret_b, B1, B2, axis) then
			return true, ret_b, name .. '+';
		end
	end

	return false;
end

--[[
Checks for collision between two boxes
--]]
function Raycast.check_box_box(A1, A2, B1, B2)
	return A1.x <= B2.x and A2.x >= B1.x and
	       A1.y <= B2.y and A2.y >= B1.y and
	       A1.z <= B2.z and A2.z >= B1.z;
end

--[[
Returns an entity's hitbox
--]]
function Raycast.get_entity_box(entity)
	local b1, b2;
	if entity:is_player() then
		-- assuming player is 0.8x1.75x0.8
		b1 = {x = -0.4, y = 0.0, z = -0.4}
		b2 = {x =  0.4, y = 1.8, z =  0.4}
	else
		local lua_entity = entity:get_luaentity();
		if lua_entity then
			local ent_name = lua_entity.name;
			local ent_name = lua_entity.name;
			local ent_def = minetest.registered_entities[ent_name];
			local ent_col = ent_def.collisionbox or {
				-0.5, -0.5, -0.5, 0.5, 0.5, 0.5
			};
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

--[[
Raytrace that find the first entity hit. Does not penetrate walls.
returns entity, position of entity, position of block behind entity, axis
--]]
function Raycast.entities(a, b, filter)
	--make sure that view isn't blocked
	--maybe replace line_of_sight with something a little better...?
	local is_blocked, _, new_pos, backup_axis = Raycast.blocks(a, b);
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
	local ret_axis;
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

		local b1, b2 = Raycast.get_entity_box(entity);
		if b1 and b2 and can_check then
			local did_collide, pos, axis = Raycast.check_line_box(b1, b2, a, b)
			if did_collide then
				if not ret_pos or vector.distance(a, pos) <
						vector.distance(a, ret_pos) then
					ret_ent = entity;
					ret_pos = pos;
					ret_axis = axis;
				end
			end
		end
	end
	if not ret_ent then
		ret_pos = b;
		axis = backup_axis;
	end
	return ret_ent, ret_pos, new_pos, axis;
end

--[[
Returns a list of all collision boxes of a node
--]]
function Raycast.get_node_boxes(def)
	if not def then return {} end
	if not def.walkable then return {} end
	local node_col = def.collision_box;

	if not node_col or node_col.type == "regular" then
		return {{-0.5,-0.5,-0.5, 0.5,0.5,0.5}}

	elseif node_col.type == "fixed" then
		local fixed = node_col.fixed;
		if type(fixed[1]) == "table" then
			return fixed;
		else
			return {fixed}
		end

	else
		--TODO? wallmounted and connected, probably not important
		return {{-0.5,-0.5,-0.5, 0.5,0.5,0.5}}
	end
end

--[[
A raytrace that checks against blocks
returns if it collided, where it ends, block position, axis
--]]
function Raycast.blocks(a, b, step)
	local step = step or 0.25;
	for pos, apos in Raycast.block_iter(a, b, step or 0.4) do
		local node = minetest.get_node(pos);
		if node.name == "ignore" then
			return false, b, pos
		end
		local node_def = minetest.registered_nodes[node.name];
		local node_cols = Raycast.get_node_boxes(node_def);
		for k, col in pairs(node_cols) do
			local min_x, max_x = math.minmax(col[1], col[4]);
			local min_y, max_y = math.minmax(col[2], col[5]);
			local min_z, max_z = math.minmax(col[3], col[6]);
			local b1 = vector.add(pos, vector.new(min_x, min_y, min_z));
			local b2 = vector.add(pos, vector.new(max_x, max_y, max_z));
			local did, ret, axis = Raycast.check_line_box(b1, b2, a, apos);
			if did then return true, ret, pos, axis end
		end
	end

	return false, b;
end

return Raycast;
