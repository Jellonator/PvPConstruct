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

local designer_weapon_funcs = {
	projectile = function (itemstack, user, pointed_thing, digparams)
		local def = designer_weapons.registered_weapons[itemstack:get_name()];

		if itemstack:get_wear() == 0 then
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

			designer_weapons.shoot_projectile(def.entity_name, from, dir,
					def.speed_mult, def.damage_mult, user);
			itemstack:set_wear(65535);
		end

		return itemstack;
	end,

	hitscan = function (itemstack, user, pointed_thing, digparams)
		local def = designer_weapons.registered_weapons[itemstack:get_name()];

		if itemstack:get_wear() == 0 then
			local dir;
			local from = user:getpos();
			from.y = from.y + 1.6;
			if user:is_player() then
				dir = user:get_look_dir();
			else
				local yaw = user:getyaw();
				dir = vector.new(math.cos(yaw), 0, math.sin(yaw));
			end
			local to = vector.add(from, vector.multiply(dir, 120));

			local entity, entity_pos, node_pos, axis =
					jutil.raytrace_entity(from, to, {user});

			if entity then
				-- punch entity
				local dmg = jutil.normalize(vector.distance(from, entity_pos),
					def.falloff, def.falloff_min, def.damage_min, def.damage);
				entity:punch(user, 10, {damage_groups={fleshy=dmg}});

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

			itemstack:set_wear(65535);
		end
		return itemstack;
	end,

	melee = nil -- use default punching mechanic
}

local WEAR_MAX = 65535;
minetest.register_globalstep(function(dtime)
	for _,player in pairs(minetest.get_connected_players()) do
		local itemstack = player:get_wielded_item();
		local def = itemstack:get_definition();
		if def and def.groups and def.groups.reloaded_weapon then
			local delay = def.delay or 1;
			local wear_sub = math.max(1, dtime * WEAR_MAX / delay);
			local wear = itemstack:get_wear();
			wear = math.max(0, wear - wear_sub);
			itemstack:set_wear(wear);
			player:set_wielded_item(itemstack);
		end
	end
end)

function designer_weapons.register_weapon(name, weapon_type, def)
	-- def.on_use = function() end
	def.delay = def.delay or 0.1;
	if def.rate then def.delay = 1 / def.rate end
	def.on_use = designer_weapon_funcs[weapon_type];
	def.damage = def.damage or 1;
	def.damage_min = def.damage_min or def.damage;
	def.falloff = def.falloff or 100;
	def.falloff_min = def.falloff_min or 0;

	if weapon_type == "melee" then
		def.tool_capabilities = def.tool_capabilities or {
			groupcaps={
				snappy={times={[1]=1.0, [2]=1.0, [3]=0.4}, uses=25, maxlevel=3},
			},
			damage_groups = {fleshy=def.damage},
		}
	else
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
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
	self.object:set_armor_groups({fleshy=1})
end

local function projectile_get_staticdata(self)
	return jutil.serialize_safe(self);
end

minetest.register_entity("designer_weapons:explosion", {
	visual = "sprite",
	frame = 0,
	textures = {"dweapon_explosion.png"},
	spritediv = {x=7,y=1},
	visual_size = {x=2,y=2},
	physical = false,
	collide_with_objects = false,
	on_activate = function(self, staticdata)
		if staticdata == "a" then
			self.object:remove()
		end
	end,
	get_staticdata = function() return "a" end,
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
				minetest.chat_send_all(string.format("Axis: %s", dump(unit)))
				minetest.chat_send_all("Orientation: " .. minetest.dir_to_wallmounted(unit))
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
	if entity then
		--hurt entity
		local dmgdata = {damage_groups={fleshy=self.damage}}
		entity:punch(owner, 10, dmgdata);
		table.insert(filter, entity);
	end
	--blast radius
	for _, other in pairs(jutil.table_filter(filter, minetest.get_objects_inside_radius(
			self.object:getpos(), self.blast_radius))) do
		local dis = vector.distance(self.object:getpos(), other:getpos());
		local dmg = jutil.normalize(dis, 0, self.blast_radius, self.damage, self.damage_min);
		if other == owner then
			dmg = dmg / 2;
		end
		dmg = math.max(1, dmg);
		local dmgdata = {damage_groups={fleshy=dmg}}
		other:punch(owner, 10, dmgdata);
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
			local self_b1, self_b2 = jutil.get_entity_box(self.object);
			local other_b1, other_b2 = jutil.get_entity_box(entity);
			if jutil.check_box_box(self_b1, self_b2, other_b1, other_b2) then
				projectile_explode(self, entity, nil);
			end
		end
	end
	-- destroy when velocity changes(presumably hitting a wall)
	local vdiff = vector.subtract(vector.add(self.prev, vector.multiply(
			self.object:getacceleration(), dtime)), self.object:getvelocity())
	if vector.length(vdiff) > 0.01 then
		projectile_explode(self, nil, vdiff);
		return
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
	local object = minetest.add_entity(from, name);
	object:setacceleration({x=0,y=def.gravity,z=0});
	object:setvelocity(velocity);
	local lua_entity = object:get_luaentity();
	lua_entity.damage = lua_entity.damage * damage_mult;
	lua_entity.prev = velocity;
	lua_entity.owner = owner;
end

dofile(minetest.get_modpath("designer_weapons") .. "/default.lua");
dofile(minetest.get_modpath("designer_weapons") .. "/testdummy.lua");
