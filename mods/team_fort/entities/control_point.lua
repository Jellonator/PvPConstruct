local CONTROL_POINT_CHECK_RATE = 0.5;
local CONTROL_POINT_RANGE = 3.0;
local CONTROL_POINT_DECAY = 0.5;
local CONTROL_POINT_CAPTURE_BASE = 0.6;
local CONTROL_POINT_CAPTURE_MULT = 0.4;
local NO_TEAM = "$NONE";

local CONTROL_POINT_TIMER_MAX = 5 * 60;
local POINT_HUD_TIMER = {
	hud_elem_type = "text",
	text = "",
	position = {x=0.5,y=0},
	alignment = {x=0,y=1},
	offset = {x=0,y=1},
};
local function POINT_HUD_POINT(n, pointid, color)
	color = jutil.get_color_num(color);
	local color_num = jutil.get_color_num(color);
	color = color % 0x01000000
	local color_num = color;
	color = color + 0xff000000;
	color = string.format("%X", color);
	color = "#" .. color:sub(3);
	return {
		hud_elem_type = "statbar",
		text = "teamf_cp_meter.png^[colorize:" .. color .. ":150",
		point_id = pointid,
		number = 20,
		direction = 0,
		position = {x=1,y=0},
		alignment = {x=-1,y=1},
		offset = {x=-162, y= n*20+2},
	}, {
		hud_elem_type = "text",
		text = "Point " .. pointid,
		number = color_num,
		position = {x=1,y=0},
		alignment = {x=-1,y=1},
		offset = {x=-164, y= n*20+2},
	}
end

local point_obj = {
	lock_data = {},
	point_data = {},
	new_points = false,
	winner = NO_TEAM,
	objective_id = Objectively.get_id(),
	timer = CONTROL_POINT_TIMER_MAX,
	reset_time = false,
	hud_elements = {},
	is_overtime = false,
}

local control_point_textures = {
	neutral = "teamf_cp_neutral.png",
	red     = "teamf_cp_red.png",
	blue    = "teamf_cp_blue.png"
}

local control_point = {
	collisionbox = {-2.5, 0.0, -2.5, 2.5, 0.25, 2.5},
	visual = "mesh",
	mesh = "teamf_control_point.b3d",
	textures = {"teamf_cp_neutral.png"},
	visual_size = {x=10,y=10},

	-- objective id
	objective_id = '',

	-- owner data
	color = "neutral",
	pcolor = NO_TEAM,
	original_color = "neutral",

	-- timer data
	timer = 0,
	timer_target = 10,
	check_time = 0,

	-- capture data
	capturer = NO_TEAM,
	holder = NO_TEAM,
	holder_count = 0,

	-- lock data
	lock = NO_TEAM,
	is_final = false,
	-- id = '',

	jtool_variables = {
		color = true,
		original_color = true,
		timer_target = true,
		lock = true,
		id = true,
		is_final = true,
	}
};

local max_point_time = 0;
function control_point.on_activate(self, staticdata)
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
	-- place some variables into editor
	self.timer_target = self.timer_target;
	self.color = self.color;
	self.original_color = self.original_color;
	self.id = self.id or jutil.string.random(16);

	self.object:set_armor_groups({immortal=1})
end

function control_point.get_staticdata(self)
	return jutil.serialize_safe(self, {"pcolor", "check_time", "holder",
			"holder_count", "timer", "jtool_variables"})
end

function control_point.reset(self)
	self.color = self.original_color;
	self.capturer = NO_TEAM;
	self.holder = NO_TEAM;
	self.timer = 0;
	self.objective_id = point_obj.objective_id;
end

