--[[
Defines a few basic weapons to demonstrate the core abilities of this mod.
Includes:
bow - shoots arrow projectile
gun - shoots bullets, leaves decal
shotgun - gun with falloff
--]]

-- Bow and arrow
minetest.register_craftitem("designer_weapons:arrow", {
	description = "An arrow",
	inventory_image = "dweapon_arrow.png"
})

minetest.register_craft({
	type = "shapeless",
	recipe = {"default:stick", "default:paper", "default:flint"},
	output = "designer_weapons:arrow 4"
})

designer_weapons.register_projectile("designer_weapons:arrow", {
	collisionbox = {-0.15,-0.15,-0.15, 0.15,0.15,0.15},
	textures = {"dweapon_arrow.png"},
	gravity = -8,
	speed = 20,
	life = 10,
	damage = 4,
})

designer_weapons.register_weapon("designer_weapons:bow", "projectile", {
	entity_name = "designer_weapons:arrow",
	description = "Bow and Arrow",
	inventory_image = "dweapon_bow.png",
	delay = 0.5,
	ammo = "designer_weapons:arrow"
})

-- Shotguns and pistols
designer_weapons.register_weapon("designer_weapons:gun", "hitscan", {
	description = "Basic pistol",
	inventory_image = "dweapon_pistol.png",
	rate = 3,
	damage = 3,
	sound_shoot = "dweapon_shoot",
	decal = "designer_weapons:decal_bullet"
})

designer_weapons.register_weapon("designer_weapons:shotgun", "hitscan", {
	description = "Basic shotgun",
	inventory_image = "dweapon_shotgun.png",
	delay = 0.7,
	damage = 7,
	damage_min = 2,
	falloff = 25,
	falloff_min = 4,
	sound_shoot = "dweapon_shotgun",
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
