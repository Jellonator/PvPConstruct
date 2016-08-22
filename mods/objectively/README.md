Objectively
===========

This is a mod which defines and allows for further definition of objectives for
players to complete.

Usage
-----

In order to manage Objectively, a player must have `objectively_admin`
privileges.

To set the objective of a game, use `/objectively set <objective>`, where
objective is the name of a valid objective.

To see a list of available objectives, use `/objectively list`, and to see which
objective is active, use `/objectively current`.

By default, this mod defines a few useful objectives:
 * deathmatch - A very basic game mode where players kill eachother for points.
 * \_wait - A simple 'objective' that waits a few seconds before setting a different objective.

Lua API
-------

The main use of this mod if so that mod makers can define their own objectives.
To define your own objectives, use `Objectively.register_objective(name, def)`.
The name can be any string containing alphanumeric characters, underscores, and
colons.

```Lua
def = {
	on_enable(self, args...)
	--^ function called when this objective is enabled
	on_disable(self)
	--^ function called when this objective is disabled
	on_reset(self)
	--^ function called when objectives are reset

	on_joinplayer(self, player)
	--^ function called when a player joins
	on_leaveplayer(self, player)
	--^ function called when a player leaves
	on_dieplayer(self, player, killer)
	--^ function called when a player dies

	on_globalstep(self, dtime)
	--^ function called every in-game frame

	get_staticdata(self)
	--^ function called for serializing the objective
	on_loaddata(self, data)
	--^ function called to deserialize the objective
}
```

A few useful functions for managing objectives are also available as well.
```Lua
Objectively.reset()
--^ Resets the active objective.

Objectively.set_objective(name, args...)
--^ Sets the active objective to a new objective.

Objectively.get_objective()
--^ Returns the definition for the active objective.

Objectively.get_id()
--^ Returns the ID for the active objective.
--  Useful for resetting objects when an objective is reset.

Objectively.is_updated(id)
--^ Returns whether the current objective ID has updated since the id given.
```
