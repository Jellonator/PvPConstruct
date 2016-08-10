--nothing here
local function has_clicky_privelege(meta, player)
	local name = ""
	if player then
		if minetest.check_player_privs(player, "protection_bypass") then
			return true
		end
		name = player:get_player_name()
	end
	if name ~= meta:get_string("owner") then
		return false
	end
	return true
end

local clicky_sign_name = "clicky_signs:sign_clickable"
minetest.register_node(clicky_sign_name, {
	description = "Clickable Sign",
	drawtype = "nodebox",
	tiles = {"clicky_signs_sign_wall.png"},
	inventory_image = "clicky_signs_sign.png",
	wield_image = "clicky_signs_sign.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
		wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
		wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
	},
	groups = {cracky = 1, attached_node = 1, dig_immediate = 2},
	legacy_wallmounted = true,
	sounds = default.node_sound_defaults(),

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
	end,
	on_construct = function(pos)
		--local n = minetest.get_node(pos)
		local meta = minetest.get_meta(pos)
		-- meta:set_string("formspec", )
		meta:set_string("infotext", "\"Click me!\"")
		meta:set_string("owner", "")
		meta:set_string("cmd", "")
	end,
	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		if has_clicky_privelege(meta, clicker) then
			print("WOW", meta:get_string("owner"), meta:get_string("cmd"))
			minetest.show_formspec(
				clicker:get_player_name(),
				clicky_sign_name .. pos.x .. ',' .. pos.y .. ',' .. pos.z,
				"field[text;Command;"..meta:get_string("cmd").."]" ..
				"field[info;Infotext;"..meta:get_string("infotext").."]"
			)
		end
	end,
	on_punch = function(pos, node, player, pointed_thing)
		if not player:is_player() then return end
		if player:get_player_control().sneak then return end
		local meta = minetest.get_meta(pos);
		local player_name = player:get_player_name();
		local owner_name = meta:get_string("owner");

		local cmd = meta:get_string("cmd");
		if cmd:sub(1, 1) == '/' then
			cmd = cmd:sub(2);
		end
		cmd = cmd:gsub("@", player_name)
		print("Running command: ", cmd)

		local cmd_name, cmd_value;
		local space_s, space_e = cmd:find("%s");
		if space_s and space_e then
			cmd_name = cmd:sub(1, space_s - 1);
			cmd_value = cmd:sub(space_e + 1);
		else
			cmd_name = cmd;
			cmd_value = "";
		end

		local command_table = minetest.chatcommands[cmd_name];
		if not command_table then
			print("No such command of name " .. cmd_name .. "!");
			return
		end
		if not minetest.check_player_privs(owner_name, command_table.privs) then
			print("Owner of this sign, " .. owner_name .. ", does not have the necessary priveleges to run this command.");
			return;
		end

		command_table.func(player_name, cmd_value);
	end
})

minetest.register_on_player_receive_fields(function(sender, formname, fields)
	if formname:sub(1,clicky_sign_name:len()) ~= clicky_sign_name then
		return
	end
	print("Setting meta!");
	local formdata = formname:sub(string.len(clicky_sign_name) + 1);
	local data = string.split(formdata);
	local pos = {
		x = tonumber(data[1]),
		y = tonumber(data[2]),
		z = tonumber(data[3]),
	}
	print(pos.x, pos.y, pos.z)

	local player_name = sender:get_player_name();
	if minetest.is_protected(pos, player_name) then
		minetest.record_protection_violation(pos, player_name)
		return
	end

	local meta = minetest.get_meta(pos);
	if has_clicky_privelege(meta, sender) then
		if fields.text then
			meta:set_string("cmd", fields.text)
		end
		if fields.info then
			meta:set_string("infotext", fields.info)
		end
	end
	-- meta:set_string("infotext", '"' .. fields.text .. '"')
end)
