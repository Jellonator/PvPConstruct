-- local Table = {};

--[[
Removes all indexes in a table from anther table
--]]
function jutil.remove_indexes(t, indexes)
	-- remove in reverse order so that indexes dont interfere with each other
	table.sort(indexes);
	for i = #indexes, 1, -1 do
		local k = indexes[i];
		table.remove(t, k);
	end
end
