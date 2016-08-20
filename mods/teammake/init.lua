Teammake = {
	NONE_TEAM = "__NONE__"
};
-- players are given Teams by key, not value
-- players not listed are not in a team
-- e.g. {jellonator="red",bob="blue"}

local TEAM_FILE_NAME = minetest.get_worldpath() .. "/scoreboard_teams"
local TEAM_FILE_VERSION = "1";

local team_players = {}
local team_data = {
	[Teammake.NONE_TEAM] = {} -- team that is not a team. used for default values.
}
local incremental_id = 0;
local prev_incremental_id = incremental_id;

local function get_team_spawn(team)
	local teamdata = Teammake.get_team(team);
	if teamdata and teamdata.spawn then
		if teamdata.spawn.r then
			local spawn = teamdata.spawn;
			local newpos = {
				x = spawn.x + math.random(-spawn.r, spawn.r),
				y = spawn.y,
				z = spawn.z + math.random(-spawn.r, spawn.r),
			}
			return newpos, spawn.yaw;
		else
			return teamdata.spawn, teamdata.spawn.yaw;
		end
	end

	if team ~= Teammake.NONE_TEAM then
		return get_team_spawn(Teammake.NONE_TEAM);
	end
end

local function increment_id()
	incremental_id = incremental_id + 1;
end

local function loadteams()
	local team_file = io.open(TEAM_FILE_NAME, "r");
	if not team_file then return end

	local version = team_file:read("*l");
	if version ~= TEAM_FILE_VERSION then return end

	-- load teams
	local team_def;
	while team_file:read(0) do
		local line = team_file:read("*l");
		if line == ":players:" then break end

		local first_space = line:find(' ');
		if first_space then
			local team_name = line:sub(1, first_space - 1);
			local def_str = line:sub(first_space + 1);
			local def = minetest.deserialize(def_str);
			team_data[team_name] = def
		end
	end

	-- load players
	while team_file:read(0) do
		local line = team_file:read("*l");
		local first_space = line:find(' ');
		if first_space then
			local team_name = line:sub(1, first_space - 1);
			local player_name = line:sub(first_space + 1);
			if team_name and player_name then
				Teammake.player_join(team_name, player_name);
			end
		end
	end

	team_file:close();
end

local function saveteams()
	local team_file = io.open(TEAM_FILE_NAME, "w");
	team_file:write(TEAM_FILE_VERSION, '\n');

	for team_name, team_def in pairs(team_data) do
		team_file:write(team_name, ' ', minetest.serialize(team_def), '\n')
	end

	team_file:write(":players:\n");

	for player_name, player_team in pairs(team_players) do
		team_file:write(player_team, ' ', player_name, '\n')
	end

	team_file:close();
end

local function saveteams_timer()
	if prev_incremental_id ~= incremental_id then
		saveteams();
		prev_incremental_id = incremental_id;
	end

	minetest.after(10, saveteams_timer);
end

local function set_player_nametag_color(player, team)
	local properties = {}
	local hotbar_image = "gui_hotbar.png";
	if team then
		local teamdef = Teammake.get_team(team);
		print(teamdef);
		properties.nametag_color = teamdef and teamdef.color or {};
		hotbar_image = teamdef and teamdef.gui_hotbar_image or hotbar_image;
	else
		properties.nametag_color = {}
	end
	if type(properties.nametag_color) == "table" then
		-- properties.color.r = properties.color.r or 255;
		-- properties.color.g = properties.color.g or 255;
		-- properties.color.b = properties.color.b or 255;
		properties.nametag_color.a = properties.nametag_color.a or 255;
	end
	player:set_properties(properties)
	player:hud_set_hotbar_image(hotbar_image);
end

local function reset_player(player)
	local player_name = player:get_player_name();
	local player_team = Teammake.player_get_team(player_name);
	set_player_nametag_color(player, player_team);

	local spawn, yaw = get_team_spawn(player_team);
	print(spawn, yaw);
	if yaw then
		player:set_look_yaw(math.rad(yaw - 90));
	end
	if spawn then
		player:setpos(spawn);
		return true;
	end
	return false;
