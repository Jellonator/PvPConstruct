--[[
Defines a few basic weapons to demonstrate the core abilities of this mod.
Includes:
bow     - shoots arrow projectile
gun     - shoots bullets, leaves decal
shotgun - gun with falloff
rifle   - gun that can headshot
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
	ammo = "designer_weapons:arrow",
	ammo_max = 8,
})

-- pistol
minetest.register_craftitem("designer_weapons:bullet_standard", {
	description = "Bullet",
	inventory_image = "dweapon_bullet_standard.png"
})

-- minetest.register_craft({
-- 	type = "shapeless",
-- 	recipe = {},
-- 	output = "designer_weapons:bullet_standard 6"
-- })

designer_weapons.register_weapon("designer_weapons:gun", "hitscan", {
	description = "Basic pistol",
	inventory_image = "dweapon_pistol.png",
	rate = 3,
	damage = 3,
	sound_shoot = "dweapon_shoot",
	decal = "designer_weapons:decal_bullet",
	ammo = "designer_weapons:bullet_standard",
	ammo_max = 12,
})

designer_weapons.register_decal("designer_weapons:decal_bullet", {
	description = "A bullet hole",
	tiles = {"dweapon_decal_bullet.png"},
})

-- shotgun
minetest.register_craftitem("designer_weapons:bullet_shell", {
	description = "Shotgun shell",
	inventory_image = "dweapon_bullet_shell.png"
})

-- minetest.register_craft({
-- 	type = "shapeless",
-- 	recipe = {},
-- 	output = "designer_weapons:bullet_shell 4"
-- })

designer_weapons.register_weapon("designer_weapons:shotgun", "hitscan", {
	description = "Basic shotgun",
	inventory_image = "dweapon_shotgun.png",
	delay = 0.7,
	damage = 7,
	damage_min = 2,
	falloff = 25,
	falloff_min = 4,
	sound_shoot = "dweapon_shotgun",
	decal = "designer_weapons:decal_shotgun",
	ammo = "designer_weapons:bullet_shell",
	ammo_max = 8,
})

designer_weapons.register_decal("designer_weapons:decal_shotgun", {
	description = "A shotgun hole",
	tiles = {"dweapon_decal_shotgun.png"},
})

-- rifle
minetest.register_craftitem("designer_weapons:bullet_rifle", {
	description = "Rifle bullet",
	inventory_image = "dweapon_bullet_rifle.png"
})

-- minetest.register_craft({
-- 	type = "shapeless",
-- 	recipe = {},
-- 	output = "designer_weapons:bullet_standard 6"
-- })

designer_weapons.register_weapon("designer_weapons:rifle", "hitscan", {
	description = "Basic rifle",
	inventory_image = "dweapon_rifle.png",
	delay = 1.2,
	damage = 8,
	damage_headshot = 12,
	sound_shoot = "dweapon_shoot",
	decal = "designer_weapons:decal_bullet",
	ammo = "designer_weapons:bullet_rifle",
	ammo_max = 8,
})
