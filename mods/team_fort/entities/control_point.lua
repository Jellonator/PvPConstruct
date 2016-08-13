local control_point_textures = {
	[TEAM_COLOR.NEUTRAL] = "teamf_cp_neutral.png",
	[TEAM_COLOR.RED]     = "teamf_cp_red.png",
	[TEAM_COLOR.BLUE]    = "teamf_cp_blue.png"
}

local control_point = {
	collisionbox = {-2.5, 0.0, -2.5, 2.5, 0.25, 2.5},
	visual = "mesh",
	mesh = "teamf_control_point.b3d",
	textures = {"teamf_cp_neutral.png"},
	visual_size = {x=10,y=10},

	color = TEAM_COLOR.NEUTRAL,
	pcolor = 4,
	original_color = TEAM_COLOR.NEUTRAL
};

function control_point.on_activate(self, staticdata)
	if staticdata then
		local data = string.split(staticdata, ",");
		self.color = tonumber(data[1]);
		self.original_color = tonumber(data[2]);
		self.pcolor = 4;
		print("Activating point: ", data[1], data[2]);
	end
	self.object:set_armor_groups({immortal=1})
end

function control_point.get_staticdata(self)
	local data = {self.color, self.original_color};
	local ret = table.concat(data, ",");
	print("Saving point: " .. ret);
	return ret;
end

function control_point.on_step(self, dtime)
	if self.color ~= self.pcolor then
		self.pcolor = self.color;
		self.object:set_properties({textures = {control_point_textures[self.color]}})
	end
end

minetest.register_entity("team_fort:control_point", control_point);

local function register_control_point_item(name, texture, color)
	minetest.register_craftitem("team_fort:control_point_" .. name, {
		description = "Control point " .. name,
		inventory_image = texture,
		wield_image = texture,

		on_place = function(itemstack, placer, pointed_thing)
			if pointed_thing.type ~= "node" then
				return
			end

			pointed_thing.under.y = pointed_thing.under.y + 0.5
			local entity = minetest.add_entity(pointed_thing.under, "team_fort:control_point");
			entity:get_luaentity().color = color;
			entity:get_luaentity().original_color = color;

			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end,
	})
end

register_control_point_item("neutral", "teamf_cp_neutral_item.png", TEAM_COLOR.NEUTRAL)
register_control_point_item("red", "teamf_cp_red_item.png", TEAM_COLOR.RED)
register_control_point_item("blue", "teamf_cp_blue_item.png", TEAM_COLOR.BLUE)
