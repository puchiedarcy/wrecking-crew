Wrecking Crew
=============
This repository contains two files.
One is a LUA script to assist in playing or practising.
The other is a RAM Watch file just in case you're curious about the inner workings of Wrecking Crew.

wcrew.lua
=========
This script has the following functions:

1. Shows the location of the Prize Bomb on each level, when available.
1. Shows Prize Bomb counters on each level to help get the Golden Hammer
 1. Bomb Counter is how many bombs are left
 1. Magic Number is how many swing are left
 1. When Bomb Counter and Magic Number equal 1, wreck the Prize Bomb for a Golden Hammer
1. Shows the location of the Bonus Coin after every 4 levels.
1. Holding B then quickly pressing A with turn on/off the Golden Hammer. Useful for practising levels with the Golden Hammer without backtracking.

Wrecking Crew.wch
=================
Contains a list of interesting RAM values.

Basics
======
The map of Wrecking Crew has 8 floors (0 to 7, top to bottom) and 16 columns (0 to F, left to right).
Mario's location is held in {{0x030F}}.
Mario starts at 79 in Phase 01 (7th/bottom floor, 10th column [because it starts at 0]).

Golden Hammer
=============
Wrecking Crew is near unplayable without the Golden Hammer.
You can obtain the Golden Hammer on any level that has *at least 3 bombs*.
The game keeps track of how many bombs have been exploded at {{0x0440}}.
It starts at 1 and increases whenever a bomb space is swung at.
This means it increases regardless of whether or not a bomb is there or explodes.

One of the bombs on the map will be the "Prize Bomb" that can yield the Golden Hammer.
The location of the Prize Bomb on the map is stored at {{0x0441}}.

The game also keeps track of a "Magic Number".
On each level it starts at [Phase number - 1] and increases by 1 with each swing of the hammer.
The Magic Number is stored at {{0x005D}}.

The Golden Hammer comes out after the Prize Bomb is exploded when two conditions are met:
 1. The Bomb Counter is at 3.
 1. The Magic Number is evenly divisible by 8.

If the Prize Bomb is the first or second bomb exploded, the Bomb Counter is set to 0 preventing a prize from coming out.
If a bomb that isn't the Prize Bomb is hit third, the Bomb Counter is set to 0 preventing a prize.

When the Magic Number is not evenly divisible by 8, a prize that gives points comes out. Useless.

The flag for having the Golden Hammer is stored at {{0x005C}}.

Bonus Coin
==========
The location of the Bonus Coin is stored {{0x034F}}.
Incidentally, in normal levels this is the location of the first enemy.

Known Unknowns
==============
* How is the Prize Bomb location selected?
* How is the Bonus Coin location selected?

Misc.
=====
* The game keeps track of how many levels (including bonus) you've beaten in a row at {{0x0039}}.
* The game keeps track of how many things have been wrecked since power on at {{0x005e}}.
