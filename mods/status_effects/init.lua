status_effect = {
	registered_effects = {}
}

local effect_data = {}

local DMETHOD = {
	override = 'override',
	both = 'both',
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

local function disable_effect(effect)
	local def = status_effect.registered_effects[effect._name];
	if def.on_deactivate then
		def.on_deactivate(effect, effect._object);
	end
end

local function match_def_value(effect, key, value)
	local def = status_effect.registered_effects[effect._name];
	return def[key] == value;
end

function status_effect.register_effect(name, def)
	def.duplicate_method = def.duplicate_method or DMETHOD.override;
	def.overrides = def.overrides or {};
	def.conflicts = def.conflicts or {};
	def.applies_to = def.applies_to or "all";
	if def.remove_on_death == nil then
		def.remove_on_death = true;
	end
	status_effect.registered_effects[name] = def;
end

function status_effect.parse(text)
	local name;
	local length;
	local strength;
	for v in text:gmatch("%S+") do
		if not name then
			name = v;
		elseif not length then
			length = tonumber(v);
			if not length then
				return;
			end
		elseif not strength then
			strength = tonumber(v);
			if not strength then
				return;
			end
		else
			return;
		end
	end

	return name, length, strength
end

function status_effect.remove_effect(player, name)
	local effect_list = status_effect.get_object_data(player);
	if name == nil then
		jutil.table.filter_inplace(jutil.filter.MATCH_ALL, effect_list);
	else
		jutil.table.filter_inplace(jutil.filter.MATCH_KEY_VALUE, effect_list,
			'_name', name)
	end
end

function status_effect.apply_effect(player, name, length, strength, data)
	if not length then
		return false, "No length given.";
	end
	if not player then
		return false, "No player given.";
	end
	if not name then
		return false, "No effect given.";
	end

	if length == 0 then
		status_effect.remove_effect(player, name);
	end

	local data = data or {}
	data.time = length;
	data._name = name;
	data._object = player;
	data._original_time = length;
	data._timer = 0;

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
		if jutil.filter.table_match(jutil.MATCH_KEY_VALUE, object_data, '_name',
		conflict) then
			return false, "Effect '" .. name ..
					"' conflicts with effect '" .. conflict .. "'.";
		end
	end

	-- remove overrides
	for _, override in pairs(effect_def.overrides) do
		jutil.table.filter_inplace(jutil.filter.CALL_FUNC, object_data,
				disable_effect, jutil.filter.MATCH_KEY_VALUE, '_name', override);
	end

	local pvalues = {};
	local pindexes = {};
	for i, v in ipairs(object_data) do
		if v._name == name then
			table.insert(pvalues, v);
			table.insert(pindexes, i);
		end
	end

	if #pvalues == 0 or effect_def.duplicate_method == DMETHOD.both then
		table.insert(object_data, data);
		if effect_def.on_activate then
			effect_def.on_activate(data, player, strength);
		end

	elseif type(effect_def.duplicate_method) == "function" then
		-- remove from data
		jutil.table.remove_indexes(object_data, pindexes);
		-- add based on function
		for _,v in pairs({effect_def.duplicate_method(data, unpack(pvalues))}) do
			table.insert(object_data, v);
			if v == data then
				if effect_def.on_activate then
					effect_def.on_activate(data, player, strength);
				end
			end
		end

		if effect_def.on_deactivate then
			for _,pval in pairs(pvalues) do
				-- deactivate removed values
				if not jutil.filter.match(object_data, {pval}) then
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
			effect_def.on_activate(data, player, strength);
		end

	elseif effect_def.duplicate_method == DMETHOD.reset then
		-- reset the time to the original time
		for k,v in pairs(pvalues) do
			v.time = math.max(v._original_time, data.time);
		end
	end

	return true, "Successfully applied status effect!"
end

local function update_status(effect_table, dtime)
	local rm;
	for _, effect in pairs(effect_table) do
		local def = status_effect.registered_effects[effect._name];
		local do_step = true;

		local ptime = effect._timer;
		effect._timer = effect._timer - dtime;
		local timer = effect.step_timer or def.step_timer;
		if timer then
			do_step = jutil.math.mod(ptime, timer) <
					  jutil.math.mod(effect._timer, timer);
		end

		effect.time = effect.time - dtime;
		if effect.time <= 0 then
			rm = rm or {};
			table.insert(rm, effect);
			do_step = false;
		end

		if def.on_step and do_step then
			def.on_step(effect, effect._object, dtime);
		end
	end

	if rm then
		jutil.table.filter_inplace(jutil.filter.CALL_FUNC, effect_table,
				disable_effect, rm);
	end
end

minetest.register_globalstep(function(dtime)
	for _,player in pairs(minetest.get_connected_players()) do
		local effect_table = status_effect.get_object_data(player);
		update_status(effect_table, dtime)
	end
	--[[ I will add this in later
	for _,entity in pairs(minetest.luaentities) do
		local effect_table = status_effect.get_object_data(entity);
		update_status(effect_table, dtime);
	end
	]]
end)

minetest.register_on_dieplayer(function(player)
	local player_effects = effect_data[player:get_player_name()];
	jutil.table.filter_inplace(jutil.filter.CALL_FUNC, player_effects,
			disable_effect, match_def_value, "remove_on_death", true);
end)

dofile(minetest.get_modpath("status_effects") .. "/default.lua");
dofile(minetest.get_modpath("status_effects") .. "/commands.lua");
