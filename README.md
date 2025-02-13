# Overview

This solution to the maze game problem does not use A* or other graph search algorithms.

Instead, it uses BFS to expand the frontier from the start node, and each node as it is processed keeps a list of all paths to it such that none are _strictly worse_ than any paths it has. If a visited node path is updated, it is again added back into the fronteir for re-processing. This way, when you reach the end, you have the list of all paths from A to B where none is _strictly worse_.

The definition of _strictly worse_ is defined in code as the logical inverse:

```rb
def is_strictly_better(other)
	@health >= other.health && @moves >= other.moves && (@health > other.health || @moves > other.moves)
end
```

Doing a full BFS (with possible reprocessing) is not the most efficient route, but it should deterministically guarantee finding all paths from A to B where none is _strictly worse_.

Here is sorted sample output from `random1.in.result` showing all the paths from A to B. None of these paths are _strictly worse_ than any other path. And the intuition of using Health to reduce Moves does make sense.

```sh
Path 40: Health=200, Moves=299
Path 39: Health=195, Moves=310
Path 38: Health=190, Moves=313
Path 37: Health=185, Moves=318
Path 36: Health=180, Moves=323
Path 35: Health=175, Moves=328
Path 34: Health=170, Moves=331
Path 33: Health=165, Moves=334
Path 32: Health=160, Moves=337
Path 31: Health=155, Moves=338
Path 30: Health=150, Moves=341
Path 29: Health=145, Moves=342
Path 28: Health=140, Moves=345
Path 27: Health=135, Moves=346
Path 22: Health=130, Moves=349
Path 21: Health=125, Moves=350
Path 20: Health=120, Moves=351
Path 17: Health=115, Moves=352
Path 15: Health=110, Moves=353
Path 14: Health=105, Moves=354
Path 13: Health=100, Moves=355
Path 12: Health=95, Moves=356
Path 11: Health=90, Moves=357
Path 8: Health=85, Moves=358
Path 7: Health=80, Moves=359
Path 6: Health=75, Moves=360
Path 5: Health=70, Moves=361
Path 4: Health=65, Moves=362
Path 3: Health=60, Moves=363
Path 2: Health=55, Moves=364
Path 1: Health=50, Moves=365
Path 9: Health=45, Moves=366
Path 10: Health=40, Moves=367
Path 16: Health=35, Moves=368
Path 18: Health=30, Moves=369
Path 19: Health=25, Moves=370
Path 23: Health=20, Moves=371
Path 24: Health=15, Moves=372
Path 25: Health=10, Moves=373
Path 26: Health=5, Moves=374
```
