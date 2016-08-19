status_effect.register_effect("default:speed", {
	applies_to = "player",
	duplicate_method = "both",
	on_activate = function(self, player, speed)
		self.speed = speed or 2;
		local override = player:get_physics_override();
		override.speed = override.speed * self.speed;
		player:set_physics_override(override);
	end,
	on_deactivate = function(self, player)
		local override = player:get_physics_override();
		override.speed = override.speed / self.speed;
		player:set_physics_override(override);
	end
})

status_effect.register_effect("default:burning", {
	duplicate_method = "override",
	step_timer = 1.0,
	on_activate = function(self, player, strength)
		self.damage = strength or 1;
	end,
	on_step = function(self, player, dtime)
		player:set_hp(player:get_hp() - self.damage);
	end
})

status_effect.register_effect("default:regeneration", {
	duplicate_method = "override",
	step_timer = 1.0,
	overrides = {"default:burning"},
	on_activate = function(self, player, strength)
		self.step_timer = 1 / (strength or 1);
	end,
	on_step = function(self, player, dtime)
		player:set_hp(player:get_hp() + 1);
	end
})
