--[[
The point of this file is to load all team fort commands
There are two basic commands:
/scoreboard       commands that can be ran by any player, such as joining teams
/scoreadmin  commands that can only be ran by admins with the 'tfadmin' priv
--]]

minetest.register_privilege("scoreboard_admin", {
	description = "Can use team fort (/tfadmin) commands",
	give_to_singleplayer = true
})

jutil.cmd.register("scoreadmin",
	{
		description = "Scoreboard admin commands",
		privs = { scoreboard_admin = 1 }
	}, {
		team = {
			new = jutil.cmd.command({"string"},
			function(player_name, team_name)
				return Scoreboard.Teams.register_team(team_name, {});
			end),

			setspawn = jutil.cmd.command({"string", "x", "y", "z", "?number", "?yaw"},
			function(player_name, team, x, y, z, r, yaw)
				print("YAW: ", yaw)
				return Scoreboard.Teams.set_spawn(team, {
					x=x,y=y,z=z,r=r or 0,yaw=yaw or 0});
			end),

			resetspawn = jutil.cmd.command({"string"},
			function(player_name, team)
				return Scoreboard.Teams.set_spawn(team, nil);
			end),

			color = jutil.cmd.command({"string", "color"},
			function(player_name, team, color)
				return Scoreboard.Teams.set_color(team, color);
			end),
		}
	}
)

jutil.cmd.register("scoreboard",
	{
		description = "Scoreboard commands",
		privs = { interact = true }
	}, {
		team = {
			join = jutil.cmd.command({"string", "?string"},
			function (name, team_name, player_name)
				local name = player_name or name;
				return Scoreboard.Teams.player_join(team_name, name);
			end),

			leave = jutil.cmd.command({"?string"},
			function (name, player_name)
				local name = player_name or name;
				return Scoreboard.Teams.player_leave(name);
			end),
		}
	}
)
