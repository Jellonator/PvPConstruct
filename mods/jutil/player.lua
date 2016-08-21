local Player = {};

function Player.clear_items(player)
	local inv = player:get_inventory();
	local list = player:get_wield_list();
	inv:set_list(list, {});
end

return Player;
