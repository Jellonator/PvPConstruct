--[[
Attempts to recreate some of the weapons found in team fortress 2
--]]

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
	decal = "team_fort:decal_explosion"
})

designer_weapons.register_weapon("team_fort:rocket_launcher", "projectile", {
	entity_name = "team_fort:rocket",
	description = "Rocket Launcher",
	inventory_image = "teamf_weapon_rocketlauncher.png",
	delay = 0.9,
})

designer_weapons.register_decal("team_fort:decal_explosion", {
	description = "Remains of an explosion long past",
	tiles = {"teamf_decal_explosion.png"},
});
