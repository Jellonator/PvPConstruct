status_effect.register_effect("default:speed", {
	applies_to = "player",
	duplicate_method = "copy",
	on_activate = function(self, player)
		local override = player:get_physics_override();
		override.speed = override.speed * 4;
		player:set_physics_override(override);
	end,
	on_deactivate = function(self, player)
		local override = player:get_physics_override();
		override.speed = override.speed / 4;
		player:set_physics_override(override);
	end
})
