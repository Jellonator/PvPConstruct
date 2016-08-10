MOD_NAME = "team_fort"
TEXTURE_PREFIX = "teamf_"

TEAM_COLOR = {
	NEUTRAL = 1,
	RED = 2,
	BLU = 3,
	BLUE = 3, -- just in case
}

-- Basic functions
function get_file(...)
	return minetest.get_modpath(MOD_NAME) .. "/" .. table.concat({...}, '/');
end

function get_res(name)
	return TEXTURE_PREFIX .. name;
end

function get_name(...)
	return string.format("%s:%s", MOD_NAME, table.concat({...}, ' '));
end

-- Load extra utilities
dofile(get_file("util.lua"));

-- register some basic teams
Scoreboard.Teams.register_team("red", {nametag_color = 0xFFFF0000})
Scoreboard.Teams.register_team("blue", {nametag_color = 0xFF0000FF})

-- Load all objects
local nodes_to_load = {};
local items_to_load = {};
local entities_to_load = {"control_point", "payload"};

function init()
	for _,name in pairs(nodes_to_load) do
		dofile(get_file("nodes", name .. ".lua"));
	end
	for _,name in pairs(items_to_load) do
		dofile(get_file("items", name .. ".lua"));
	end
	for _,name in pairs(entities_to_load) do
		dofile(get_file("entities", name .. ".lua"));
	end
	dofile(get_file("commands.lua"));
end

init();
