local PAYLOAD_CHECK_RATE = 0.5;
local PAYLOAD_RANGE = 4.0;
local PAYLOAD_SPEED_EXP = 0.2;
local PAYLOAD_SPEED_BASE = 0.2;
local YAW_CHANGE_SPEED = math.pi;
local PAYLOAD_GRAVITY = 6.0;
local PAYLOAD_MAXFALL = 12.0;

local PAYLOAD_HUD_TIMER = {
	hud_elem_type = "text",
	text = "",
	position = {x=0.5,y=0},
	alignment = {x=0,y=1},
	offset = {x=0,y=1},
};
local PAYLOAD_HUD_TIMERTAB = {
	hud_elem_type = "image",
	text = "objectively_timetab.png",
	scale = {x=1,y=1},
	position = {x=0.5,y=0},
	alignment = {x=0,y=1},
	offset = {x, y=0},
};

local obj_payload = {
	winner = NO_TEAM,
	objective_id = Objectively.get_id(),
	timer = Objectively.get_global_timer(),
	reset_time = false,
	hud_elements = {},
	is_overtime = false,
}

local payload = {
	collisionbox = {-0.45, 0.0, -0.45, 0.45, 1.0, 0.45},
	visual = "mesh",
	mesh = "teamf_kart.b3d",
	textures = {"teamf_kart.png"},
	visual_size = {x=4,y=4},

	physical = true,
	check_time = 0,
	move_speed = 0,
	target_pos = false,
	target_yaw = 0,
	self_pos = false,
	falling = -1,
	start_pos = nil,
	start_yaw = nil,
	initialize = false
};

local max_payload_speed = 0;
function payload.on_activate(self, staticdata)
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
	self.object:set_armor_groups({immortal=1})
end

function payload.get_staticdata(self)
	return jutil.serialize_safe(self, {"self_pos", "check_time", "move_speed"});
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

function payload.check_players(self, dtime)
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
			if Teammake.has_player("blue", v:get_player_name()) then
				blu_num = blu_num + 1;
			elseif Teammake.has_player("red", v:get_player_name()) then
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
end

function payload.reset(self, is_win)
	self.object:setpos(self.start_pos);
	self.object:setyaw(self.start_yaw);
	self.self_pos = self.object:getpos();
	self.objective_id = obj_payload.objective_id;
end

function payload.update_objective(self)
	if not self.objective_id or self.objective_id == '' then
		self.objective_id = obj_payload.objective_id;
	elseif self.objective_id  ~= obj_payload.objective_id then
		payload.reset(self);
		return true;
	end
	return false;
end

