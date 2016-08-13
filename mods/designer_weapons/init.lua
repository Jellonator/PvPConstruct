designer_weapons = {
	registered_weapons = {},
	registered_projectiles = {}
}

designer_weapons.TYPES = {
	"raytrace",
	"projectile",
	"melee"
}

function designer_weapons.register_weapon(name, weapon_type, def)
	-- def.on_use = function() end
	def.delay = def.delay or 0.1;
	def.on_secondary_use = function (itemstack, user, pointed_thing, digparams)
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
	end

	minetest.register_tool(name, def);
end

-- local COPY_PROJECTILE_DEF = {
-- 	'hp_max', 'weight', 'visual', 'visual_size', 'mesh', 'textures', 'colors',
-- 	'spritediv', 'initial_sprite_basepos', 'is_visible', 'makes_footstep_sount',
-- 	'automatic_rotate', 'automatic_face_movement_dir', 'backface_culling',
-- 	'automatic_face_movement_max_rotation_per_sec', 'nametag', 'nametag_color',
-- 	'infotext'
-- }
local function projectile_punch()
	--can not be hurt
end

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

		-- destroy when velocity changes
		if vector.distance(vector.add(self.prev,
				vector.multiply(self.object:getacceleration(), dtime)),
				self.object:getvelocity()) > 0.1 then
			self.object:remove();
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
	def.wait = def.wait or 0.1;     -- time before it can hurt
	def.radius = def.radius or 5;

	def.physical = true;
	def.collide_with_objects = false
	def.on_punch = projectile_punch;
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
