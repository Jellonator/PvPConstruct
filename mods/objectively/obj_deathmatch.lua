local DEATHMATCH_MAX_TIME =  5 * 60;
local SCORE_TEXT = "Score\n====="
local DM_HUD_TIMER = {
	hud_elem_type = "text",
	text = "",
	position = {x=0.5,y=0},
	alignment = {x=0,y=1},
	offset = {x=0,y=1},
};
local DM_HUD_LIST = {
	hud_elem_type = "text",
	text = SCORE_TEXT,
	position = {x=1,y=0.1},
	alignment = {x=-1,y=1},
	offset = {x=-4,y=0},
};
local function cmp_scores(a, b)
	return a.value < b.value;
end
local deathmatch = {
	team_data = {},
	timer = 0,
	hud_elements = {},
	on_joinplayer = function(self, player)
		self.hud_elements[player:get_player_name()] = {
			timer = player:hud_add(DM_HUD_TIMER),
			list = player:hud_add(DM_HUD_LIST)
		}
	end,
	on_leaveplayer = function(self, player)
		local hud = self.hud_elements[player:get_player_name()];
		player:hud_remove(hud.timer);
		player:hud_remove(hud.list);
		self.hud_elements[player:get_player_name()] = nil;
	end,
	on_dieplayer = function(self, player, killer)
		local killer_name = killer:get_player_name()
		if not killer_name then return end
		local killer_team = Teammake.player_get_team(killer_name);
		if not killer_team then return end
		self.team_data[killer_team] = (self.team_data[killer_team] or 0) + 1;
		DM_HUD_LIST.text = SCORE_TEXT;
		local data = {}
		for team, value in pairs(self.team_data) do
			table.insert(data, {team=team, value=value})
		end
		table.sort(data, cmp_scores);
		for i, value in ipairs(data) do
			DM_HUD_LIST.text = DM_HUD_LIST.text ..
			value.value .. " - " .. value.team;
		end
		for name, ids in pairs(self.hud_elements) do
			local player = minetest.get_player_by_name(name);
			if player then
				player:hud_change(ids.list, 'text', DM_HUD_LIST.text);
			end
		end
	end,
	on_enable = function(self)
		self.on_reset(self);
	end,
	on_reset = function(self)
		self.timer = DEATHMATCH_MAX_TIME;
		self.team_data = {}
		-- Teammake.reset();
	end,
	get_staticdata = function(self)
		return jutil.serialize_safe({team_data=self.team_data,timer=self.timer});
	end,
	on_loaddata = function(self, data)
		local data = minetest.deserialize(data) or {};
		self.timer = data.timer or DEATHMATCH_MAX_TIME;
		self.team_data = data.team_data or self.team_data;
	end,
	on_globalstep = function(self, dtime)
		self.timer = self.timer - dtime;
		if self.timer <= 0 then
			Objectively.set_objective("_wait", 20, "deathmatch")
		end
		local ptext = DM_HUD_TIMER.text;
		DM_HUD_TIMER.text = jutil.string.fmt_seconds(self.timer, self.timer <= 9.9 and 1 or 0)
		if ptext ~= DM_HUD_TIMER.text then
			for name, ids in pairs(self.hud_elements) do
				local player = minetest.get_player_by_name(name);
				if player then
					player:hud_change(ids.timer, 'text', DM_HUD_TIMER.text);
				end
			end
		end
	end
}

Objectively.register_objective("deathmatch", deathmatch);
