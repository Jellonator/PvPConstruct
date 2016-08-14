local dummy = {
	hp_max = 20,
	collisionbox = {-0.4, -0.9, -0.4, 0.4, 0.9, 0.4},
	visual = "cube",
	visual_size = {x=0.8,y=1.8},
};

function dummy.on_activate(self, staticdata)
	self.dummy_bool = true
	self.dummy_number = 1.0
	self.dummy_string = "Hello"
	if staticdata then
		jutil.deserialize_to(staticdata, self);
	end
end

function dummy.get_staticdata(self)
	return jutil.serialize_safe(self);
end

function dummy.on_punch(self, puncher, time, tool_capabilities, dir)
	if not puncher:is_player() then return end
	local dmg = tool_capabilities.damage_groups and
			tool_capabilities.damage_groups.fleshy or 0;
	minetest.chat_send_player(puncher:get_player_name(),
			string.format("You did %d damage!", dmg));
end

minetest.register_entity("designer_weapons:dummy", dummy);

minetest.register_craftitem("designer_weapons:dummy", {
	description = "Test dummy",
	inventory_image = "dweapon_dummy_item.png",

	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end

		pointed_thing.under.y = pointed_thing.under.y + 0.5 + 0.9
		local entity = minetest.add_entity(pointed_thing.under, "designer_weapons:dummy");
		entity:get_luaentity().color = color;
		entity:get_luaentity().original_color = color;

		if not minetest.setting_getbool("creative_mode") then
			itemstack:take_item()
		end
		return itemstack
	end,
})
