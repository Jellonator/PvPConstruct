local direction = {}

direction.NORTH = 1
direction.EAST = 2
direction.SOUTH = 3
direction.WEST = 4

local function _mod(a, n)
	return a - math.floor(a/n) * n
end

function direction.from_yaw(yaw)
	yaw = jutil.mod(yaw, math.pi * 2);
	yaw = yaw + math.pi / 4;
	if yaw < math.pi / 2 then
		return direction.NORTH;
	elseif yaw < math.pi then
		return direction.WEST;
	elseif yaw < math.pi * 3 / 2 then
		return direction.SOUTH;
	elseif yaw < math.pi * 2 then
		return direction.EAST;
	else
		return direction.NORTH;
	end
end

function direction.decompose(dir)
	if dir == direction.NORTH then
		return 0, 1
	elseif dir == direction.EAST then
		return 1, 0
	elseif dir == direction.SOUTH then
		return 0, -1
	elseif dir == direction.WEST then
		return -1, 0
	end
	return 0, 0;
end

function direction.to_pos(dir)
	if dir == direction.NORTH then
		return {x =  0, y = 0, z =  1}
	elseif dir == direction.EAST then
		return {x =  1, y = 0, z =  0}
	elseif dir == direction.SOUTH then
		return {x =  0, y = 0, z = -1}
	elseif dir == direction.WEST then
		return {x = -1, y = 0, z =  0}
	end
	return {x=0,y=0,z=0};
end

function direction.left(dir)
	local ret = dir - 1;
	if ret < 1 then
		ret = 4
	end
	return ret;
end

function direction.right(dir)
	local ret = dir + 1;
	if ret > 4 then
		ret = 1
	end
	return ret;
end

return direction;
