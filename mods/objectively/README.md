Objectively
===========

This is a mod which defines and allows for further definition of objectives for
players to complete.

Lua API
-------
```
def = {
	on_enable -- function called when this objective is enabled
	on_disable -- function called when this objective is disabled
	on_reset -- function called when objectives are reset

	on_joinplayer -- function called when a player joins
	on_leaveplayer -- function called when a player leaves
	on_dieplayer -- function called when a player dies

	get_staticdata -- function called for serializing the objective
	on_loaddata -- function called to deserialize the objective
}
```
