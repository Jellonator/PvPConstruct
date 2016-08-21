local Class = {
	class_data = {}
}

function Class.exists(class)
	return Class.class_data[class] and true or false;
end

function Class.get(class)
	return Class.class_data[class];
end

function Class.set(class, def)
	if not Class.exists(class) then
		return Class.register(class, def);
	else
		local classdef = Class.get(class);
		for k,v in pairs(def) do
			classdef[k] = v;
		end
		Caste._increment_id()
	end
end

function Class.register(class, def)
	local def = def or {};
	if class:find("[^%w_]") then
		return false, "Class name \"" .. class .. "\" must only contain alphanumeric characters and underscores!";
	end
	if Class.get(class) then
		return false, "Class " .. class .. " already exists!"
	end
	Class.class_data[class] = def;
	Caste._increment_id()
	return true, "Successfully created class!";
end

function Class.remove(class)
	if not Class.get(class) then
		return false, "Class " .. class .. " does not exist!"
	end
	for player_name, player_class in pairs(Caste.player.player_data) do
		if player_class == class then
			Caste.player.leave(player_name);
		end
	end
	Class.class_data[class] = nil;
	Caste._increment_id();
	return true, "Successfully removed a player's class!";
end

-- Items
function Class.add_item(class, item, count)
	local class_data = Class.get(class);
	if not class_data then
		return false, "Class " .. class .. " does not exist!"
	end

	class_data.items = class_data.items or {}
	table.insert(class_data.items, {name=item, count=count or 1});
	Caste._increment_id()

	return true, "Successfully added item to class' definition!"
end

function Class.remove_item(class, item)
	local class_data = Class.get(class);
	if not class_data then
		return false, "Class " .. class .. " does not exist!"
	end
	local items = class_data.items or {};
	local pval = #items;
	jutil.table.filter_inplace(jutil.filter.MATCH_KEY_VALUE, items, 'name', item);
	Caste._increment_id()
	if pval == #items then
		return false, "No such item defined in class!";
	else
		return true, "Successfully removed items!"
	end
end

function Class.get_items(class)
	local class_data = Class.get(class);
	if not class_data then
		return;
	end
	if not class_data.items or #class_data.items == 0 then
		return;
	end
	return class_data.items;
end

function Class.list_items(class)
	local class_data = Class.get(class);
	if not class_data then
		return;
	end

	if not class_data.items or #class_data.items == 0 then
		return;
	end

	local str = "";
	for i,item in ipairs(class_data.items) do
		if i ~= 1 then str = str .. '\n' end
		str = str .. item.name .. " " .. tostring(item.count);
	end

	return str;
end

return Class;
