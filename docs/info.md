<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Desert Dash is an endless runner, written in TL-Verilog in Makerchip from tt-makerchip-template (with its `vga` and
`gamepad` settings). A critter runs along the ground as cacti scroll toward it; jump them. The score counts up,
and the game speeds up every 200 points. Touching a cactus ends the game.

It draws a 640x480 VGA picture at 60 Hz, one pixel per clock cycle (25.175 MHz). The game state changes once per
frame; each pixel's color comes from the beam position, the 8x8 sprites (drawn 4x), and a 3x5 font for the score.
A crash is detected as a runner pixel drawn over a cactus pixel.

## How to test

Connect a VGA monitor (through the Tiny VGA Pmod) and the Gamepad Pmod, then release reset. Press A, B or up to
jump. After a crash, press A or start to play again.

In VGA Playground, enable the gamepad and use the arrow keys and the `a`, `b` and `t` (start) keys.

## External hardware

- [Tiny VGA Pmod](https://github.com/mole99/tiny-vga) on the outputs.
- [Gamepad Pmod](https://github.com/psychogenic/gamepad-pmod) on the inputs.
