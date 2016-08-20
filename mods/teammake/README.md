Teammake
========

This mod is used to place players into teams.

How to use
----------

This mod defines two commands, `/team` and `/teamadmin`.

#### /team
Any player with interact privileges can use `/team`.

`/team join <teamname> [playername]` will cause the player to join a team.

`/team leave [playername]` will cause the player to leave their team.

Use `/help team` for more information.

#### /teamadmin
Only players with the 'teammake_admin' privilege can use the `/teamadmin`
command.

Use `/help teamadmin` for more information on how to use this command.

Basics
------

A team defines a set of rules for the players that are in them. A player on a
team can not damage other players on their team. When a player dies, that
player respawns at a team-defined respawn location. Teams also have colors that
show up on their nameplate.

There is a special '\_\_NONE\_\_' team that refers to players not on a team.
Players not on a team can still damage other players that are not on a team.
For convenience, admins can use the `/teamadmin world` commands to set
properties for this team.
