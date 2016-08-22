local String = {}

--[[
Sanatize a string for use in a formspec
--]]
local sanatize_badchars = {";", ",", "%[", "%]"}
function String.sanatize(str)
	str = str:gsub("\\", "\\\\");
	for k,v in pairs(sanatize_badchars) do
		str = str:gsub(v, "\\%1");
	end
	return str;
end

function String.fmt_seconds(seconds, digits)
	local seconds = math.max(0, seconds);
	local hours = math.floor(seconds / 3600);
	seconds = seconds - hours * 3600;
	local minutes = math.floor(seconds / 60);
	seconds = seconds - minutes * 60;
	-- local seconds, milliseconds = math.modf(seconds);
	-- milliseconds = math.floor(milliseconds * 1000);
	local ret = "";
	if hours > 0 then
		ret = tostring(hours) .. ":"
	end
	if minutes > 0 then
		ret = ret .. tostring(minutes) .. ":"
	end
	if digits and digits > 0 then
		ret = ret .. string.format("%." .. digits .. "f", seconds)
	else
		ret = ret .. string.format("%d", seconds)
	end

	return ret;
end

return String;
