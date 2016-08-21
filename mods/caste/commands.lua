minetest.register_privilege("caste_admin", {
	description = "Can use caste admin (/casteadmin) commands",
	give_to_singleplayer = true
})

local CLASS_SELECT_FORMSPEC_NAME = "caste.class.selection";
local function gen_class_formspec()
	local classes = Caste.class.class_data;
	local ret = "size[8," .. tostring(#classes + 1) .. "]";
	local y_pos = 1;
	if #classes == 0 then
		return;
	end
	for name, def in pairs(classes) do
		ret = ret .. "button_exit[0," .. tostring(y_pos) .. ";3,1;" .. name ..
				";" .. name .. "]";
		y_pos = y_pos + 1;
	end
	-- "button_exit[0,1;3,1;aaa;A]" ..
	-- "button_exit[0,2;3,1;bbb;B]" ..
	-- "button_exit[0,3;3,1;ccc;C]";

	return ret;
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= CLASS_SELECT_FORMSPEC_NAME then
		return
	end

	for k,v in pairs(fields) do
		minetest.chat_send_all(tostring(k) .. ": " .. tostring(v));
	end
end)

jutil.cmd.register("casteadmin",
	{
		description = "Caste admin commands",
		privs = { caste_admin = 1 }
	}, {
		new = jutil.cmd.command({"name:string"},
		function(_, name)
			return Caste.class.register(name);
		end, "Creates a new class"),

		item = {
			add = jutil.cmd.command({"class:string", "item:string", "count:?number"},
			function(_, class, item, count)
				return Caste.class.add_item(class, item, count);
			end, "Adds an item to a class' definition."),

			remove = jutil.cmd.command({"class:string", "item:string"},
			function(_, class, item)
				return Caste.class.remove_item(class, item);
			end, "Removes an item from a class' definition")
		},

		effect = {
			add = jutil.cmd.command({"class:string", "effect:string", "strength:?number"},
			function(_, class, effect, strength)
				return Caste.class.add_effect(class, effect, strength);
			end, "Adds a status effect to a class' definition."),

			remove = jutil.cmd.command({"class:string", "effect:string"},
			function(_, class, effect)
				return Caste.class.remove_effect(class, effect);
			end, "Removes an item from a class' definition.")
		}
	}
)

jutil.cmd.register("caste",
	{
		description = "Caste commands",
		privs = { interact = 1 }
	}, {
		set = jutil.cmd.command({"class:string", "player:?string"},
		function(player_name, class, player_given)
			player_name = player_given or player_name
			return Caste.player.join(player_name, class)
		end, "Set a player's class"),

		remove = jutil.cmd.command({"player:?string"},
		function(player_name, player_given)
			player_name = player_given or player_name
			return Caste.player.leave(player_name, class)
		end, "Remove a player's class"),

		info = jutil.cmd.command({"class:string"},
		function(player, class)
			local class_data = Caste.class.get(class);
			if not class_data then
				return false, "No such class!";
			end
			local ret = "Name: " .. class;
			local class_items = Caste.class.list_items(class, '\t');
			if class_items then
				ret = ret .. '\nItems:\n' .. class_items;
			end

			local class_effects = Caste.class.list_effects(class, '\t');
			if class_effects then
				ret = ret .. '\nEffects:\n' .. class_effects;
			end
			return true, ret;
		end, "Prints out a class' info"),

		select = jutil.cmd.command({"player:?string"},
		function(player_name, given_player)
			local player_name = given_player or player_name;
			local player = minetest.get_player_by_name(player_name);
			if not player then
				return false, "That player is not online!"
			end
			local form = gen_class_formspec();
			if form then
				minetest.show_formspec(player_name, CLASS_SELECT_FORMSPEC_NAME, form);
			else
				return false, "No classes to select from!"
			end
		end)
	}
)
