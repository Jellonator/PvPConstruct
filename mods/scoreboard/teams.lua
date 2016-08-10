local Teams = {};
-- players are given Teams by key, not value
-- players not listed are not in a team
-- e.g. {"jellonator"="red","bob"="blue"}
local TEAM_FILE_NAME = minetest.get_worldpath() .. "/scoreboard_teams"
local TEAM_FILE_VERSION = "1";
local team_players = {}
local team_data = {}
local incremental_id = 0;
local prev_incremental_id = incremental_id;

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
			Teams.register_team(team_name, def);
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
				Teams.player_join(team_name, player_name);
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

minetest.register_on_shutdown(saveteams);
minetest.after(10, saveteams_timer);

local function set_player_nametag_color(player, team)
	local properties = {}
	if team then
		local teamdef = Teams.get_team(team);
		print(teamdef);
		properties.nametag_color = teamdef and teamdef.nametag_color or {};
	else
		properties.nametag_color = {}
	end
	if type(properties.nametag_color) == "table" then
		properties.nametag_color.r = properties.nametag_color.r or 255;
		properties.nametag_color.g = properties.nametag_color.g or 255;
		properties.nametag_color.b = properties.nametag_color.b or 255;
		properties.nametag_color.a = properties.nametag_color.a or 255;
	end
	player:set_properties(properties)
end

minetest.register_on_joinplayer(function(player)
	local team = Teams.player_get_team(player:get_player_name());
	if team then
		set_player_nametag_color(player, team);
	end
end)

function Teams.team_exists(team)
	return team_data[team] and true or false;
end

function Teams.get_team(team)
	return team_data[team]
end

function Teams.has_player(team, player)
	return team_players[player] == team;
end

function Teams.player_get_team(player)
	return team_players[player];
end

function Teams.player_leave(player)
	if team_players[player] == nil then
		return false, string.format("Player %s is not on a team!", player);
	end
	team_players[player] = nil;
	local playerent = minetest.get_player_by_name(player);
	if playerent then
		set_player_nametag_color(playerent);
	end
	minetest.chat_send_all(string.format("Player %s left their team!", player))
	increment_id()
	return true
end

function Teams.player_join(team, player)
	if not Teams.team_exists(team) then
		return false, string.format("Team %s does not exist!", team);
	end
	if Teams.has_player(team, player) then
		return false, string.format("Player %s is already on team %s!", player, team);
	end
	team_players[player] = team;
	local playerent = minetest.get_player_by_name(player);
	if playerent then
		set_player_nametag_color(playerent, team);
	end
	minetest.chat_send_all(string.format("Player %s joined team %s!", player, team));
	increment_id()
	return true
end

function Teams.register_team(team, def)
	if team:find("[^%w_]") then
		return false, "Team name \"" .. team .. "\" must only contain alphanumeric characters and underscores!";
	end
	if Teams.get_team(team) then
		return false, "Team " .. team .. " already exists!"
	end
	def.nametag_color = def.nametag_color or {r=0,g=0,b=0,a=255};
	team_data[team] = def;
	increment_id()
	return def;
end

function Teams.remove_team(team)
	if not Teams.get_team(name) then
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

loadteams();
return Teams;
