--[[
Attempts to recreate some of the weapons found in team fortress 2
--]]

designer_weapons.register_projectile("team_fort:rocket", {
	collisionbox = {-0.3,-0.3,-0.3, 0.3,0.3,0.3},
	textures = {"teamf_projectile_rocket.png"},
	gravity = 0,
	speed = 10,
	life = 15,
	damage = 9,
	explode = true,
	visual_size = {x = 0.8, y = 0.8}
})

designer_weapons.register_weapon("team_fort:rocket_launcher", "projectile", {
	entity_name = "team_fort:rocket",
	description = "Rocket Launcher",
	inventory_image = "teamf_weapon_rocketlauncher.png",
	delay = 0.5,
})
