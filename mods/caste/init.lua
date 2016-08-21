Caste = {}

local CASTE_FILE_NAME = minetest.get_worldpath() .. "/caste.dat"
local CASTE_FILE_VERSION = 1;

local incremental_id = 0;
local prev_incremental_id = incremental_id;

function Caste._increment_id()
	incremental_id = incremental_id + 1;
end

-- The entire caste file format is pretty much the same as that of teammake
local function loadcaste()
	local caste_file = io.open(CASTE_FILE_NAME, "r");
	if not caste_file then return end

	local version = caste_file:read("*l");
	if version ~= CASTE_FILE_VERSION then return end

	-- load classes
	while caste_file:read(0) do
		local line = caste_file:read("*l");
		if line == ":players:" then break end

		local first_space = line:find(' ');
		if first_space then
			local class_name = line:sub(1, first_space - 1);
			local def_str = line:sub(first_space + 1);
			local def = minetest.deserialize(def_str);
			Caste.class.class_data[class_name] = def
		end
	end

	-- load players
	while caste_file:read(0) do
		local line = caste_file:read("*l");
		local first_space = line:find(' ');
		if first_space then
			local class_name = line:sub(1, first_space - 1);
			local player_name = line:sub(first_space + 1);
			if class_name and player_name then
				Caste.player.join(player_name, class_name);
			end
		end
	end

	caste_file:close();
end

local function savecaste()
	local caste_file = io.open(CASTE_FILE_NAME, "w");
	caste_file:write(CASTE_FILE_VERSION, '\n');

	for class, def in pairs(Caste.class.class_data) do
		caste_file:write(class, ' ', minetest.serialize(def), '\n');
	end

	caste_file:write(":players:\n");

	for player, class in pairs(Caste.player.player_data) do
		caste_file:write(class, ' ', player, '\n')
	end

	caste_file:close();
end

local function savecaste_timer()
	if prev_incremental_id ~= incremental_id then
		savecaste();
		prev_incremental_id = incremental_id;
	end

	minetest.after(10, savecaste_timer);
end

Caste.class  = dofile(minetest.get_modpath('caste') .. "/class.lua");
Caste.player = dofile(minetest.get_modpath('caste') .. "/player.lua");
dofile(minetest.get_modpath('caste') .. "/commands.lua");

loadcaste();
minetest.register_on_shutdown(savecaste);
minetest.after(10, savecaste_timer);
