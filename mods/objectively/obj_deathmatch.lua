local DEATHMATCH_MAX_TIME =  5 * 60;
local SCORE_TEXT = "Scoreboard\n=========="
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
	is_overtime = false,
	try_win = function(self)
		if #self.team_data == 0 or (#self.team_data > 1 and
				self.team_data[1].count == self.team_data[2].count) then
			self.is_overtime = true;
		else
			minetest.chat_send_all(self.team_data[1].team .. " team wins!")
			Objectively.set_objective("_wait", 20, "deathmatch")
		end
	end,

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
		print("DIE ", self, player, killer)
		local killer_name = killer:get_player_name()
		if not killer_name then return end
		local killer_team = Teammake.player_get_team(killer_name);
		if not killer_team then return end
		print("GOOD");

		-- self.team_data[killer_team] = self.team_data[killer_team] or
		-- 		{team=killer_team, count=0};

		-- self.team_data[killer_team].count = self.team_data[killer_team].count + 1;

		local team_def;

		for _, def in ipairs(self.team_data) do
			if def.team == killer_team then
				team_def = def;
				break;
			end
		end

		if not team_def then
			team_def = {team=killer_team, count=0};
			table.insert(self.team_data, team_def);
		end

		def.count = def.count + 1;

		DM_HUD_LIST.text = SCORE_TEXT;
		table.sort(self.team_data, cmp_scores);
		for i, value in ipairs(self.team_data) do
			DM_HUD_LIST.text = DM_HUD_LIST.text .. '\n' ..
			value.value .. " - " .. value.team;
		end

		for name, ids in pairs(self.hud_elements) do
			local player = minetest.get_player_by_name(name);
			if player then
				player:hud_change(ids.list, 'text', DM_HUD_LIST.text);
			end
		end

		if self.is_overtime then
			self.try_win(self);
		end
	end,

	on_enable = function(self)
		self.on_reset(self);
	end,

	on_reset = function(self)
		self.timer = DEATHMATCH_MAX_TIME;
		self.team_data = {}
		self.is_overtime = false;
		Teammake.respawn();
	end,

	get_staticdata = function(self)
		return jutil.serialize_safe({team_data=self.team_data,timer=self.timer});
	end,

	on_loaddata = function(self, data)
		local data = minetest.deserialize(data) or {};
		self.timer = data.timer or DEATHMATCH_MAX_TIME;
		self.team_data = data.team_data or self.team_data or {};
	end,

	on_globalstep = function(self, dtime)
		self.timer = self.timer - dtime;
		if self.timer <= 0 then
			self.try_win(self);
		end
		local ptext = DM_HUD_TIMER.text;
		if not self.is_overtime then
			DM_HUD_TIMER.text = jutil.string.fmt_seconds(self.timer, self.timer <= 9.9 and 1 or 0)
		else
			DM_HUD_TIMER.text = "Overtime";
		end

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
