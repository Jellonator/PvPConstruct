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

end

function status_effect.apply_effect(name, player, length, data)
	local data = data or {}
	data.time = length;
	data._name = name;
	data._original_time = length;

	local object_data = status_effect.get_object_data(player);
	local effect_def = status_effect.registered_effects[name];

	if not object_data then
		error("This object can not store status effect data.");
	end
	if not effect_def then
		error("No such effect of name '" .. name .. "'");
	end

	local pvalues;
	local pindexes;
	for i,v in pairs(object_data) do
		if v._name == name then
			table.insert(pvalues, v);
			table.insert(pindexes, i);
		end
	end

	if #pvalues == 0 or def.duplicate_method == DMETHOD.copy then
		table.insert(object_data, data);
		
	elseif type(def.duplicate_method) == "function" then
		-- remove from data
		jutil.remove_indexes(object_data, pindexes);
		-- add based on function
		for _,v in pairs({def.duplicate_method(data, unpack(pvalues))}) do
			table.insert(object_data, v);
		end

	elseif def.duplicate_method == DMETHOD.override then
		-- replace the data with the new data, along with longest time
		data.time = math.max(pvalues[1].time, data.time);
		object_data[pindexes[1]] = data;

	elseif def.duplicate_method == DMETHOD.reset then
		-- reset the time to the original time
		for k,v in pairs(pvalues) do
			v.time = math.max(v._original_time, data.time);
		end
	end
end
