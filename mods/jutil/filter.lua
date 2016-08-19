local Filter = {};

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
		if Filter.match_filter(filter, v, ...) then
			return true;
		end
	end

	return false;
end

return Filter;