function control_point.on_step(self, dtime)
	max_point_time = math.max(max_point_time, self.timer);
	if not self.objective_id or self.objective_id == '' then
		self.objective_id = point_obj.objective_id;
	elseif self.objective_id  ~= point_obj.objective_id then
		control_point.reset(self);
		return;
	end
	if not point_obj.point_data[self.id] then
		point_obj.point_data[self.id] = {}
		point_obj.new_points = true;
	end
	point_obj.point_data[self.id].timer = self.timer;
	point_obj.point_data[self.id].timer_target = self.timer_target;
	point_obj.point_data[self.id].color = self.color;

	-- change texture depending on color
	if self.color ~= self.pcolor then
		self.pcolor = self.color;
		local tex = control_point_textures[self.color]
		self.object:set_properties({textures = {tex}})
		point_obj.lock_data[self.id] = self.color;
		point_obj.new_points = true;
		if self.is_final and self.color ~= self.original_color then
			point_obj.winner = self.color;
		end
	end

	-- get data for who is currently standing on the point
	self.check_time = self.check_time + dtime;
	if self.check_time >= CONTROL_POINT_CHECK_RATE then
		self.check_time = self.check_time - CONTROL_POINT_CHECK_RATE
		local objects = minetest.get_objects_inside_radius(
				self.object:getpos(), CONTROL_POINT_RANGE);
		local team_majority = NO_TEAM;
		local team_count = 0;
		for k,v in pairs(objects) do
			if v:is_player() then
				local player_team = Teammake.player_get_team(
						v:get_player_name());
				if team_majority == NO_TEAM and player_team then
					team_majority = player_team;
					team_count = 1;
				elseif team_majority == player_team and player_team then
					team_count = team_count + 1;
				elseif player_team then
					team_majority = NO_TEAM;
					team_count = 0;
					break;
				end
			end
		end

		-- control point is locked and the team trying to capture this point
		-- does not own the locking point, then don't allow capture of this
		-- point
		if self.lock ~= NO_TEAM then
			local lock_team = point_obj.lock_data[self.lock];
			if lock_team ~= team_majority then
				team_majority = nil;
				team_count = 0;
			end
		elseif self.holder ~= team_majority then
			if not team_majority or team_majority == NO_TEAM and self.timer > 0 then
				minetest.chat_send_all(string.format(
					"Control point %s is no longer being contested.", self.id));
			elseif self.color ~= team_majority and team_majority and
					team_majority ~= NO_TEAM then
				minetest.chat_send_all(string.format(
					"Control point %s is being contested by team %s!",
					self.id, team_majority));
			end
		end

		self.holder = team_majority;
		self.holder_count = team_count;
	end

	local speed = CONTROL_POINT_CAPTURE_BASE +
			CONTROL_POINT_CAPTURE_MULT * self.holder_count;

	if self.holder == NO_TEAM then
		-- decrease timer if nobody is on point
		self.timer = math.max(0, self.timer - CONTROL_POINT_DECAY * dtime);
	elseif self.holder ~= self.capturer and self.holder ~= NO_TEAM then
		-- decrease timer if players on point aren't
		-- capturing the point(owner or otherwise)
		self.timer = math.max(0, self.timer - speed * dtime);

		-- when timer hits zero set capturer to team of players on point
		if self.timer == 0 and self.holder ~= self.color then
			self.capturer = self.holder;
		end
	elseif self.holder == self.capturer and
			self.holder ~= self.color and self.holder ~= NO_TEAM then
		-- increase timer if players on point are capturing the point
		self.timer = math.min(self.timer_target, self.timer + speed * dtime);
		if self.timer_target == self.timer then
			self.color = self.capturer;
			self.timer = 0;
			self.capturer = NO_TEAM;
			point_obj.reset_time = true;
			minetest.chat_send_all(string.format(
				"Control point %s has been captured by team %s!",
				self.id, self.color));
		end
	end
end

minetest.register_entity("team_fort:control_point", control_point);

local function register_control_point_item(name, texture, color)
	minetest.register_craftitem("team_fort:control_point_" .. name, {
		description = "Control point " .. name,
		inventory_image = texture,
		wield_image = texture,

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return
			end

			pointed_thing.under.y = pointed_thing.under.y + 0.5
			local entity = minetest.add_entity(pointed_thing.under,
					"team_fort:control_point");
			entity:get_luaentity().color = color;
			entity:get_luaentity().original_color = color;

			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,
	})
