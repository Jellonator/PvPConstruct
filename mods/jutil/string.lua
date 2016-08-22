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
	local is_negative = seconds < 0;
	local seconds = math.abs(seconds);
	local hours = math.floor(seconds / 3600);
	seconds = seconds - hours * 3600;
	local minutes = math.floor(seconds / 60);
	seconds = seconds - minutes * 60;
	-- local seconds, milliseconds = math.modf(seconds);
	-- milliseconds = math.floor(milliseconds * 1000);
	local ret = "";
	if is_negative then
		ret = '-'
	end
	if hours > 0 then
		ret = ret .. tostring(hours) .. ":"
	end
	if minutes > 0 then
		ret = ret .. tostring(minutes) .. ":"
		if seconds < 10 then
			ret = ret .. '0';
		end
	end
	if digits and digits > 0 then
		ret = ret .. string.format("%." .. digits .. "f", seconds)
	else
		ret = ret .. string.format("%d", seconds)
	end

	return ret;
end

return String;
