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
