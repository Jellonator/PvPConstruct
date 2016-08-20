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
			new = jutil.cmd.command({"team:string"},
			function(player_name, team_name)
				return Scoreboard.Teams.register_team(team_name, {});
			end, "Creates a new team"),

			setspawn = jutil.cmd.command({"team:string", "x", "y", "z", "radius:?number", "rotation:?yaw"},
			function(player_name, team, x, y, z, r, yaw)
				return Scoreboard.Teams.set_spawn(team, {
					x=x,y=y,z=z,r=r or 0,yaw=yaw or 0});
			end, "Sets a team's spawn"),

			resetspawn = jutil.cmd.command({"team:string"},
			function(player_name, team)
				return Scoreboard.Teams.set_spawn(team, nil);
			end, "Disables spawning at a set location"),

			color = jutil.cmd.command({"team:string", "color"},
			function(player_name, team, color)
				return Scoreboard.Teams.set_color(team, color);
			end, "Sets a team's color"),
		},
		world = {
			setspawn = jutil.cmd.command({"x", "y", "z", "radius:?number", "rotation:?yaw"},
			function(player_name, x, y, z, r, yaw)
				return Scoreboard.Teams.set_spawn(Scoreboard.Teams.NONE_TEAM, {
					x=x,y=y,z=z,r=r or 0,yaw=yaw or 0});
			end, "Sets a world spawn"),

			resetspawn = jutil.cmd.command({},
			function(player_name)
				return Scoreboard.Teams.set_spawn(Scoreboard.Teams.NONE_TEAM, nil);
			end, "Disables spawning at a set location"),
		}
	}
)

jutil.cmd.register("scoreboard",
	{
		description = "Scoreboard commands",
		privs = { interact = true }
	}, {
		team = {
			join = jutil.cmd.command({"team:string", "player:?string"},
			function (name, team_name, player_name)
				local name = player_name or name;
				return Scoreboard.Teams.player_join(team_name, name);
			end, "Join a team"),

			leave = jutil.cmd.command({"player:?string"},
			function (name, player_name)
				local name = player_name or name;
				return Scoreboard.Teams.player_leave(name);
			end, "Leave a team"),
		}
	}
)
