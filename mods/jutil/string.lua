--[[
Sanatize a string for use in a formspec
--]]
local sanatize_badchars = {";", ",", "%[", "%]"}
function string.sanatize(str)
	str = str:gsub("\\", "\\\\");
	for k,v in pairs(sanatize_badchars) do
		str = str:gsub(v, "\\%1");
	end
	return str;
end
