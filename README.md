# checkers_zynq
Checkers implemented in VHDL and C

## Rules 
ENGLISH Checkers - https://www.fmjd.org/?p=v-ch
Test game - https://www.247checkers.com/

## Done
- Full Game logic
- VGA display
- Move and capture logic
- Kings
- King display
- Bigger board
- Main meny to choose AI or PvP

## TODO
- We don't implement mandatory capture yet. The rulebook says that we have to capture the piece, but we don'tt have it for State 2. It is optional to add this feature
-  AI is optional. If you don't wanna do it, make sure to change Main Menu accordingly
    - For AI you can push legal moves array to C, so that it can randomly choose legal move
