local CONTROL_POINT_CHECK_RATE = 0.5;
local CONTROL_POINT_RANGE = 3.0;
local CONTROL_POINT_DECAY = 0.5;
local CONTROL_POINT_CAPTURE_BASE = 0.6;
local CONTROL_POINT_CAPTURE_MULT = 0.4;
local NO_TEAM = "$NONE";

local control_point_textures = {
	neutral = "teamf_cp_neutral.png",
	red     = "teamf_cp_red.png",
	blue    = "teamf_cp_blue.png"
}

-- I should probably put lock_data into a save file, but since control points
-- should be near eachother anyways, I don't see it as a big deal.
local lock_data = {}

local control_point = {
	collisionbox = {-2.5, 0.0, -2.5, 2.5, 0.25, 2.5},
	visual = "mesh",
	mesh = "teamf_control_point.b3d",
	textures = {"teamf_cp_neutral.png"},
	visual_size = {x=10,y=10},

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
	id = NO_TEAM,

	jtool_variables = {
		color = true,
		original_color = true,
		timer_target = true,
		lock = true,
		id = true
	}
};

function control_point.on_activate(self, staticdata)
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
	-- place some variables into editor
	self.timer_target = self.timer_target;
	self.color = self.color;
	self.original_color = self.original_color;

	self.object:set_armor_groups({immortal=1})
end

function control_point.get_staticdata(self)
	return jutil.serialize_safe(self, {"pcolor", "check_time", "holder",
			"holder_count", "timer", "jtool_variables"})
end

function control_point.on_step(self, dtime)
	-- change texture depending on color
	if self.color ~= self.pcolor then
		self.pcolor = self.color;
		local tex = control_point_textures[self.color]
		self.object:set_properties({textures = {tex}})
		if self.id and self.id ~= '' then
			lock_data[self.id] = self.color;
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
				local player_team = Scoreboard.Teams.player_get_team(
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
			local lock_team = lock_data[self.lock];
			if lock_team ~= team_majority then
				team_majority = nil;
				team_count = 0;
			end
		end

		self.holder = team_majority;
		self.holder_count = team_count;
	end

	local speed = CONTROL_POINT_CAPTURE_BASE +
			CONTROL_POINT_CAPTURE_MULT * self.holder_count;

	-- if not self.capturer then
	-- 	self.capturer = self.holder;
	-- end

	if self.holder == NO_TEAM then
		-- decrease timer if nobody is on point
		self.timer = math.max(0, self.timer - CONTROL_POINT_DECAY * dtime);

	elseif self.holder ~= self.capturer and self.holder ~= NO_TEAM then
		-- decrease timer if players on point aren't
		-- capturing the point(owner or otherwise)
		self.timer = math.max(0, self.timer - speed * dtime);

		-- when timer hits zero set capturer to team of players on point
		if self.timer == 0 then
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