end

function Teammake.set_color(team, color)
	if not Teammake.team_exists(team) then
		return false, string.format("Team %s does not exist!", team);
	end
	Teammake.get_team(team).color = color;
	increment_id();
	return true, "Successfully set team color!";
end

function Teammake.set_spawn(team, pos)
	if not Teammake.team_exists(team) then
		return false, string.format("Team %s does not exist!", team);
	end
	Teammake.get_team(team).spawn = pos;
	increment_id();
	return true, "Successfully set team spawn!";
end

function Teammake.team_exists(team)
	return team_data[team] and true or false;
end

function Teammake.get_team(team)
	return team_data[team]
end

function Teammake.has_player(team, player)
	return team_players[player] == team;
end

function Teammake.player_get_team(player)
	return team_players[player];
end

function Teammake.player_leave(player)
	if team_players[player] == nil then
		return false, string.format("Player %s is not on a team!", player);
	end
	team_players[player] = nil;
	local playerent = minetest.get_player_by_name(player);
	if playerent then
		reset_player(playerent)
	end
	minetest.chat_send_all(string.format("Player %s left their team!", player))
	increment_id()

	return true
end

function Teammake.player_join(team, player)
	if not Teammake.team_exists(team) then
		return false, string.format("Team %s does not exist!", team);
	end
	if Teammake.has_player(team, player) then
		return false, string.format("Player %s is already on team %s!", player, team);
	end
	team_players[player] = team;
	local playerent = minetest.get_player_by_name(player);
	if playerent then
		reset_player(playerent);
	end
	minetest.chat_send_all(string.format("Player %s joined team %s!", player, team));
	increment_id()
	return true
end

function Teammake.set_team(team, def)
	if not Teammake.team_exists(team) then
		return Teammake.register_team(team, def);
	else
		local teamdef = Teammake.get_team(team);
		for k,v in pairs(def) do
			teamdef[k] = v;
		end
	end
end

function Teammake.register_team(team, def)
	if team:find("[^%w_]") then
		return false, "Team name \"" .. team .. "\" must only contain alphanumeric characters and underscores!";
	end
	if Teammake.get_team(team) then
		return false, "Team " .. team .. " already exists!"
	end
	def.color = def.color or {r=0,g=0,b=0,a=255};
	team_data[team] = def;
	increment_id()
	return def;
end

function Teammake.remove_team(team)
	if not Teammake.get_team(name) then
		return false, "Team " .. name .. " does not exist!"
	end
	for player_name, player_team in pairs(team_players) do
		if player_team == team then
			team_players[player_name] = nil
		end
	end
	team_data[team] = nil;
	increment_id()
	return true;
end

function Teammake.respawn(team)
	for player_name, player_team in pairs(team_players) do
		local player = minetest.get_player_by_name(player_name);
		-- reset all players on team, or all players if team is nil
		if (not team or player_team == team) and player_team and player then
			reset_player(player);
		end
	end
end

-- respawn players who join
minetest.register_on_joinplayer(function(player)
	local team = Teammake.player_get_team(player:get_player_name());
	if team then
		if not Teammake.team_exists(team) then
			Teammake.player_leave(player:get_player_name());
		end
	end
	return reset_player(player);
end)

-- respawn players who have died
minetest.register_on_respawnplayer(function(player)
	if not player:is_player() then return false end
	return reset_player(player);
end)

-- disable damage between members of team
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch,
tool_capabilities, dir, damage)
	if not hitter:is_player() or not player:is_player() then
		return false;
	end
	local player_team = Teammake.player_get_team(player:get_player_name());
	local hitter_team = Teammake.player_get_team(hitter:get_player_name());
	if player_team == Teammake.NONE_TEAM or hitter_team == Teammake.NONE_TEAM then
		return false;
	end
	-- when players are on same team disable punching
	return player_team == hitter_team;
end)


minetest.register_on_shutdown(saveteams);
minetest.after(10, saveteams_timer);

loadteams();

dofile(minetest.get_modpath("teammake") .. "/commands.lua");
