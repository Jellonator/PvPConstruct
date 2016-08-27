Caste.class.set("Scout", {
	description = "Run fast and hit hard.",
	items = {
		{name = "designer_weapons:shotgun", count = 1}
	},
	effects = {
		{name="default:speed", strength=2}
	}
});

Caste.class.set("Soldier", {
	description = "Rocket jump and shoot from above.",
	items = {
		{name = "designer_weapons:shotgun", count = 1},
		{name = "team_fort:rocket_launcher", count = 1}
	},
	effects = {
		{name="default:speed", strength=1.1}
	}
});

Caste.class.set("Demoman", {
	description = "Shoot grenades.",
	items = {
		{name = "team_fort:grenade_launcher", count = 1}
	},
	effects = {
		{name="default:speed", strength=1.2}
	}
});

Caste.class.set("Heavy", {
	description = "Deal out damage at close range.",
	items = {
		{name = "team_fort:minigun", count = 1}
	},
	effects = {
		{name="default:speed", strength=0.8}
	}
});

Caste.class.set("Medic", {
	description = "Heal teammates with your crossbow.",
	items = {
		{name = "team_fort:healing_crossbow", count = 1}
	},
	effects = {
		{name="default:speed", strength=1.2}
	}
});

Caste.class.set("Sniper", {
	description = "Shoot enemies from afar with a rifle.",
	items = {
		{name = "designer_weapons:rifle", count = 1}
	},
	effects = {}
});
