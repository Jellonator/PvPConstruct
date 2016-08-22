local Filter = {};

--[[
Filter which matches everything
--]]
Filter.MATCH_ALL = function()
	return true;
end

--[[
Filter which matches a value with another value
--]]
Filter.MATCH_VALUE = function(a, b)
	return a == b;
end

--[[
Filter which matches a table's key with a value
--]]
Filter.MATCH_KEY_VALUE = function(t, key, value)
	return t[key] == value;
end

--[[
Filter which calls a function if a match succeeds
--]]
Filter.CALL_FUNC = function(value, func, filter, ...)
	if Filter.match(filter, value, ...) then
		func(value, ...);
		return true;
	end
	return false;
end

--[[
Filter which only matches players
--]]
Filter.PLAYER = function(value)
	return value:is_player();
end

--[[
Filter which negates another filter
--]]
Filter.NOT = function(value, filter, ...)
	return not Filter.match(filter, value, ...);
end

--[[
Returns whether an object matches a filter
--]]
function Filter.match(filter, obj, ...)
	if not filter then return false end;
	if type(filter) == "table" then
		for k,v in pairs(filter) do
			if v == obj then
				return true;
			end
		end
	elseif type(filter) == "function" then
		return filter(obj, ...);
	end

	return filter == obj;
end

--[[
Returns true if any value in the given table matches a given filter
--]]
function Filter.match_table(filter, t, ...)
	for k, v in pairs(t) do
		if Filter.match(filter, v, ...) then
			return true;
		end
	end

	return false;
end

function Filter.find(filter, t, ...)
	for k,v in pairs(t) do
		if Filter.match(filter, v, ...) then
			return v;
		end
	end
	return nil;
end

return Filter;
