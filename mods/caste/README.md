caste
=====

This is a mod that adds class to the game. Every class has a set of items and
status effects that are given to players when a player becomes that class.

Joining a class
----------------

There are two methods of joining a class. The first is with
`/caste join <class>`, which will set a players class, provided that 'class'
exists. The other method is with `/caste select`, which will show an
interactable list of classes to join.

To get further information about a class before joining it, the command
`/caste info <class>` will show more in-depth information about a class,
including a description, a list of items given to players in that class, and
a list of status effects applied to players in that class.

Creating a custom class
-----------------------

This mod, by default, does not specify any classes. Classes instead will need to
be defined by an admin with the 'caste_admin' privilege.

A class can be created using `/casteadmin new <name>`. This will create a new
class with the name 'name', provided that class does not already exist.

A class also defines a base inventory for every player that is in that class. To
add an item to that inventory, use `/casteadmin item add <item> [count]`, where
'item' is an itemstring, and count is a number. If no count is given it will
default to 1. If a mistake is made in defining items,
`/casteadmin item remove <item>` will remove that item from the list of items.

Classes may also define status effects to apply on players who are in that
class. Status effects added by a class will be infinite in length and will
always affect players of that class. To add a status effect to a class, use
`/casteadmin effect add <effect> [strength]`, where 'effect' is the name of the
status effect and (optionally) 'strength' is the potency of the effect. Same as
with items, effects can be removed if a mistake is made defining them. Use
`/casteadmin effect remove <effect>` to remove 'effect' from the effect list.

Of course, a class will also need some sort of description to describe their
role. to do that, simply use `/casteadmin describe <class> <description>`,
which will add a description 'description' to 'class'.
