local HEALTHPACK_ROT = 0.61;--kek
local HEALTHPACK_CHECK_RATE = 0.25;
local HEALTHPACK_CHECK_RANGE = 1.0;
local HEALTHPACK_TIMEOUT = 5;

local healthpack = {
	collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
	visual = "mesh",
	mesh = "dweapon_healthpack.b3d",
	textures = {"dweapon_healthpack.png"},
	visual_size = {x=3.3,y=3.3},

	timer = 0,
	wait = 0,
	original_position,
};

local function heal_player(player)
	local prevhp = player:get_hp();
	player:set_hp(prevhp+1000);
	return player:get_hp() ~= prevhp;
end

function healthpack.on_activate(self, staticdata)
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
	self.object:set_armor_groups({immortal=1})
end

function healthpack.get_staticdata(self)
	return jutil.serialize_safe(self);
end

function healthpack.on_step(self, dtime)
	if not self.original_position then
		self.original_position = self.object:getpos();
	end
	local nyaw = self.object:getyaw() + dtime*HEALTHPACK_ROT;
	self.object:setyaw(jutil.math.mod(nyaw, math.pi*2));
	if self.wait > 0 then
		self.wait = self.wait - dtime;
		if self.wait <= 0 then
			self.object:setpos(self.original_position);
		end
	else
		self.timer = self.timer + dtime;
		if self.timer >= HEALTHPACK_CHECK_RATE then
			self.timer = 0;
			local entities = minetest.get_objects_inside_radius(
					self.object:getpos(), HEALTHPACK_CHECK_RANGE);

			-- filter out anything not a player
			jutil.table.filter_inplace(jutil.filter.NOT, entities,
					jutil.filter.PLAYER);

			for _,entity in pairs(entities) do
				if heal_player(entity) then
					self.wait = HEALTHPACK_TIMEOUT;
					self.object:setpos(vector.add(self.object:getpos(),
							{x=0,y=-1,z=0}));
					return
				end
			end
		end
	end
end

minetest.register_entity("designer_weapons:healthpack", healthpack);

jutil.register_entitytool("designer_weapons:healthpack",
		"designer_weapons:healthpack", {
	description = "An healthpack",
	inventory_image = "dweapon_healthpack_item.png"
})