-- stupid monolithic 200 line function alert
function payload.on_step(self, dtime)
	max_payload_speed = math.max(max_payload_speed, self.move_speed)
	if not self.initialize then
		self.initialize = true;
		self.start_pos = self.object:getpos()
		self.start_yaw = self.object:getyaw();
	end
	-- Using self.self_pos instead of actual object position
	-- This is because using the actual position can lead to strange behavior,
	-- including players standing on the payload to push it through the ground
	if not self.self_pos then self.self_pos = self.object:getpos() end
	if payload.update_objective(self) then return end;

	payload.check_players(self, dtime);

	-- check for new positions
	if (self.move_speed > 0 or self.falling >= 0) and not self.target_pos then
		-- check for targets in front and below
		local current_pos = self.self_pos;
		local dir = jutil.direction.from_yaw(self.object:getyaw());
		local dirx, dirz = jutil.direction.decompose(dir);

		if jutil.node.check_name("team_fort:cart_target", current_pos.x,
				current_pos.y - 0.5, current_pos.z) or jutil.node.check_name(
				"team_fort:cart_target", current_pos.x + dirx, current_pos.y,
				current_pos.z + dirz) then
			-- payload.reset(self, true);
			obj_payload.winner = "blue";
			return;
		end
		self.target_yaw = self.object:getyaw();
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
				jutil.direction.to_pos(dir),
				jutil.direction.to_pos(jutil.direction.left(dir)),
				jutil.direction.to_pos(jutil.direction.right(dir)),
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
				local can_move = jutil.node.check_name("default:rail", v);
				if not can_move and self.falling < 0 then
					can_move = jutil.node.check_name("default:rail", down_check_a) or
							jutil.node.check_name("default:rail", down_check_b);
					move_by_down = true;
				end
				if can_move then
					self.target_pos = v;
					self.target_yaw = target_yaw;
					local target_pitch = 0;
					if self.falling < 0 then
						if jutil.node.check_name("default:rail", up_check) then
							self.target_pos.y = self.target_pos.y + 1.0;
							target_pitch = math.pi/4;
						end
						if current_node.name == "air" and move_by_down and
								jutil.node.check_name("default:rail", under_pos) then
							self.target_pos.y = self.target_pos.y - 1.0
							target_pitch = -math.pi/4;
						end
					end
					break
				end
			end
		end

		if not self.target_pos and jutil.node.check_property(
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
			if jutil.node.check_property("walkable", false, next_pos) then
				self.target_pos = next_pos;
			end
		end

		-- offset so that the payload isn't floating above the ground
		if self.target_pos then
			self.target_pos.y = self.target_pos.y - 0.5
		end
	end

	-- Actual movement
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

			self.object:setyaw(jutil.math.angle_to(self.object:getyaw(),
					self.target_yaw, dtime * YAW_CHANGE_SPEED))
		end
	end
end

minetest.register_entity("team_fort:payload", payload);

minetest.register_craftitem("team_fort:payload", {
	description = "Payload cart",
	inventory_image = "teamf_kart_item.png",
	wield_image = "teamf_kart_item.png",

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		if minetest.get_node(pointed_thing.under).name ~= "default:rail" then
			return
		end

		local to_pos = pointed_thing.under;
		to_pos.y = to_pos.y - 0.5
		local object = minetest.add_entity(to_pos, "team_fort:payload");
		object:setyaw(jutil.get_player_yaw(placer));
		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})

-- Objective
function obj_payload.on_joinplayer(self, player)
	local hud = {
		timertab = player:hud_add(PAYLOAD_HUD_TIMERTAB),
		timer = player:hud_add(PAYLOAD_HUD_TIMER),
	}
	self.hud_elements[player:get_player_name()] = hud;
end

function obj_payload.on_leaveplayer(self, player)
	local hud = self.hud_elements[player:get_player_name()];
	for _, v in pairs(hud) do
		player:hud_remove(v);
	end
	self.hud_elements[player:get_player_name()] = nil;
end

function obj_payload.on_globalstep(self, dtime)
	if not self.timer then
		-- self.timer = Objectively.get_global_timer();
	end
	-- announce winner if payload is winner
	if self.winner ~= NO_TEAM and self.winner ~= "neutral" then
		minetest.chat_send_all(self.winner .. " team wins!");
		Objectively.set_objective("_wait", 30, "team_fort:payload");
	end

	-- manage timer
	self.timer = self.timer - dtime;
	if self.reset_time then
		self.reset_time = false;
		self.timer = Objectively.get_global_timer();
	end

	-- red whens when timer hits 0
	if self.timer <= 0 and max_payload_speed <= 0 then
		-- Assumedly red team is the winner when time runs out.
		self.winner = "red";
	elseif self.timer <= 0 then
		self.is_overtime = true;
	end

	-- update text
	local ptext = PAYLOAD_HUD_TIMER.text;
	if not self.is_overtime then
		PAYLOAD_HUD_TIMER.text = jutil.string.fmt_seconds(self.timer, self.timer <= 9.9 and 1 or 0)
	else
		PAYLOAD_HUD_TIMER.text = "Overtime";
	end

	-- update hud
	if ptext ~= PAYLOAD_HUD_TIMER.text then
		for name, ids in pairs(self.hud_elements) do
			local player = minetest.get_player_by_name(name);
			if player then
				player:hud_change(ids.timer, 'text', PAYLOAD_HUD_TIMER.text);
			else
				self.hud_elements[name] = nil;
			end
		end
	end

	max_payload_speed = 0;
end

function obj_payload.on_enable(self)
	self.on_reset(self);
end

function obj_payload.on_disable(self)
	-- nothing
end

function obj_payload.on_reset(self)
	self.winner = NO_TEAM;
	self.objective_id = Objectively.get_id();
	self.timer = Objectively.get_global_timer();
	self.is_overtime = false;
	Teammake.respawn();
end

function obj_payload.on_loaddata(self, data)
	jutil.deserialize_to(data, self);
end

function obj_payload.get_staticdata(self)
	return jutil.serialize_safe(self);
end

Objectively.register_objective('team_fort:payload', obj_payload);
