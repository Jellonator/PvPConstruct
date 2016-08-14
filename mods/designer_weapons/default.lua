designer_weapons.register_projectile("designer_weapons:arrow", {
	visual = "sprite",
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	textures = {"dweapon_arrow.png"},
	gravity = -5,
	speed = 14,
	life = 15,
	damage = 8,
	visual_size = {x = 0.4, y = 0.4}
})

designer_weapons.register_weapon("designer_weapons:bow", "projectile", {
	entity_name = "designer_weapons:arrow",
	description = "Bow and Arrow",
	inventory_image = "dweapon_bow.png",
	delay = 0.4,
})

designer_weapons.register_weapon("designer_weapons:gun", "hitscan", {
	description = "Basic pistol",
	inventory_image = "dweapon_pistol.png",
	rate = 5,
	damage = 4,
	decal = "designer_weapons:decal_bullet"
})

designer_weapons.register_weapon("designer_weapons:shotgun", "hitscan", {
	description = "Basic shotgun",
	inventory_image = "dweapon_shotgun.png",
	rate = 2,
	damage = 8,
	damage_min = 2,
	falloff = 25,
	falloff_min = 5,
	decal = "designer_weapons:decal_shotgun"
})

designer_weapons.register_decal("designer_weapons:decal_bullet", {
	description = "A bullet hole",
	tiles = {"dweapon_decal_bullet.png"},
});

designer_weapons.register_decal("designer_weapons:decal_shotgun", {
	description = "A shotgun hole",
	tiles = {"dweapon_decal_shotgun.png"},
});