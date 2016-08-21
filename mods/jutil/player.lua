local Player = {};

function Player.clear_items(player)
	local inv = player:get_inventory();
	local list = player:get_wield_list();
	inv:set_list(list, {});
end

function Player.named(player)
	if type(player) == "string" then
		return player;
	end

	return player:get_player_name();
end

function Player.entity(player)
	if type(player) == "string" then
		return minetest.get_player_by_name(player);
	end

	return player;
end

function Player.name_ent(player)
	return Player.named(player), Player.entity(player);
end

return Player;
