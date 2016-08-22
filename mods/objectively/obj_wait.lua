local WAIT_HUD = {
	hud_elem_type = "text",
	text = "",
	position = {x=0.5,y=0},
	alignment = {x=0,y=1},
	offset = {x=0,y=1},
};

local wait_obj = {
	hud_elements = {},
	on_joinplayer = function(self, player)
		self.hud_elements[player:get_player_name()] = player:hud_add(WAIT_HUD)
	end,
	on_leaveplayer = function(self, player)
		local hud = self.hud_elements[player:get_player_name()];
		player:hud_remove(hud);
		self.hud_elements[player:get_player_name()] = nil;
	end,
	on_enable = function(self, time, next)
		self.timer = time or 10;
		self.next = next;
	end,
	on_globalstep = function(self, dtime)
		self.timer = self.timer - dtime;
		if self.timer <= 0 and self.next then
			print("WOW")
			Objectively.set_objective(self.next);
		end
		local ptext = WAIT_HUD.text;
		WAIT_HUD.text = "Next round in " .. jutil.string.fmt_seconds(self.timer) .. " seconds."
		if ptext ~= WAIT_HUD.text then
			for name, id in pairs(self.hud_elements) do
				local player = minetest.get_player_by_name(name);
				if player then
					player:hud_change(id, 'text', WAIT_HUD.text);
				end
			end
		end
	end,
	get_staticdata = function(self)
		return jutil.serialize_safe({next=self.next,timer=self.timer});
	end,
	on_loaddata = function(self, data)
		local data = minetest.deserialize(data) or {};
		self.timer = data.timer or 30;
		self.next = data.next;
	end,
}

Objectively.register_objective("_wait", wait_obj);
