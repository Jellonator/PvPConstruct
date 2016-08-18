status_effect = {
	registered_effects = {}
}

local effect_data = {}

local DMETHOD = {
	override = 'override',
	copy = 'copy',
	reset = 'reset'
}

local entstatus_name = "$_STATUSEFFECTLIST"
function status_effect.get_object_data(object)
	-- player status effects are stored inside a special table
	if object:is_player() then
		local ret = effect_data[object:get_player_name()];
		if not ret then
			ret = {}
			effect_data[object:get_player_name()] = ret
		end
		return ret;
	end

	-- entity status effects are stored inside the entity
	-- (hopefully) the entity will store its effects when serializing
	local luaent = object:get_luaentity();
	if luaent then
		local ret = luaent[entstatus_name];
		if not ret then
			ret = {}
			luaent[entstatus_name] = ret;
		end
		return ret;
	end
end

function status_effect.register_effect(name, def)
	def.duplicate_method = def.duplicate_method or DMETHOD.override;
	def.overrides = def.overrides or {};
	def.conflicts = def.conflicts or {};
	def.applies_to = def.applies_to or "all";
	status_effect.registered_effects[name] = def;
end

local function match_effect_name(effect, name)
	return effect._name == name;
end

local function remove_effect_name(effect, name)
	local def = status_effect.registered_effects[name];
	if match_effect_name(effect, name) then
		if def.on_deactivate then
			def.on_deactivate(effect, effect._object);
		end
		return true;
	end
	return false;
end

function status_effect.apply_effect(name, player, length, data)
	local data = data or {}
	data.time = length;
	data._name = name;
	data._object = player;
	data._original_time = length;

	local object_data = status_effect.get_object_data(player);
	local effect_def = status_effect.registered_effects[name];

	if not object_data then
		error("This object can not store status effect data.");
	end
	if not effect_def then
		return false, "No such effect of name '" .. name .. "'";
	end
	if effect_def.applies_to == "player" and not player:is_player() then
		return false, "This effect can only be applied to players!";
	end
	if effect_def.applies_to == "object" and not player:get_luaentity() then
		return false, "This effect can only be applied to entities!";
	end

	-- fail on conflict
	for _, conflict in pairs(effect_def.conflicts) do
		if jutil.table_match_filter(object_data, match_effect_name, conflict) then
			return false, "Effect '" .. name ..
					"' conflicts with effect '" .. conflict .. "'.";
		end
	end

	-- remove overrides
	for _, override in pairs(effect_def.overrides) do
		jutil.table_filter_inplace(object_data, remove_effect_name, override);
	end

	local pvalues = {};
	local pindexes = {};
	for i, v in ipairs(object_data) do
		if v._name == name then
			table.insert(pvalues, v);
			table.insert(pindexes, i);
		end
	end

	if #pvalues == 0 or effect_def.duplicate_method == DMETHOD.copy then
		table.insert(object_data, data);
		if effect_def.on_activate then
			effect_def.on_activate(data, player);
		end

	elseif type(effect_def.duplicate_method) == "function" then
		-- remove from data
		jutil.remove_indexes(object_data, pindexes);
		-- add based on function
		for _,v in pairs({effect_def.duplicate_method(data, unpack(pvalues))}) do
			table.insert(object_data, v);
			if v == data then
				if effect_def.on_activate then
					effect_def.on_activate(data, player);
				end
			end
		end

		if effect_def.on_deactivate then
			for _,pval in pairs(pvalues) do
				-- deactivate removed values
				if not jutil.match_filter(object_data, {pval}) then
					effect_def.on_deactivate(pval, player);
				end
			end
		end

	elseif effect_def.duplicate_method == DMETHOD.override then
		-- replace the data with the new data, along with longest time
		if effect_def.on_deactivate then
			effect_def.on_deactivate(pvalues[1], player);
		end
		data.time = math.max(pvalues[1].time, data.time);
		object_data[pindexes[1]] = data;
		if effect_def.on_activate then
			effect_def.on_activate(data, player);
		end

	elseif effect_def.duplicate_method == DMETHOD.reset then
		-- reset the time to the original time
		for k,v in pairs(pvalues) do
			v.time = math.max(v._original_time, data.time);
		end
	end

	return true, "Successfully applied status effect!"
end

minetest.register_globalstep(function(dtime)
	for _,player in pairs(minetest.get_connected_players()) do
		local player_effects = status_effect.get_object_data(player);
		local rm;
		for _, effect in pairs(player_effects) do
			local def = status_effect.registered_effects[effect._name];
			if def.on_step then
				def.on_step(effect, player, dtime);
			end
			effect.time = effect.time - dtime;
			if effect.time <= 0 then
				rm = rm or {};
				table.insert(rm, effect);
				if def.on_deactivate then
					def.on_deactivate(effect, player);
				end
			end
		end

		if rm then
			jutil.table_filter_inplace(rm, player_effects, v, def);
		end
	end
end)

dofile(minetest.get_modpath("status_effects") .. "/default.lua");
dofile(minetest.get_modpath("status_effects") .. "/commands.lua");
