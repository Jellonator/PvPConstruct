designer_weapons = {
	registered_weapons = {},
	registered_projectiles = {},
	registered_decals = {},
	TYPES = {
		hitscan = "hitscan",
		projectile = "projectile",
		melee = "melee"
	}
}

local function damage_entity(self, owner, entity, damage)
	local dmgdata = {damage_groups={fleshy=damage}}
	if self.on_hit then
		damage = self.on_hit(self, owner, entity, damage);
	end
	if damage then
		entity:punch(owner, 10, dmgdata);
		if self.status_effects then
			for k,v in pairs(self.status_effects) do
				status_effect.apply_effect(entity, status_effect.parse(v));
			end
		end
	end
end

local designer_weapon_funcs = {
	projectile = function (def, from, dir, user)
		designer_weapons.shoot_projectile(def.entity_name, from, dir,
				def.speed_mult, def.damage_mult, user);
	end,

	hitscan = function (def, from, dir, user)
		local to = vector.add(from, vector.multiply(dir, 120));

		local entity, entity_pos, node_pos, axis =
				jutil.raycast.entities(from, to, {user});

		if entity then
			-- punch entity
			local dmg = jutil.math.normalize(vector.distance(from, entity_pos),
				def.falloff, def.falloff_min, def.damage_min, def.damage);
			if def.damage_headshot then
				local b1, b2 = jutil.raycast.get_entity_box(entity);
				local target_y = jutil.math.lerp(0.65, b1.y, b2.y);
				if entity_pos.y > target_y then
					dmg = def.damage_headshot;
				end
			end
			damage_entity(def, user, entity, dmg);

		elseif entity_pos and axis and def.decal then
			-- place decal
			local unit_vec = jutil.vec_unit(axis);
			if unit_vec then
				local decal_pos = vector.add(node_pos, unit_vec);
				local decal_node = minetest.get_node(decal_pos);
				local target_node = minetest.get_node(node_pos);
				if decal_node.name == "air"
				and minetest.registered_nodes[target_node.name].pointable then
					minetest.set_node(decal_pos, {name=def.decal,
						param2=minetest.dir_to_wallmounted(
						vector.multiply(unit_vec, -1))});
				end
			end
		end
	end,
}

local function weapon_can_shoot(itemstack, user)
	local def = itemstack:get_definition();

	-- check user ammo
	local can_shoot = true;
	if def.ammo and itemstack:get_wear() == 0 then
		local inv = user:get_inventory();
		if not inv then
			return false;
		else
			local wield_list = user:get_wield_list();
			if not inv:contains_item(wield_list, def.ammo) then
				return false
			end
		end
	end

	-- check if reloaded
	return itemstack:get_wear() == 0;
end

local WEAR_MAX = 65535;
minetest.register_globalstep(function(dtime)
	for _,player in pairs(minetest.get_connected_players()) do
		local itemstack = player:get_wielded_item();
		local def = itemstack:get_definition();
		local wear = itemstack:get_wear();
		-- reload weapons
		if def and def.groups and def.groups.reloaded_weapon and wear > 0 then
			local delay = def.delay or 1;
			local wear_sub = math.max(1, dtime * WEAR_MAX / delay);
			wear = math.max(0, wear - wear_sub);
			itemstack:set_wear(wear);
			player:set_wielded_item(itemstack);
			if wear == 0 then
				minetest.sound_play("dweapon_reload", {pos = player:getpos()});
			end
		end
		-- shoot automatic weapons
		if def.automatic and def.on_use and player:get_player_control().LMB and
				weapon_can_shoot(itemstack, player) then
			local new_itemstack = def.on_use(itemstack, player);
			if new_itemstack then
				player:set_wielded_item(itemstack);
			end
		end
	end
end)

local weapon_shoot = function(itemstack, user)
	local def = itemstack:get_definition();

	if weapon_can_shoot(itemstack, user) then
		local dir;
		local from = user:getpos();
		local yaw;
		from.y = from.y + 1.5;
		if user:is_player() then
			dir = user:get_look_dir();
			yaw =  user:get_look_yaw();
		else
			yaw = user:getyaw();
			dir = vector.new(math.cos(yaw), 0, math.sin(yaw));
		end
		local yrot = yaw - math.pi/2;
		local scale_rot = 0.15;
		from = vector.add(from, vector.new(math.cos(yrot)*scale_rot, 0,
		math.sin(yrot)*scale_rot));

		-- call shoot function
		local func = designer_weapon_funcs[def.weapon_type];
		if func then
			func(def, from, dir, user);
		end

		-- reload
		itemstack:set_wear(65535);

		-- shoot sound
		if def.sound_shoot then
			minetest.sound_play(def.sound_shoot, {pos = user:getpos()});
		end

		-- remove one ammo
		if def.ammo then
			local inv = user:get_inventory();
			if inv then
				local wield_list = user:get_wield_list();
				inv:remove_item(wield_list, def.ammo);
			end
		end
	else
		minetest.sound_play("dweapon_noshot", {pos = user:getpos()});
	end

	return itemstack;
end

