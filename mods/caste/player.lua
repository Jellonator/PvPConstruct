local Player = {
	player_data = {}
}

function Player.reset(player)
	if type(player) == "string" then
		local ent = minetest.get_player_by_name(player);
		if ent then
			return Player.reset(ent)
		end
		return;
	end
	local player_name = player:get_player_name();
	if not player_name then return end;
	local class = Player.player_data[player_name];
	local class_data = Caste.class.get(class) or {};
	local items = Caste.class.get_items(class);
	jutil.player.clear_items(player);
	if items then
		for _, v in ipairs(items) do
			local inv = player:get_inventory();
			local list = player:get_wield_list();
			inv:add_item(list, v.name .. " " .. tostring(v.count));
		end
	end
	local effects = Caste.class.get_effects(class);
	status_effect.clear_effects(player);
	if effects then
		for _, effect in pairs(effects) do
			status_effect.apply_effect(player, effect.name, 1,
					effect.strength, {infinite=true})
		end
	end
	if Teammake then
		Teammake.reset_player(player);
	end
end

function Player.leave(player)
	if Player.player_data[player] == nil then
		return false, "Error, player is not of a class!"
	end
	Player.player_data[player] = nil;
	Player.reset(player);
	Caste._increment_id();

	return true, "Player successfully had their class removed!";
end

function Player.join(player, class)
	if not Caste.class.exists(class) then
		return false, "Error, class " .. tostring(class) .. " does not exist!";
	end
	if Player.player_data[player] == class then
		return false, "Error, player is already of this class!"
	end

	Player.player_data[player] = class;
	Player.reset(player);
	Caste._increment_id();

	return true, "Player's class was set successfully!"
end

function Player.get_player_class(player)
	return Player.player_data[player];
end

-- reset a dead player's items and status effects
minetest.register_on_respawnplayer(function(player)
	if not player:is_player() then return false end
	Player.reset(player);
end)

return Player;
