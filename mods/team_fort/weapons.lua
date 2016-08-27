--[[
Attempts to recreate some of the weapons found in team fortress 2
--]]

-- rocket launcher
local ROCKET_LAUNCHER_BOOST = 1;
status_effect.register_effect("team_fort:rocket_jump", {
	applies_to = "player",
	duplicate_method = "override",
	on_activate = function(self, player, speed)
		local speed = speed or 1;
		self.speed = speed;

		local override = player:get_physics_override();
		self.pgrav = override.gravity;
		override.speed = override.speed * (ROCKET_LAUNCHER_BOOST + self.speed * 0.5);
		override.gravity = -speed;
		player:set_physics_override(override);
	end,
	on_deactivate = function(self, player)
		local override = player:get_physics_override();
		override.gravity = self.pgrav;
		override.speed = override.speed / (ROCKET_LAUNCHER_BOOST + self.speed * 0.5);
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
	delay = 1.0,
	ammo = "team_fort:rocket",
	ammo_max = 12
})

designer_weapons.register_decal("team_fort:decal_explosion", {
	description = "Remains of an explosion long past",
	tiles = {"teamf_decal_explosion.png"},
});


-- grenade launcher
minetest.register_craftitem("team_fort:grenade_ammo", {
	description = "A grenade",
	inventory_image = "teamf_projectile_grenade.png"
})

designer_weapons.register_projectile("team_fort:grenade", {
	collisionbox = {-0.2,-0.2,-0.2, 0.2,0.2,0.2},
	textures = {"teamf_projectile_grenade.png"},
	gravity = -9.8,
	speed = 8,
	life = 4,
	damage = 8,
	damage_min = 4,
	blast_radius = 2.5,
	explode = true,
	sound_hit = "tnt_explode",
	decal = "team_fort:decal_explosion",
	status_effects = {"team_fort:rocket_jump 0.1 3"},
	roll_time = 1.0,
	bounce = 0.5,
})

designer_weapons.register_weapon("team_fort:grenade_launcher", "projectile", {
	entity_name = "team_fort:grenade",
	description = "Grenade Launcher",
	inventory_image = "teamf_weapon_grenadelauncher.png",
	delay = 1.1,
	ammo = "team_fort:grenade_ammo",
	ammo_max = 10
})

-- healing crossbow
minetest.register_craftitem("team_fort:healing_arrow", {
	description = "A healing arrow",
	inventory_image = "teamf_projectile_healingarrow.png"
})

designer_weapons.register_projectile("team_fort:healing_arrow", {
	collisionbox = {-0.15,-0.15,-0.15, 0.15,0.15,0.15},
	textures = {"teamf_projectile_healingarrow.png"},
	gravity = -8,
	speed = 20,
	life = 10,
	damage = 4,
	healing = 5,
	on_hit = function(self, owner, entity, damage)
		if not owner:is_player() or not entity:is_player() then
			return damage;
		end
		local owner_name = owner:get_player_name();
		local entity_name = entity:get_player_name();
		local owner_team = Teammake.player_get_team(owner_name);
		local entity_team = Teammake.player_get_team(entity_name);
		-- when shooter is not on a team or both the player and the entity are
		-- on the same team, use healing
		if not owner_team or entity_team == owner_team then
			entity:set_hp(entity:get_hp() + self.healing);
			return;
		end
		return damage;
	end,
})

designer_weapons.register_weapon("team_fort:healing_crossbow", "projectile", {
	entity_name = "team_fort:healing_arrow",
	description = "Healing Crossbow",
	inventory_image = "teamf_weapon_healingcrossbow.png",
	delay = 1.2,
	ammo = "team_fort:healing_arrow",
	ammo_max = 8
})

-- minigun
designer_weapons.register_weapon("team_fort:minigun", "hitscan", {
	description = "Minigun",
	inventory_image = "dweapon_shotgun.png",
	rate = 10,
	damage = 4,
	damage_min = 1,
	falloff = 9,
	falloff_min = 2,
	sound_shoot = "dweapon_shoot",
	decal = "designer_weapons:decal_bullet",
	ammo = "designer_weapons:bullet_standard",
	ammo_max = 50,
	automatic = true,
})
