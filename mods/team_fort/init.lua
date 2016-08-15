TEAM_COLOR = {
	NEUTRAL = 1,
	RED = 2,
	BLU = 3,
	BLUE = 3, -- just in case
}

-- register some basic teams
Scoreboard.Teams.register_team("red", {nametag_color = 0xFFFF0000})
Scoreboard.Teams.register_team("blue", {nametag_color = 0xFF0000FF})

-- Load all objects
local nodes_to_load = {};
local items_to_load = {};
local entities_to_load = {"control_point", "payload"};

for _,name in pairs(entities_to_load) do
	dofile(minetest.get_modpath("team_fort") .. "/entities/" .. name .. ".lua");
end
dofile(minetest.get_modpath("team_fort") .. "/commands.lua");
dofile(minetest.get_modpath("team_fort") .. "/nodes.lua");
dofile(minetest.get_modpath("team_fort") .. "/weapons.lua");
