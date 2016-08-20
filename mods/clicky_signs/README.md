Clicky Signs
============

This is a mod which defines signs that can be clicked by players. The only thing
this mod defines is a node called `clicky_signs:sign_clickable`.

When a sign is placed, it can only ever be modified by the player who placed it,
or by players with protection_bypass privileges. The sign will also follow
the privileges of the player who owns the sign when running commands. When a
player click on this sign, the command contained inside the sign will be run
on the player who clicked it, with the privileges of the player who placed it.

All `@` symbols in the sign's command will be replaced with the name of the
player who clicked it. Multiple commands can be run by separating each command
with a semicolon.
