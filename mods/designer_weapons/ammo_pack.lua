local AMMO_ROT = 1;
local AMMO_CHECK_RATE = 0.5;
local AMMO_CHECK_RANGE = 1.25;
local AMMO_TIMEOUT = 10;

local ammo = {
	collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
	visual = "cube",
	visual_size = {x=0.6,y=0.6},

	timer = 0,
	wait = 0,
	original_position,
};

function ammo.on_activate(self, staticdata)
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
	self.object:set_armor_groups({immortal=1})
end

function ammo.get_staticdata(self)
	return jutil.serialize_safe(self);
end

function ammo.on_step(self, dtime)
	if not self.original_position then
		self.original_position = self.object:getpos();
	end
	self.object:setyaw(self.object:getyaw() + dtime*AMMO_ROT);
	if self.wait > 0 then
		self.wait = self.wait - dtime;
		if self.wait <= 0 then
			self.object:setpos(self.original_position);
		end
	else
		self.timer = self.timer + dtime;
		if self.timer >= AMMO_CHECK_RATE then
			self.timer = 0;
			local entities = minetest.get_objects_inside_radius(
					self.object:getpos(), AMMO_CHECK_RANGE);

			jutil.table.filter_inplace(jutil.filter.NOT, entities,
					jutil.filter.PLAYER);
			-- jutil.table.filter_inplace({self.object}, entities);

			local entity = jutil.get_nearest_entity(entities,
					self.object:getpos());
			if entity then
				self.wait = AMMO_TIMEOUT;
				self.object:setpos(vector.add(self.object:getpos(),
						{x=0,y=-1,z=0}))
			end
		end
	end
end

minetest.register_entity("designer_weapons:ammo_pack", ammo);

jutil.register_entitytool("designer_weapons:ammo_pack",
		"designer_weapons:ammo_pack", {
	description = "An ammo pack",
	inventory_image = "dweapon_decal_bullet.png"
})