function designer_weapons.register_weapon(name, weapon_type, def)
	-- def.on_use = function() end
	def.delay = def.delay or 0.1;
	if def.rate then def.delay = 1 / def.rate end
	def.damage = def.damage or 1;
	def.damage_min = def.damage_min or def.damage;
	def.falloff = def.falloff or 100;
	def.falloff_min = def.falloff_min or 0;
	def.weapon_type = weapon_type;

	if weapon_type == "melee" then
		def.tool_capabilities = def.tool_capabilities or {
			groupcaps={
				snappy={times={[1]=1.0, [2]=1.0, [3]=0.4}, uses=25, maxlevel=3},
			},
			damage_groups = {fleshy=def.damage},
		}
	else
		def.on_use = weapon_shoot;
		def.range = 0;
		def.groups = def.groups or {}
		def.groups.reloaded_weapon = 1;
	end

	designer_weapons.registered_weapons[name] = def;
	minetest.register_tool(name, def);
end

function designer_weapons.register_decal(name, def)
	def.drawtype = "nodebox";
	def.paramtype = "light";
	def.groups = {decal=1};
	def.paramtype2 = "wallmounted";
	def.sunlight_propagates = true;
	def.is_ground_content = false;
	def.walkable = false;
	def.pointable = false;
	def.diggable = false;
	def.buildable_to = true;
	def.floodable = true;
	def.groups = def.groups or {};
	def.groups.not_in_creative_inventory = 1;
	-- def.legacy_wallmounted = true;
	def.node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.49, -0.5,   0.5,  0.5,  0.5},
		wall_bottom = {-0.5, -0.5, -0.5,   0.5, -0.49, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.49,  0.55, 0.5},
	};

	designer_weapons.registered_decals[name] = def;
	minetest.register_node(name, def);
end

-- Slowly kill decals
minetest.register_abm({
	nodenames = {"group:decal"},
	interval = 3,
	chance = 30,
	action = function(pos, node)
		minetest.remove_node(pos)
	end
})

local function projectile_activate(self, staticdata)
	if staticdata ~= "" or self._i_am_activated_yes_edboy then
		self.object:remove();
	end
end

local function projectile_get_staticdata(self)
	-- kill projectiles when outside world
	if self._i_am_activated_yes_edboy then
		self.object:remove();
	end
	self._i_am_activated_yes_edboy = true;

	return "a"
end

minetest.register_entity("designer_weapons:explosion", {
	visual = "sprite",
	frame = 0,
	textures = {"dweapon_explosion.png"},
	spritediv = {x=7,y=1},
	visual_size = {x=4,y=4},
	physical = false,
	collide_with_objects = false,
	on_activate = projectile_activate,
	get_staticdata = projectile_get_staticdata,
	on_step = function(self, dtime)
		self.frame = self.frame + dtime * 15;
		local aframe = math.floor(self.frame);
		if aframe >= 7 then
			self.object:remove();
			return;
		end
		self.object:setsprite({x=aframe,y=0}, 7);
	end
})

local function projectile_kill(self, dir)
	if self.explode then
		minetest.add_entity(self.object:getpos(),
			"designer_weapons:explosion");
	end
	if self.decal then
		for _, axis in ipairs({dir, "y-", "y+", "x-", "x+", "z-", "z+"}) do
			if axis then
				local unit = jutil.vec_unit(axis);
				local block = minetest.get_node(vector.add(self.object:getpos(), unit));
				local block_def = minetest.registered_nodes[block.name];
				local decal_node = minetest.get_node(self.object:getpos());
				if decal_node.name == "air" and block_def and block_def.pointable then
					minetest.set_node(self.object:getpos(), {name=self.decal,
						param2=minetest.dir_to_wallmounted(unit)});
					break;
				end
			end
		end
	end
	self.object:remove();
end

local function projectile_explode(self, entity, vdir)
	local filter = {self.object}
	local owner = self.owner or self.object;
	--hurt entity
	if entity then
		damage_entity(self, owner, entity, self.damage);
		table.insert(filter, entity);
	end
	--blast radius
	if self.blast_radius > 0 then
		for _, other in pairs(jutil.table.filter(filter, minetest.get_objects_inside_radius(
				self.object:getpos(), self.blast_radius))) do
			local dis = vector.distance(self.object:getpos(), other:getpos());
			local dmg = jutil.math.normalize(dis, 0, self.blast_radius, self.damage, self.damage_min);
			if other == owner then
				dmg = dmg / 2;
			end
			dmg = math.max(1, dmg);
			damage_entity(self, owner, other, dmg);
		end
	end
	-- play sound
	if self.sound_hit then
		minetest.sound_play(self.sound_hit, {pos = self.object:getpos()})
	end
	--kill self
	projectile_kill(self, vdir);
end

