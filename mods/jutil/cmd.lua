local cmd = {}

--[[
Type names:
string - string with no spaces
text   - string that can contain spaces, no arguments can come after
number - represents a number
color  - represents a color
x   - x position
y   - y position
z   - z position
yaw - yaw rotation
--]]

local function get_param_next(param, type_name, player_name)
	local space_start, space_end = string.find(param, "%s");
	if space_end == nil then
		space_end = space_start
	end

	local ret, new_param;
	if space_start == nil then
		ret = param;
		new_param = "";
	else
		ret, new_param = param:sub(1, space_start-1), param:sub(space_end+1);
	end

	if type_name == "string" then
		ret = ret
	elseif type_name == "number" then
		ret = tonumber(ret)
	elseif type_name == "x" or type_name == "y" or type_name == "z" or
	 		type_name == "yaw" then
		local relative = false;
		if ret:sub(1, 1) == "~" then
			relative = true;
			ret = ret:sub(2);
		end
		ret = ret == "" and 0 or tonumber(ret);
		if relative and ret then
			local playerref = minetest.get_player_by_name(player_name);
			if not playerref then return nil, new_param end
			local playerpos = playerref:getpos();

			if     type_name == 'x' then ret = ret + playerpos.x
			elseif type_name == 'y' then ret = ret + playerpos.y
			elseif type_name == 'z' then ret = ret + playerpos.z
			elseif type_name == 'yaw' then ret = ret + playerref:get_look_yaw() end
		end
	elseif type_name == "text" then
		return param, "";
	elseif type_name == "color" then
		ret = jutil.color[ret] or tonumber(ret)
	else
		error("No such type name of '" .. type_name .. "'!");
	end

	return ret, new_param;
end

local function do_command(name, param, cmd, full_cmd)
	param = string.trim(param);
	local argname, new_param = get_param_next(param, "string");
	local prev_cmd = full_cmd
	full_cmd = full_cmd .. " " .. argname;
	for k, v in pairs(cmd) do
		if k == argname then
			if type(v) == "table" then
				return do_command(name, new_param, v, full_cmd);
			elseif type(v) == "function" then
				return v(name, new_param, full_cmd);
			end
		end
	end

	return false, "/" .. string.trim(prev_cmd) .. ": Invalid command '/" .. string.trim(full_cmd) .. "'"
end

local function cmd_fmt(full_cmd, def)
	full_cmd = string.trim(full_cmd);
	local def_str = "";
	for i, v in pairs(def) do
		if i ~= 1 then def_str = def_str .. " "; end
		def_str = def_str .. "{" .. tostring(v) .. "}"
	end

	return string.format("/%s %s",
		full_cmd, def_str
	);
end

local function err_cmd_fmt(full_cmd, def)
	full_cmd = string.trim(full_cmd);
	return string.format("Invalid arguments to '/%s'! Expected: '%s'",
		full_cmd, cmd_fmt(full_cmd, def)
	);
end

local function gen_description(def, cmd, full_cmd)
	for k,v in pairs(cmd) do
		local next_cmd = full_cmd .. ' ' .. k;
		if type(v) == "function" then
			local cmd_str, desc = v();
			def.description = def.description .. "\n\t/" ..
				next_cmd .. cmd_str;
			if desc then
				def.description = def.description .. " - " .. desc;
			end
		else
			gen_description(def, v, next_cmd)
		end
	end
end

function cmd.register(name, def, cmd)
	local full_cmd = name;
	def.description = def.description or ""
	def.func = function(name, param)
		print("Starting a command");
		return do_command(name, param, cmd, full_cmd);
	end

	gen_description(def, cmd, name);

	minetest.register_chatcommand(name, def);
end

function cmd.command(def, func, desc)
	local is_optional = false;
	local minimum_argn = #def;

	local cmd_str = "";
	for i, v in ipairs(def) do
		cmd_str = cmd_str .. ' ';

		local colon_loc = v:find(":");
		local name;
		if colon_loc then
			name = v:sub(1, colon_loc - 1);
			def[i] = v:sub(colon_loc+1);
			v = def[i];
		else
			name = v;
		end

		local optional = v:sub(1,1) == "?";
		if optional and not colon_loc then
			name = v:sub(2)
		end

		if optional then
			cmd_str = cmd_str .. '[' .. name .. ']';
		else
			cmd_str = cmd_str .. '<' .. name .. '>';
		end
	end

	for i, v in ipairs(def) do
		local new_optional = v:sub(1, 1) == "?";
		if not is_optional and new_optional then
			is_optional = true;
			minimum_argn = i - 1;
		elseif is_optional and not new_optional then
			error("All optional parameters must come at the end of a command definition!")
		end
	end
	return function(name, param, full_cmd)
		-- Welp, there's no other way to get it from a function other than this
		if name == nil and param == nil and full_cmd == nil then
			return cmd_str, desc;
		end

		-- print("Doing a command thing!");
		local args = {}
		local expected_argn = #def;

		for i,v in ipairs(def) do
			param = string.trim(param);
			if param == "" then
				break
			end
			local next_arg;
			local param_type = v;
			local is_optional = false;
			if param_type:sub(1, 1) == "?" then
				is_optional = true;
				param_type = param_type:sub(2);
			end
			next_arg, param = get_param_next(param, param_type, name);
			if next_arg == nil then
				if is_optional then break end
				return false, err_cmd_fmt(full_cmd, def)
			end
			table.insert(args, next_arg);
		end

		local actual_argn = #args;
		if actual_argn < minimum_argn or actual_argn > expected_argn then
			return false, err_cmd_fmt(full_cmd, def)
		end
		print("func", name, #args, minimum_argn, expected_argn)
		return func(name, unpack(args));
	end
end

--[[
example:
cmd.register("cmd",
	{
		description = "whatever",
		privs = { interact = true }
	},
	{
		foo = cmd.command({"number"}, function(name, value)
			return true, "Number: " .. value
		end),
		bar = cmd.command({"string", "?number"}, function(name, a, b)
			return true, "Player <" .. name .. "> called bar with args: " .. a .. " " .. tostring(b)
		end)
	}
)
]]

return cmd;
