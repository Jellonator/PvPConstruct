minetest.register_privilege("caste_admin", {
	description = "Can use caste admin (/casteadmin) commands",
	give_to_singleplayer = true
})

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
			end),

			remove = jutil.cmd.command({"class:string", "item:string"},
			function(_, class, item)
				return Caste.class.remove_item(class, item);
			end)
		},

		effect = {
			add = jutil.cmd.command({"class:string", "effect:string", "strength:?number"},
			function(_, class, effect, strength)
				return Caste.class.add_effect(class, effect, strength);
			end),

			remove = jutil.cmd.command({"class:string", "effect:string"},
			function(_, class, effect)
				return Caste.class.remove_effect(class, effect);
			end)
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
		end, "Prints out a class' info")
	}
)
