team_fort = {};

TEAM_COLOR = {
	NEUTRAL = 1,
	RED = 2,
	BLU = 3,
	BLUE = 3, -- just in case
}

-- register some basic teams
Teammake.set_team("red", {
	color = 0xFFFF0000,
	gui_hotbar_image = "teamf_gui_hotbar_red.png"
})
Teammake.set_team("blue", {
	color = 0xFF0000FF,
	gui_hotbar_image = "teamf_gui_hotbar_blue.png"
})

-- Load all objects
local entities_to_load = {"control_point", "payload"};

for _,name in pairs(entities_to_load) do
	dofile(minetest.get_modpath("team_fort") .. "/entities/" .. name .. ".lua");
end

dofile(minetest.get_modpath("team_fort") .. "/commands.lua");
dofile(minetest.get_modpath("team_fort") .. "/nodes.lua");
dofile(minetest.get_modpath("team_fort") .. "/weapons.lua");
dofile(minetest.get_modpath("team_fort") .. "/koth.lua");

local creative_mode = minetest.setting_getbool("creative_mode")
if not creative_mode and not minetest.is_singleplayer() then
	local old_func = minetest.is_protected;
	minetest.is_protected = function(pos, playername)
		-- those with protection_bypass are fine
		if minetest.check_player_privs(playername, {protection_bypass=true}) then
			return old_func(pos, playername);
		end

		-- everyone else gets rekt tho
		return true;
	end
end