end

register_control_point_item("neutral", "teamf_cp_neutral_item.png", "neutral")
register_control_point_item("red", "teamf_cp_red_item.png", "red")
register_control_point_item("blue", "teamf_cp_blue_item.png", "blue")

-- Objective
function point_obj.on_joinplayer(self, player)
	local hud = {
		timer = player:hud_add(POINT_HUD_TIMER)
	}
	local i = 0;
	for id, val in pairs(self.point_data) do
		local team = Teammake.get_team(val.color);
		local color = team and team.color or 0x777777;
		local bar, txt = POINT_HUD_POINT(i, id, color);
		i = i + 1;
		hud["bar_" .. id] = player:hud_add(bar);
		hud["txt_" .. id] = player:hud_add(txt);
	end
	self.hud_elements[player:get_player_name()] = hud;
end

function point_obj.on_leaveplayer(self, player)
	local hud = self.hud_elements[player:get_player_name()];
	-- player:hud_remove(hud.timer);
	for _, v in pairs(hud) do
		player:hud_remove(v);
	end
	-- player:hud_remove(hud.list);
	self.hud_elements[player:get_player_name()] = nil;
end

function point_obj.on_globalstep(self, dtime)
	-- update gui if there are new points
	if self.new_points then
		self.new_points = false;
		for name, ids in pairs(self.hud_elements) do
			local player = minetest.get_player_by_name(name);
			if player then
				self.on_leaveplayer(self, player);
				self.on_joinplayer(self, player);
			else
				self.hud_elements[name] = nil;
			end
		end
	end

	-- announce winner if final point is captured
	if self.winner ~= NO_TEAM and self.winner ~= "neutral" then
		minetest.chat_send_all(self.winner .. " team wins!");
		Objectively.set_objective("_wait", 30, "team_fort:control_point");
	end

	-- manage timer
	self.timer = self.timer - dtime;
	if self.reset_time then
		self.reset_time = false;
		self.timer = CONTROL_POINT_TIMER_MAX;
	end

	-- red whens when timer hits 0
	if self.timer <= 0 and max_point_time <= 0 then
		-- Assumedly red team is the winner when time runs out.
		self.winner = "red";
	elseif self.timer <= 0 then
		self.is_overtime = true;
	end

	-- update text
	local ptext = POINT_HUD_TIMER.text;
	if not self.is_overtime then
		POINT_HUD_TIMER.text = jutil.string.fmt_seconds(self.timer, self.timer <= 9.9 and 1 or 0)
	else
		POINT_HUD_TIMER.text = "Overtime";
	end

	-- update hud
	if ptext ~= POINT_HUD_TIMER.text then
		for name, ids in pairs(self.hud_elements) do
			local player = minetest.get_player_by_name(name);
			if player then
				player:hud_change(ids.timer, 'text', POINT_HUD_TIMER.text);
			else
				self.hud_elements[name] = nil;
			end
		end
	end

	for name, ids in pairs(self.hud_elements) do
		local player = minetest.get_player_by_name(name);
		if player then
			for point_id, data in pairs(self.point_data) do
				local n = 20 * (1 - data.timer / data.timer_target);
				n = math.ceil(n * 2) / 2;
				player:hud_change(ids["bar_" .. point_id], 'number', n);
			end
		else
			self.hud_elements[name] = nil;
		end
	end

	max_point_time = 0;
end

function point_obj.on_enable(self)
	self.on_reset(self);
end

function point_obj.on_disable(self)
	-- nothing
end

function point_obj.on_reset(self)
	self.winner = NO_TEAM;
	self.objective_id = Objectively.get_id();
	self.timer = CONTROL_POINT_TIMER_MAX;
	self.is_overtime = false;
end

function point_obj.on_loaddata(self, data)
	jutil.deserialize_to(data, self);
end

function point_obj.get_staticdata(self)
	return jutil.serialize_safe(self, {"point_data"});
end

Objectively.register_objective('team_fort:control_point', point_obj);
