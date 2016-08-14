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
	delay = 0.1,
	damage = 6,
	decal = "designer_weapons:decal_bullet"
})

designer_weapons.register_decal("designer_weapons:decal_bullet", {
	description = "A bullet hole",
	tiles = {"dweapon_decal_bullet.png"},
});
