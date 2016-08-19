--[[
Attempts to recreate some of the weapons found in team fortress 2
--]]

-- rocket launcher
status_effect.register_effect("team_fort:rocket_jump", {
	applies_to = "player",
	duplicate_method = "override",
	on_activate = function(self, player, speed)
		local speed = speed or 1;
		local override = player:get_physics_override();
		self.pgrav = override.gravity;
		override.gravity = -speed;
		player:set_physics_override(override);
	end,
	on_deactivate = function(self, player)
		local override = player:get_physics_override();
		override.gravity = self.pgrav;
		player:set_physics_override(override);
	end
})

minetest.register_craftitem("team_fort:rocket", {
	description = "A rocket",
	inventory_image = "teamf_projectile_rocket.png"
})

minetest.register_craft({
	recipe = jutil.recipe_format({
		{0, 3, 0},
		{3, 1, 3},
		{2, 4, 2}
	}, {"fire:flint_and_steel", "tnt:gunpowder", "default:steel_ingot", "default:copper_ingot"}),
	output = "team_fort:rocket 3"
})

designer_weapons.register_projectile("team_fort:rocket", {
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	textures = {"teamf_projectile_rocket.png"},
	gravity = 0,
	speed = 10,
	life = 10,
	damage = 6,
	damage_min = 2,
	blast_radius = 2.5,
	explode = true,
	sound_hit = "tnt_explode",
	decal = "team_fort:decal_explosion",
	status_effects = {"team_fort:rocket_jump 0.1 5"}
})

designer_weapons.register_weapon("team_fort:rocket_launcher", "projectile", {
	entity_name = "team_fort:rocket",
	description = "Rocket Launcher",
	inventory_image = "teamf_weapon_rocketlauncher.png",
	delay = 0.9,
	ammo = "team_fort:rocket",
	ammo_max = 8
})

designer_weapons.register_decal("team_fort:decal_explosion", {
	description = "Remains of an explosion long past",
	tiles = {"teamf_decal_explosion.png"},
});
