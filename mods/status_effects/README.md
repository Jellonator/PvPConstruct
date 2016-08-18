Status effect mod for Minetest and PvPConstruct

How to define a status effect:
```Lua
status_effect.register_effect("mod_name:status_effect_name", def);
```

How to apply a status effect:
```Lua
status_effect.apply_effect("mod_name:status_effect_name", player, time);
```

Status effect definition:
```
def = {
	overrides -- Status effects that will be removed when applied.

	conflicts -- This status won't be applied if this effect is already active.

	duplicate_method -- Method that this status effect will use if applied again
			--     Possible modes:
			-- "override", overrides the original, uses longest length (default)
			-- "reset", resets the timer of the original, but not the data
			-- "both", use both the original and the new effect at the same time
			-- function(a, b), use a function and return the mode(s) to use

	applies_to = "all" -- If set to "player", this status will only affect
			players. If set to "object", this status will only affect
			LuaEntitySAO objects.

	on_activate(self, object) -- Function that will be called when the status
			-- effect is first applied or the player logs in.

	on_deactivate(self, object) -- Function that will be called when the status
	 		-- effect ends.

	on_step(self, object, dtime) -- Function that will be called every frame.

	-- anything else defined will be used by self
}
```

Example:
```Lua
status_effect.register_effect("my_mod:burning", {
	duplicate_method = "override",
	overrides = {"my_mod:freezing"}, -- player no longer freezes
	conflicts = {"my_mod:wet"}, -- player can not burn while wet
	timer = 0;
	on_step = function(self, object, dtime)
		self.timer = self.timer + dtime;
		-- lose two health per second
		if self.timer > 0.5 then
			object:set_hp(object:get_hp() - 1);
		end
	end
})
```
