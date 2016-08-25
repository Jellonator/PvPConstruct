local function KOTH_HUD_POINT(xpos, color, starttime)
	color = jutil.get_color_num(color);
	local color_num = jutil.get_color_num(color);
	color = color % 0x01000000
	local color_num = color;
	color = color + 0xff000000;
	color = string.format("%X", color);
	color = "#" .. color:sub(3);
	return {
		hud_elem_type = "text",
		text = starttime,
		number = color_num,
		position = {x=0.5,y=0},
		alignment = {x=0,y=1},
		offset = {x = xpos, y=2},
	}, {
		hud_elem_type = "image",
		text = "objectively_timetab.png^[colorize:" .. color .. ":100",
		scale = {x=1,y=1},
		position = {x=0.5,y=0},
		alignment = {x=0,y=1},
		offset = {x = xpos, y=0},
	}
end

local obj_koth = {
	team_timers = {},
	hud_elements = {},
	current_team = team_fort.cp.NO_TEAM
}

function obj_koth.on_enable(self)
	obj_koth.on_reset(self);
end

function obj_koth.on_reset(self)
	self.current_team = team_fort.cp.NO_TEAM
	self.team_timers = {}
	for k,v in pairs(Teammake.get_team_list()) do
		self.team_timers[v] = Objectively.get_global_timer();
		obj_koth.reset_hud(self, v);
	end
	team_fort.cp.set_id();
	team_fort.cp.set_winner();
end

function obj_koth.reset_hud(self, team)
	local str = self.team_timers[team];
	str = jutil.string.fmt_seconds(str, str < 10 and 1 or 0);

	for name, ids in pairs(self.hud_elements) do
		local player = minetest.get_player_by_name(name);
		if player then
			player:hud_change(ids[team], 'text', str);
		else
			self.hud_elements[name] = nil;
		end
	end
end

function obj_koth.on_joinplayer(self, player)
	local hud = {}
	local num = 0;
	for k,v in pairs(self.team_timers) do num = num + 1; end
	local WIDTH = 64;
	local cur = -(num-1) * WIDTH / 2;
	print("POINT", cur, num)
	for k,v in pairs(self.team_timers) do
		local str = v or 0;
		str = jutil.string.fmt_seconds(str, str < 10 and 1 or 0);

		local team = Teammake.get_team(k);
		local color = team and team.color or 0x777777;
		local time, tab = KOTH_HUD_POINT(cur, color, str)
		hud['!' .. k] = player:hud_add(tab);
		hud[k] = player:hud_add(time);
		cur = cur + WIDTH;
	end
	self.hud_elements[player:get_player_name()] = hud;
end

function obj_koth.on_leaveplayer(self, player)
	local hud = self.hud_elements[player:get_player_name()];
	for _, v in pairs(hud) do
		player:hud_remove(v);
	end
	self.hud_elements[player:get_player_name()] = nil;
end

function obj_koth.on_globalstep(self, dtime)
	local new_winner = team_fort.cp.get_winner();
	team_fort.cp.reset_winner();
	if new_winner and new_winner ~= self.current_team and new_winner ~= team_fort.cp.NO_TEAM then
		self.current_team = new_winner;
	end
	if self.team_timers[self.current_team] then
		self.team_timers[self.current_team] = self.team_timers[self.current_team] - dtime;
		if self.team_timers[self.current_team] <= 0 then
			minetest.chat_send_all(self.current_team .. " team wins!");
			Objectively.set_objective("_wait", 30, "team_fort:koth");
		end

		obj_koth.reset_hud(self, self.current_team);
	end
end

function obj_koth.on_loaddata(self, data)
	jutil.deserialize_to(data, self);
end

function obj_koth.get_staticdata(self)
	return jutil.serialize_safe(self, {});
end

Objectively.register_objective("team_fort:koth", obj_koth)
