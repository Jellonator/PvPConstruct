local Table = {};

--[[
Removes all indexes in a table from anther table
--]]
function Table.remove_indexes(t, indexes)
	-- remove in reverse order so that indexes dont interfere with each other
	table.sort(indexes);
	for i = #indexes, 1, -1 do
		local k = indexes[i];
		table.remove(t, k);
	end
end

--[[
Returns a table with all values that don't match a given filter
--]]
function Table.filter(filter, t, ...)
	local ret = {}
	for k,v in pairs(t) do
		if not jutil.filter.match(filter, v, ...) then
			table.insert(ret, v);
		end
	end
	return ret;
end

--[[
Removes all objects in the given table that match a given filter
--]]
function Table.filter_inplace(filter, t, ...)
	local i = 1;
	while i <= #t do
		local v = t[i];
		if jutil.filter.match(filter, v, ...) then
			table.remove(t, i);
			i = i - 1;
		end
		i = i + 1;
	end

	return t;
end

return Table;
