--[[
Returns a table with all values that don't match a given filter
--]]
function jutil.table_filter(filter, t, ...)
	local ret = {}
	for k,v in pairs(t) do
		if not jutil.match_filter(filter, v, ...) then
			table.insert(ret, v);
		end
	end
	return ret;
end

--[[
Removes all objects in the given table that match a given filter
--]]
function jutil.table_filter_inplace(filter, t, ...)
	local i = 1;
	while i <= #t do
		local v = t[i];
		if jutil.match_filter(filter, v, ...) then
			table.remove(t, i);
			i = i - 1;
		end
		i = i + 1;
	end

	return t;
end

--[[
Returns whether an object matches a filter
--]]
function jutil.match_filter(filter, obj, ...)
	if not filter then return false end;
	if type(filter) == "table" then
		for k,v in pairs(filter) do
			if v == obj then
				return true;
			end
		end
	else
		return filter(obj, ...);
	end

	return filter == obj;
end

--[[
Returns true if any value in the given table matches a given filter
--]]
function jutil.table_match_filter(filter, t, ...)
	for k, v in pairs(t) do
		if jutil.match_filter(filter, v, ...) then
			return true;
		end
	end

	return false;
end
