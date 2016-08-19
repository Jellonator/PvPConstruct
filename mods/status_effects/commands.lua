minetest.register_privilege("can_apply_status", {
	description = "Can apply status effects with the /effect command"
})

jutil.cmd.register("effect",
	{
		description = "Apply an effect to a player",
		privs = { can_apply_status = 1 }
	}, {
		apply = jutil.cmd.command({"effect:string", "duration:number", "strength:?number", "player:?string"},
		function(player_name, effect_name, duration, strength, given_player_name)
			local player_name = given_player_name or player_name;
			local player = minetest.get_player_by_name(player_name);
			if not player then return false, "No such player " .. player_name .. "!"; end
			return status_effect.apply_effect(effect_name, player, duration, strength);
		end, "Applies an effect to a player.")
	}
)