local function projectile_on_step(self, dtime)
	self.life = self.life - dtime;
	if self.life < 0 then
		self.object:remove();
		return
	end
	self.wait = self.wait - dtime;
	if self.wait < 0 then
		-- find nearby entities
		local entities = minetest.get_objects_inside_radius(
				self.object:getpos(), self.radius)
		local entity = jutil.get_nearest_entity(entities, self.object:getpos(),
				{self.object});
		if entity then
			local self_b1, self_b2 = jutil.raycast.get_entity_box(self.object);
			local other_b1, other_b2 = jutil.raycast.get_entity_box(entity);
			if jutil.raycast.check_box_box(self_b1, self_b2, other_b1, other_b2) then
				projectile_explode(self, entity, nil);
			end
		end
	end
	-- destroy when velocity changes(presumably hitting a wall)
	local vdiff = vector.subtract(vector.add(self.prev, vector.multiply(
			self.object:getacceleration(), dtime)), self.object:getvelocity())
	if vector.length(vdiff) > 0.01 then
		self.is_currently_rolling = true;
		-- self.object:setvelocity(vector.multiply(self.prev, -self.bounce))
		local normal = vector.normalize(vector.subtract(self.prev, self.object:getvelocity()));
		local dir = vector.normalize(vector.reflect(self.prev, normal));
		local speed = vector.length(self.prev) * self.bounce;
		self.object:setvelocity(vector.multiply(dir, speed))
	end

	if self.is_currently_rolling then
		self.roll_time = self.roll_time - dtime;
		if self.roll_time <= 0 then
			projectile_explode(self, nil, vdiff);
			return
		end
	end

	self.prev = self.object:getvelocity()
end

function designer_weapons.register_projectile(name, def)
	def.gravity = def.gravity or 0; -- no gravity
	def.speed = def.speed or 1;     -- 1 m/s
	def.life = def.life or 5;       -- 5 second life span
	def.damage = def.damage or 1;   -- half heart
	def.wait = def.wait or 0.2;     -- time before it can hurt
	def.radius = def.radius or 5;
	def.visual = def.visual or "mesh";
	def.mesh = def.mesh or "dweapon_arrow.b3d";
	def.prev = {x=0,y=0,z=0};
	def.visual_size = def.visual_size or {x=2,y=2};
	def.blast_radius = def.blast_radius or 0;
	def.damage_min = def.damage_min or 0;
	def.roll_time = def.roll_time or 0;
	def.is_currently_rolling = false;
	def.bounce = def.bounce or 0;
	if def.backface_culling == nil then
		def.backface_culling = false;
	end
	if def.automatic_face_movement_dir == nil then
		def.automatic_face_movement_dir = 0.0
	end


	def.physical = true;
	def.collide_with_objects = false
	def.on_activate = projectile_activate;
	def.get_staticdata = projectile_get_staticdata;
	def.on_step = projectile_on_step;

	designer_weapons.registered_projectiles[name] = def;
	minetest.register_entity(name, def);
end

function designer_weapons.shoot_projectile(name, from, dir, speed_mult,
		damage_mult, owner)
	local speed_mult = speed_mult or 1;
	local damage_mult = damage_mult or 1;
	local def = designer_weapons.registered_projectiles[name];
	if not def then
		error("No such projectile of name " .. name);
	end
	local velocity = vector.multiply(dir, speed_mult * def.speed);
	local grav = {x=0,y=def.gravity,z=0}
	velocity = vector.add(velocity, vector.multiply(grav, -0.25))
	local object = minetest.add_entity(from, name);
	object:setacceleration(grav);
	object:setvelocity(velocity);
	local lua_entity = object:get_luaentity();
	lua_entity.damage = lua_entity.damage * damage_mult;
	lua_entity.prev = velocity;
	lua_entity.owner = owner;
end

function designer_weapons.restock_ammo(player)
	local inv = player:get_inventory();
	if not inv then return false end;
	local list = player:get_wield_list();

	local stacks = inv:get_list(list);
	local ammos_to_add = {}
	local total_counts = {}
	for _, itemstack in pairs(stacks) do
		if not itemstack:is_empty() then
			-- get counts
			local stackname = itemstack:get_name();
			total_counts[stackname] = total_counts[stackname] or 0;
			total_counts[stackname] = total_counts[stackname] + itemstack:get_count();

			-- get ammos
			local def = itemstack:get_definition();
			if def.ammo and def.ammo_max then
				ammos_to_add[def.ammo] = ammos_to_add[def.ammo] or 0;
				ammos_to_add[def.ammo] = math.max(ammos_to_add[def.ammo], def.ammo_max);
			end
		end
	end

	local did_do = false;
	for name, count in pairs(ammos_to_add) do
		if total_counts[name] then
			ammos_to_add[name] = ammos_to_add[name] - total_counts[name];
		end

		if ammos_to_add[name] > 0 then
			inv:add_item(list, name .. " " .. tostring(ammos_to_add[name]));
			did_do = true;
		end
	end

	return did_do;
end

dofile(minetest.get_modpath("designer_weapons") .. "/default.lua");
dofile(minetest.get_modpath("designer_weapons") .. "/testdummy.lua");
dofile(minetest.get_modpath("designer_weapons") .. "/ammo_pack.lua");
dofile(minetest.get_modpath("designer_weapons") .. "/health_pack.lua");
