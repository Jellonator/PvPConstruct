Status effect mod for Minetest and PvPConstruct

Basics
======

From in the game, you can apply status effects with the `/effect` command, like
so:
```
/effect apply effect_name duration strength player_name
```
e.g.
```
/effect apply default:burning 5 2 singleplayer
```

This mod defines a few basic basic status effects:

 * default:burning - player will take continual damage over time
 * default:speed - speeds up or down the player based on its strength
 * default:regeneration - player will heal over time

Lua API
=======

How to define a status effect:
```Lua
status_effect.register_effect("mod_name:status_effect_name", def);
```

How to apply a status effect:
```Lua
status_effect.apply_effect("mod_name:status_effect_name", player, time,
		strength);
```

Status effect definition:
```Lua
def = {
	overrides -- Status effects that will be removed when applied.

	conflicts -- This status won't be applied if this effect is already active.

	duplicate_method -- Method that this status effect will use if applied again
	                 --     Possible modes:
	                 -- "override" - overrides the original
	                 -- "reset"    - resets the timer of the original
	                 -- "both"     - allow both effects to coexist
	                 -- function   - use a function

	applies_to = "all" -- What type of objects this status will affect.
	                   --     Possible values:
	                   -- "player" - will only affect players
	                   -- "object" - will only affect LuaEntitySAO objects

	step_timer = nil -- If set, will only call step every 'step_time' seconds.

	remove_on_death = true -- Whether or not this effect should be removed when
	                       -- the player dies.

	on_activate(self, object) -- Function that will be called when the status
	                          -- effect is first applied or the player logs in.

	on_deactivate(self, object) -- Function that will be called when the status
	                            -- effect ends.

	on_step(self, object, dtime) -- Function that will be called every frame.
}
```

When duplicate_method is set to a function, the new status effect is passed
first, while all current status effects are passed as well. The function should
return which effect(s) to use.

Example of duplicate_method which returns all status effects passed to it with
all times divided by two except for the first:
```
function def.duplicate_method(first, ...)
	for k,v in pairs({...}) do
		v.time = v.time / 2;
	end

	return first, ...;
end
```

Example of a status effect for burning, in case you want to define your own:
```Lua
status_effect.register_effect("my_mod:burning", {
	duplicate_method = "override",
	overrides = {"my_mod:freezing"}, -- player no longer freezes
	conflicts = {"my_mod:wet"}, -- player can not burn while wet
	step_timer = 0.5;
	on_step = function(self, object, dtime)
		-- lose two health per second
		object:set_hp(object:get_hp() - 1);
	end
})
```
