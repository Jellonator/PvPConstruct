Caste = {}

local CASTE_FILE_NAME = minetest.get_worldpath() .. "/caste.dat"
local CASTE_FILE_VERSION = 1;

local incremental_id = 0;
local prev_incremental_id = incremental_id;

function Caste._increment_id()
	incremental_id = incremental_id + 1;
end

Caste.class  = dofile(minetest.get_modpath('caste') .. "/class.lua");
Caste.player = dofile(minetest.get_modpath('caste') .. "/player.lua");
dofile(minetest.get_modpath('caste') .. "/commands.lua");
