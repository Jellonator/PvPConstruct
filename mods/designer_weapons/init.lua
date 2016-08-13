designer_weapons = {
	registered_weapons = {},
	registered_projectiles = {}
}

designer_weapons.TYPES = {
	"gun",
	"bow",
	"sword"
}

function designer_weapons.register_weapon(name, def)

end

function designer_weapons.register_projectile(name, def)
	def.gravity = def.gravity or 0; -- no gravity
	def.speed = def.speed or 1; -- 1 m/s
	def.life = def.life or 10; -- 10 second life span
	def.damage = def.damage or 1; -- half heart
end

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
