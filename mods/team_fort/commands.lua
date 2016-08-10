--[[
The point of this file is to load all team fort commands
There are two basic commands:
/tf       commands that can be ran by any player, such as joining teams
/tfadmin  commands that can only be ran by admins with the 'tfadmin' priv
--]]

minetest.register_privilege("tfadmin", {
	description = "Can use team fort (/tfadmin) commands",
	give_to_singleplayer = true
})

CommandMaker.register("tf",
	{
		description = "Team Fort commands",
		privs = { interact = true }
	}, {
		join = CommandMaker.command({"string", "?string"},
		function (name, team_name, player_name)
			local name = player_name or name;
			return Scoreboard.Teams.player_join(team_name, name);
		end),
		leave = CommandMaker.command({"?string"},
		function (name, player_name)
			local name = player_name or name;
			return Scoreboard.Teams.player_leave(name);
		end),
	}
)
