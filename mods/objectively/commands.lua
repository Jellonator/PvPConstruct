minetest.register_privilege("objectively_admin", {
	description = "Can set Objectively objectives"
})

jutil.cmd.register("objectively",
	{
		description = "Objective commands",
		privs = {objectively_admin = 1}
	},{
		set = jutil.cmd.command({"objective:string"},
		function(_, objective)
			return Objectively.set_objective(objective);
		end, "Sets the active objective"),

		current = jutil.cmd.command({},
		function()
			if Objectively.get_objective() then
				return true, "Current objective: " .. Objectively.current_objective
			else
				return true, "There is no active objective."
			end
		end, "Prints the currently active objective."),

		list = jutil.cmd.command({},
		function()
			local ret = "Objectives:";
			for name, _ in pairs(Objectively.registered_objectives) do
				ret = ret .. '\n\t' .. name;
			end
			return true, ret
		end, "Lists off all available objectives.");
	}
)
