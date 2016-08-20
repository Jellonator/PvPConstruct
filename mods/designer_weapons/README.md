Designer Weapons
================

This is a mod which defines several weapons, and introduces an API to define
even more.

#### Included weapons

The weapons this mod includes are as follows:
 * Bow and arrow - a projectile that is affected by gravity.
 * pistol - a basic hitscan weapon
 * shotgun - a hitscan weapon that does less damage from afar.
 * rifle - a hitscan weapon that deals more damage when it headshots.

#### Other stuff

This mod also provides an ammo box which refills ammo for the player who
collects it. It respawns every few seconds.

There is also a health pack which completely heals the player who picks it up.
It, too, respawns every few seconds.

Lua API
-------

#### Weapon definition

Weapons can be created using the
`designer_weapons.register(name, weapon_type, def)` function.
The name can be any string as long as it follows standard minetest naming
conventions.

The weapon type can be as follows:
 * projectile - this weapon will spawn an entity when fired.
 * hitscan - this weapon will instantly hit anything under the player's cursor.
 * melee - this is a melee weapon.

The weapon definition is as follows:

```Lua
weapon_def = {
	-- General properties
	damage - how much damage this weapon should deal.
	delay - the time between each shot.
	rate - how fast this weapon can be fired (1 / delay).
	sound_shoot - the sound this weapon will play when fired.
	decal - the tile this weapon will leave behind when it misses.
	ammo - the item this weapon will use as ammo.
	ammo_max - how much ammo an ammo box will restore to.

	-- Projectile weapon
	entity_name - the entity to spawn.

	-- Hitscan weapon
	status_effects - The status effects this weapon will apply.
	damage_min - the damage this weapon will do at maximum falloff.
	falloff - how far away the player will be when damage_min will be dealt.
	falloff_min - how close the player can be to deal maximum damage.
	damage_headshot - how much damage this weapon will deal on headshot.
}
```

#### Projectile definition

This mod provides an easier interface for defining projectiles. A projectile
will stop when it hits a wall or an entity. Projectiles can be defined using the
`designer_weapons.register_projectile(name, def)`, where 'name' can be any name
as long as it follows standard minetest entity naming rules, and 'def' is the
projectile definition.

Projectiles are defined as follows:

```Lua
def = {
	gravity - The effect of gravity on this projectile.
	speed - how fast this projectile will move.
	life - how long this projectile will go before it disappears.
	damage - how much damage this projectile will deal.
	damage_min - damage this projectile will deal if it explodes at max range.
	blast_radius - range the explosion will encompass.
	explode - whether this projectile explodes or not.
	sound_hit - sound played when this projectile hits.
	decal - tile left behind when this projectile hits something.
	status_effects - -he status effects this projectile will apply.
}
```

#### Decal definition

This mod also gives an easy way to define decals to be left behind by weapons.
Decals can be defined with the function
`designer_weapons.register_decal(name, def)`, where 'name' can be any name
as long as it follows standard minetest tile naming rules, and 'def' is the
tile definition.

Decal definition:

```Lua
def = {
	-- This is all a decal needs to define.
	-- It will appear as a flat plane
	-- Feel free to change the visual type though,
	-- this is just a shortcut for minetest.register_node
	tiles = {texture}
}
```
