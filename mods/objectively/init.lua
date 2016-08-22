Objectively = {
	objective_id = "",
	registered_objectives = {},
	current_objective = ""
}

local staticdatas = {}
local OBJECTIVE_FILE_NAME = minetest.get_worldpath() .. "/objectively.dat";
local OBJECTIVE_FILE_VERSION = '1';
local function saveobjective()
	local objective_data = {};
	for name, def in pairs(Objectively.registered_objectives) do
		local val;
		if def.get_staticdata then
			val = def.get_staticdata(def)
		end
		objective_data[name] = val;
	end

	local file = io.open(OBJECTIVE_FILE_NAME, 'w');
	file:write(OBJECTIVE_FILE_VERSION, '\n');
	-- current should always come first
	file:write(":current:\n", Objectively.current_objective, '\n');
	file:write(":data:\n", jutil.serialize_safe(objective_data), '\n');
	file:close();
end

local function loadobjective()
	local file = io.open(OBJECTIVE_FILE_NAME, 'r');
	if not file then return end

	local version = file:read("*l");
	if version ~= OBJECTIVE_FILE_VERSION then return end

	local ckey = '';
	while file:read(0) do
		local line = file:read("*l");
		if line:sub(1,1) == ':' then
			ckey = line;
		elseif ckey == ':current:' then
			Objectively.set_objective(line);
		elseif ckey == ':data:' then
			local data = minetest.deserialize(line);
			for name,def in pairs(data) do
				local obj = Objectively.registered_objectives[name];
				if obj.on_loaddata then
					obj.on_loaddata(obj, def);
				end
			end
		end
	end

	file:close();
end

--[[
Objective ID system
The idea is that when an objective is completed, the ID is reset so that all
objects with the previous objective id will reset too.

Currently, objective ids reset when the world loads. This might be for the best
anyways.
--]]
function Objectively.get_id()
	return Objectively.objective_id;
end

function Objectively.is_updated(prev_id)
	return Objectively.get_id() ~= prev_id;
end

function Objectively.reset()
	Objectively.objective_id = jutil.gen_uuid();
	local obj = Objectively.get_objective();
	if obj and obj.on_reset then
		obj.on_reset(obj)
	end
end

--[[
Actual objective stuff
--]]
function Objectively.register_objective(name, def)
	if name:find("[^%w_:]") then
		return false, "Objective name \"" .. name ..
			"\" must only contain alphanumeric characters and underscores!";
	end
	Objectively.registered_objectives[name] = def;
	return true, "Successfully registered the objective."
end

function Objectively.set_objective(name, ...)
	if name == Objectively.current_objective then
		return false, "That objective is already active!";
	end
	local prev_obj = Objectively.registered_objectives[Objectively.current_objective];
	local new_obj = Objectively.registered_objectives[name];
	if not new_obj then
		return false, "No such objective of name " .. name .. "!"
	end
	if prev_obj then
		if prev_obj.on_leaveplayer then
			for _,player in pairs(minetest.get_connected_players()) do
				prev_obj.on_leaveplayer(prev_obj, player);
			end
		end
		if prev_obj.on_disable then
			prev_obj.on_disable(prev_obj);
		end
	end

	Objectively.objective_id = jutil.gen_uuid();
	Objectively.current_objective = name;
	if new_obj then
		if new_obj.on_enable then
			new_obj.on_enable(new_obj, ...);
		end
		if new_obj.on_joinplayer then
			for _,player in pairs(minetest.get_connected_players()) do
				new_obj.on_joinplayer(new_obj, player);
			end
		end
	end

	return true, "Successfully enabled the objective."
end

function Objectively.get_objective()
	return Objectively.registered_objectives[Objectively.current_objective];
end

minetest.register_on_joinplayer(function(player)
	local obj = Objectively.get_objective();
	if obj and obj.on_joinplayer then
		obj.on_joinplayer(obj, player);
	end
end)

minetest.register_on_leaveplayer(function(player)
	local obj = Objectively.get_objective();
	if obj and obj.on_leaveplayer then
		obj.on_leaveplayer(obj, player);
	end
end)

minetest.register_globalstep(function(dtime)
	local obj = Objectively.get_objective();
	if obj and obj.on_globalstep then
		obj.on_globalstep(obj, dtime);
	end
end)

local last_hitter = setmetatable({}, {__mode = "kv"})
minetest.register_on_punchplayer(function(player, hitter)
	if not player or not hitter then
		return
	end
	last_hitter[player] = hitter;
end)

minetest.register_on_dieplayer(function(player)
	local obj = Objectively.get_objective();
	if obj and obj.on_dieplayer then
		obj.on_dieplayer(obj, player, last_hitter[player]);
	end
	last_hitter[player] = nil;
end)

--Objectively.gen =
dofile(minetest.get_modpath('objectively') .. "/obj_deathmatch.lua")
dofile(minetest.get_modpath('objectively') .. "/obj_wait.lua")
dofile(minetest.get_modpath('objectively') .. "/commands.lua")
minetest.after(0,  loadobjective);
minetest.register_on_shutdown(saveobjective);
Objectively.reset();
