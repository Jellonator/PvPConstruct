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

		local can_use = true;
		local meta = itemstack:get_metadata();
		local curtime = os.time();
		if meta == "" then
			can_use = true;
		else
			can_use = tonumber(meta) + def.delay < curtime;
		end

		if can_use then
			local dir;
			local from = user:getpos();
			from.y = from.y + 1.6;
			if user:is_player() then
				dir = user:get_look_dir();
			else
				local yaw = user:getyaw();
				dir = vector.new(math.cos(yaw), 0, math.sin(yaw));
			end

			designer_weapons.shoot_projectile(def.entity_name, from, dir,
					def.speed_mult, def.damage_mult);
			itemstack:set_metadata(tostring(curtime))
		end
		return itemstack;
	end,

	hitscan = function (itemstack, user, pointed_thing, digparams)
		local def = designer_weapons.registered_weapons[itemstack:get_name()];

		local can_use = true;
		local meta = itemstack:get_metadata();
		local curtime = os.time();
		if meta == "" then
			can_use = true;
		else
			can_use = tonumber(meta) + def.delay < curtime;
		end

		if can_use then
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
				local dmg = jutil.normalize(vector.distance(from, entity_pos),
					def.falloff, def.falloff_min, def.damage_min, def.damage);
				entity:punch(user, 10, {damage_groups={fleshy=dmg}});
			elseif entity_pos and axis and def.decal then
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
						print("Placed node!")
					else
						print("Can not place node :(");
					end
				else
					print("No unit :<")
				end
			end

			itemstack:set_metadata(tostring(curtime))
		end
		return itemstack;
	end,

	melee = nil -- use default punching mechanic
}

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
	interval = 2,
	chance = 20,
	action = function(pos, node)
		minetest.remove_node(pos)
	end
})

local function projectile_activate(self, staticdata)
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
	self.object:set_armor_groups({immortal=1})
end

local function projectile_get_staticdata(self)
	return jutil.serialize_safe(self);
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
		local entity = jutil.get_nearest_entity(
				minetest.get_objects_inside_radius(self.object:getpos(),
				self.radius), self.object:getpos(), {self.object});
		if entity then
			local self_b1, self_b2 = jutil.get_entity_box(self.object);
			local other_b1, other_b2 = jutil.get_entity_box(entity);
			if jutil.check_box_box(self_b1, self_b2, other_b1, other_b2) then
				entity:punch(self.object, 10, {damage_groups={fleshy=self.damage}});
				self.object:remove();
				print("Punched!")
				return
			end
		end
	end
	-- destroy when velocity changes
	if vector.distance(vector.add(self.prev,
	vector.multiply(self.object:getacceleration(), dtime)),
	self.object:getvelocity()) > 0.1 then
		self.object:remove();
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

	def.physical = true;
	def.collide_with_objects = false
	def.on_activate = projectile_activate;
	def.get_staticdata = projectile_get_staticdata;
	def.on_step = projectile_on_step;

	designer_weapons.registered_projectiles[name] = def;
	minetest.register_entity(name, def);
end

function designer_weapons.shoot_projectile(name, from, dir, speed_mult, damage_mult)
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
end

dofile(minetest.get_modpath("designer_weapons") .. "/default.lua");
dofile(minetest.get_modpath("designer_weapons") .. "/testdummy.lua");

-- minetest.register_tool("designer_weapons:gahbage", {
-- 	description = "Does something I guess",
-- 	inventory_image = "creative_trash_icon.png",
-- 	on_use = function(itemstack, user, pointed_thing)
-- 		local pos1 = user:getpos();
-- 		local view = vector.multiply(user:get_look_dir(), 100);
-- 		pos1.y = pos1.y + 1.6;
-- 		print(string.format("Thing: %f, %f, %f", view.x, view.y, view.z))
-- 		local pos2 = vector.add(pos1, view);
--
-- 		local entity, entity_pos = jutil.raytrace_entity(pos1, pos2, {user});
-- 		if entity then
-- 			entity:remove();
-- 		end
--
-- 		return itemstack;
-- 	end
-- })
