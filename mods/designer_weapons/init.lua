designer_weapons = {}

function designer_weapons.register_weapon()

end

minetest.register_tool("designer_weapons:gahbage", {
	description = "Does something I guess",
	inventory_image = "creative_trash_icon.png",
	on_use = function(itemstack, user, pointed_thing)
		local pos1 = user:getpos();
		local pos2 = pointed_thing.above;
		if pos2 and pos1 then
			pos1.y = pos1.y + 1;
			print("Doing block iter!")
			for pos in jutil.block_iter(pos1, pos2) do
				minetest.set_node(pos, {name="default:mese"});
			end

		end
		return itemstack;
	end
})
