local PAYLOAD_CHECK_RATE = 0.5;
local PAYLOAD_RANGE = 4.0;
local PAYLOAD_SPEED_EXP = 0.2;
local PAYLOAD_SPEED_BASE = 0.2;
local YAW_CHANGE_SPEED = math.pi;
local PAYLOAD_GRAVITY = 6.0;
local PAYLOAD_MAXFALL = 12.0;

local payload = {
	collisionbox = {-0.45, 0.0, -0.45, 0.45, 1.0, 0.45},
	visual = "mesh",
	mesh = get_res("kart.b3d"),
	textures = {get_res("kart.png")},
	visual_size = {x=4,y=4},
	physical = true,
	check_time = 0,
	move_speed = 0,
	target_pos = false,
	target_yaw = 0,
	self_pos = false,
	falling = -1
};

function payload.on_activate(self, staticdata)
	if staticdata then
		util.deserialize_to(staticdata, self);
		print("S", self.self_pos);
	end
end

function payload.get_staticdata(self)
	return util.serialize_safe(self, {"self_pos", "check_time", "move_speed"});
end

local function filter_player(t)
	local i = 1;
	while i <= #t do
		local v = t[i];
		if not v:is_player() then
			table.remove(t, i)
		else
			i = i + 1;
		end
	end
end

function payload.on_step(self, dtime)
	-- minetest.chat_send_all(string.format("Rot: %f", math.deg(self.object:getyaw())))
	-- Using self.self_pos instead of actual object position
	-- This is because using the actual position can lead to strange behavior,
	-- including players standing on the payload to push it through the ground
	if not self.self_pos then self.self_pos = self.object:getpos() end

	-- check once every once in a while if there are teammates close enough
	-- to the payload to push it
	self.check_time = self.check_time + dtime;
	if self.check_time >= PAYLOAD_CHECK_RATE then
		self.check_time = self.check_time - PAYLOAD_CHECK_RATE
		local objects = minetest.get_objects_inside_radius(
				self.object:getpos(), PAYLOAD_RANGE);
		filter_player(objects);
		local blu_num = 0;
		for k,v in pairs(objects) do
			if Scoreboard.Teams.has_player("blue", v:get_player_name()) then
				blu_num = blu_num + 1;
			elseif Scoreboard.Teams.has_player("red", v:get_player_name()) then
				blu_num = 0;
				break;
			end
		end
		if blu_num > 0 then
			self.move_speed = blu_num * PAYLOAD_SPEED_EXP + PAYLOAD_SPEED_BASE
		else
			self.move_speed = 0
		end
	end

	if (self.move_speed > 0 or self.falling >= 0) and not self.target_pos then
		local dir = direction.from_yaw(self.object:getyaw());
		local dirx, dirz = direction.decompose(dir);
		self.target_yaw = self.object:getyaw();
		local current_pos = self.self_pos;
		local current_node = minetest.get_node(current_pos);
		local under_pos = {
			x = math.round(current_pos.x),
			y = math.round(current_pos.y) - 1.0,
			z = math.round(current_pos.z)
		}
		-- attempt to follow tracks
		do
			local base_x, base_y, base_z =
					math.round(current_pos.x),
					math.round(current_pos.y),
					math.round(current_pos.z);

			local potential_directions = {
				direction.to_pos(dir),
				direction.to_pos(direction.left(dir)),
				direction.to_pos(direction.right(dir)),
			};

			for k, v in ipairs(potential_directions) do
				local target_yaw = math.atan2(-v.x, v.z);

				-- Used to check for rails up 1 over two to the payload, e.g.
				--        ___
				-- ___=O_/
				local up_check = {
					x = v.x * 2 + base_x,
					y = v.y + 1 + base_y,
					z = v.z * 2 + base_z
				}

				-- Used to check for rails under the payload
				local down_check_a = {
					x = v.x + base_x,
					y = v.y - 1 + base_y,
					z = v.z + base_z
				}
				local down_check_b = {
					x = base_x,
					y = v.y - 1 + base_y,
					z = base_z
				}

				-- offset by payload's position
				v.x = v.x + base_x;
				v.y = v.y + base_y;
				v.z = v.z + base_z;

				local move_by_down = false;
				local can_move = util.check_node("default:rail", v);
				if not can_move and self.falling < 0 then
					can_move = util.check_node("default:rail", down_check_a) or
							util.check_node("default:rail", down_check_b);
					move_by_down = true;
				end
				if can_move then
					self.target_pos = v;
					self.target_yaw = target_yaw;
					local target_pitch = 0;
					if self.falling < 0 then
						if util.check_node("default:rail", up_check) then
							self.target_pos.y = self.target_pos.y + 1.0;
							target_pitch = math.pi/4;
						end
						if current_node.name == "air" and move_by_down and
								util.check_node("default:rail", under_pos) then
							self.target_pos.y = self.target_pos.y - 1.0
							target_pitch = -math.pi/4;
						end
					end
					break
				end
			end
		end

		if not self.target_pos and util.check_node_property(
				"walkable", false, under_pos) then
			-- fall in air
			self.target_pos = under_pos;
			self.falling = math.max(0, self.falling);
		else
			self.falling = -1;
		end

		if not self.target_pos then
			-- move when derailed
			local next_pos = {
				x = math.round(current_pos.x) + dirx,
				y = math.round(current_pos.y),
				z = math.round(current_pos.z) + dirz
			};
			if util.check_node_property("walkable", false, next_pos) then
				self.target_pos = next_pos;
			end
		end

		-- offset so that the payload isn't floating above the ground
		if self.target_pos then
			self.target_pos.y = self.target_pos.y - 0.5
		end
	end

	if (self.move_speed > 0 or self.falling >= 0) and self.target_pos then
		local mspeed = self.move_speed * dtime;
		if self.falling >= 0 then
			self.falling = math.min(self.falling + dtime * PAYLOAD_GRAVITY,
					PAYLOAD_MAXFALL);
			mspeed = dtime * self.falling;
		end
		local diff = {
			x = self.target_pos.x - self.self_pos.x,
			y = self.target_pos.y - self.self_pos.y,
			z = self.target_pos.z - self.self_pos.z
		}
		if (diff.x^2 + diff.y^2 + diff.z^2) < mspeed^2 then
			-- snap to position, get a new target
			self.object:setpos(self.target_pos);
			self.object:setyaw(self.target_yaw);
			self.target_pos = false;
			self.self_pos = self.target_pos;
		else
			-- tween to position
			local len = math.sqrt(diff.x^2 + diff.y^2 + diff.z^2);
			diff.x = diff.x / len;
			diff.y = diff.y / len;
			diff.z = diff.z / len;
			self.self_pos.x = self.self_pos.x + diff.x * mspeed;
			self.self_pos.y = self.self_pos.y + diff.y * mspeed;
			self.self_pos.z = self.self_pos.z + diff.z * mspeed;
			self.object:setpos(self.self_pos);

			self.object:setyaw(util.angle_to(self.object:getyaw(),
					self.target_yaw, dtime * YAW_CHANGE_SPEED))
		end
	end
end

minetest.register_entity(get_name("payload"), payload);

minetest.register_craftitem(get_name("payload"), {
	description = "Payload cart",
	inventory_image = get_res("kart_item.png"),
	wield_image = get_res("kart_item.png"),

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		if minetest.get_node(pointed_thing.under).name ~= "default:rail" then
			return
		end

		local to_pos = pointed_thing.under;
		to_pos.y = to_pos.y - 0.5
		local object = minetest.add_entity(to_pos, get_name("payload"));
		object:setyaw(util.get_player_yaw(placer));
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})
