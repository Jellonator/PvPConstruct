local AMMO_ROT = 1;
local AMMO_CHECK_RATE = 0.3;
local AMMO_CHECK_RANGE = 1.2;
local AMMO_TIMEOUT = 5;

local ammo = {
	collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
	visual = "mesh",
	mesh = "dweapon_ammo.b3d",
	textures = {"dweapon_ammo.png"},
	visual_size = {x=3.3,y=3.3},

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

local function reload_player(player)
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

			-- filter out anything not a player
			jutil.table.filter_inplace(jutil.filter.NOT, entities,
					jutil.filter.PLAYER);

			local entity = jutil.get_nearest_entity(entities,
					self.object:getpos());
			if entity then
				if reload_player(entity) then
					self.wait = AMMO_TIMEOUT;
					self.object:setpos(vector.add(self.object:getpos(),
							{x=0,y=-1,z=0}));
				end
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
