CommandMaker = {}

local function get_param_next(param, type_name)
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
	elseif type_name == "text" then
		return param, "";
	else
		error("No such type name of '" .. type_name .. "'!");
	end

	return ret, new_param;
end

local function do_command(name, param, cmd, full_cmd)
	param = string.trim(param);
	local argname, new_param = get_param_next(param, "string");
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

	return false, "Invalid command '/" .. string.trim(full_cmd) .. "'"
end

function CommandMaker.register(name, def, cmd)
	local full_cmd = name;
	def.func = function(name, param)
		print("Starting a command");
		return do_command(name, param, cmd, full_cmd);
	end
	minetest.register_chatcommand(name, def);
end

local function full_cmd_fmt(full_cmd, def)
	full_cmd = string.trim(full_cmd);
	local def_str = "";
	for i, v in pairs(def) do
		if i ~= 1 then
			def_str = def_str .. " "
		end
		def_str = def_str .. "{" .. tostring(v) .. "}"

	end
	return string.format("Invalid arguments to '/%s'! Expected: '/%s %s'",
		full_cmd, full_cmd, table.concat(def, " ")
	);
end

function CommandMaker.command(def, func)
	local is_optional = false;
	local minimum_argn = 0;
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
		print("Doing a command thing!");
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
			next_arg, param = get_param_next(param, param_type);
			if next_arg == nil then
				if is_optional then break end
				return false, full_cmd_fmt(full_cmd, def)
			end
			table.insert(args, next_arg);
		end

		local actual_argn = #args;
		if actual_argn < minimum_argn or actual_argn > expected_argn then
			return false, full_cmd_fmt(full_cmd, def)
		end

		return func(name, unpack(args));
	end
end

--[[
example:
CommandMaker.register("cmd",
	{
		description = "whatever",
		privs = { interact = true }
	},
	{
		foo = CommandMaker.command({"number"}, function(name, value)
			return true, "Number: " .. value
		end),
		bar = CommandMaker.command({"string", "?number"}, function(name, a, b)
			return true, "Player <" .. name .. "> called bar with args: " .. a .. " " .. tostring(b)
		end)
	}
)
]]
