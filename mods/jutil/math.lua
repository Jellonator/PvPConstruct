local Math = {}

--[[
Rounds a number to the nearest 'mult'
--]]
function math.round(num, mult)
	local mult = mult or 1;
	return math.floor(num / mult + 0.5) * mult
end

--[[
returns both the minimum and the maximum of a set of values
--]]
function math.minmax(...)
	return math.min(...), math.max(...);
end

--[[
Limits the value of 'value' to the bounds of [min,max]
--]]
function Math.clamp(value, min, max)
	min, max = math.minmax(min, max);
	if (value < min) then return min end
	if (value > max) then return max end
	return value;
end

--[[
Returns a value between a and b, where a value of 0 is a and a value of 1 is b
--]]
function Math.lerp(value, a, b)
	return Math.normalize(value, 0, 1, a, b);
end

--[[
Converts a number from one scale to another.
Example:
celcius = Math.normalize(fahrenheit, 32, 212, 0, 100, false);
--]]
function Math.normalize(value, min, max, to_min, to_max, clamp)
	if to_min == to_max then return to_min end
	if clamp == nil then clamp = true end
	local a = (to_max - to_min) / (max - min);
	local b = to_max - a * max;
	value = a * value + b;
	if clamp then return Math.clamp(value, to_min, to_max) end
	return value;
end

--[[
Better mod function than the default
--]]
function Math.mod(a, n)
	return a - math.floor(a/n) * n
end

--[[
Find the difference between two angles
--]]
function Math.angle_diff(a, b)
	local ret = a - b;
	ret = Math.mod(ret + math.pi, math.pi*2) - math.pi
	return ret;
end

--[[
Tween an angle from 'from' to 'to', changing at most as much as 'speed'
--]]
function Math.angle_to(from, to, speed)
	local diff = Math.angle_diff(to, from);
	if math.abs(diff) < speed then return to end
	diff = diff * speed / math.abs(diff);
	from = from + diff;
	return Math.mod(from, math.pi*2);
end

return Math
