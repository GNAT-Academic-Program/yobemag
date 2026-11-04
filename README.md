# yobemag

A handheld game platform on the MicroNova Mercury 2 (Artix-7): the GAP NEORV32 SoC, a carrier board with a 3.5" LCD, eight buttons and a speaker, and Ada firmware on top.

This repo is the seed. It has the whole chain working end to end, small: the bitstream builds and simulates, the firmware builds, and the examples fill the screen, read the buttons and beep. What makes it a game console is the team's work.

## How the repo is put together

```text
boards/neorv32_mercury2/   git submodule: the board SoC (NEORV32 pinned to v1.13.6), its Vivado helpers, flash and console scripts
rtl/lcd_8080_xbus.vhd      the one piece of gateware yobemag adds: an XBUS slave that does 16-bit 8080 writes to the LCD
rtl/top_mercury2.vhd       the composition: board SoC + bridge, buttons on GPIO, speaker and backlight on PWM
vivado/mercury2/           create_project.tcl (calls the submodule's board.tcl) and carrier.xdc (the carrier's pins)
sim/                       GHDL: bridge unit test, boot smoke test of the composed top
sw/yobemag/                Alire crate: the carrier's drivers (LCD bridge, ST7796, gamepad, PWM) and the Yobemag package
sw/examples/               Alire crate: lcd_fill, gamepad_echo, beep
hw/carrier/                the carrier PCB: pin plan and constraints now, KiCad project later
upload/                    send a program to the bootloader and watch it run (same scripts as the mercury2 crate)
build.sh, build.bat        bitstream build launchers, Linux and Windows
```

Two things decide the shape:

- **The board is not forked, it is composed.** `boards/neorv32_mercury2` is a submodule pinned to one commit. `rtl/top_mercury2.vhd` instantiates its `neorv32_mercury2_soc` with `XBUS_EN => true` and hangs the LCD bridge on the external bus at `0x90000000`. Buttons and PWM need no RTL: the SoC's own GPIO and PWM are grown with the `GPIO_NUM` and `PWM_NUM` generics. A change needed in the SoC itself goes to the board repo, then the submodule pin is bumped here.
- **The firmware is two crates on the existing chain.** `sw/yobemag` depends on the `mercury2` board crate (console, LEDs, NEORV32 version check) and the `neorv32` MCU crate, both pinned by GitHub URL. An application withs `Board` for the module and `Yobemag` for the carrier.

## Get the sources

```sh
git clone --recurse-submodules https://github.com/GNAT-Academic-Program/yobemag.git
```

If it was cloned without `--recurse-submodules`:

```sh
git submodule update --init --recursive
```

Both the build script and the simulation stop with that command when the submodule is empty.

## The gateware

Prerequisites: Vivado (the free edition covers both Mercury 2 sizes). It does not need to be on `PATH`; see the board repo's README if it is not found.

Run from the root of the repo.

Linux, 100T:

```sh
./build.sh 100t
```

Linux, 35T:

```sh
./build.sh 35t
```

Windows, 100T:

```bat
build.bat 100t
```

Windows, 35T:

```bat
build.bat 35t
```

Output: `vivado/mercury2/yobemag_mercury2_<variant>.bit`. Flash it with the board repo's script, from the root of this repo. Linux:

```sh
sh boards/neorv32_mercury2/flash/flash.sh vivado/mercury2/yobemag_mercury2_35t.bit
```

Windows:

```bat
.\boards\neorv32_mercury2\flash\flash.bat vivado\mercury2\yobemag_mercury2_35t.bit
```

For a 100T board, use the `_100t.bit` file. The serial console is the board repo's too: `bash boards/neorv32_mercury2/console/console.sh` on Linux, `.\boards\neorv32_mercury2\console\console.bat` on Windows.

### What the bitstream contains

The SoC is the board's, unchanged (50 MHz, rv32imac, 128 KB IMEM, 64 KB DMEM, UART bootloader at 19200 8N1), plus:

| Carrier part | How the CPU sees it |
| --- | --- |
| LCD, 16-bit 8080 | `lcd_8080_xbus` at `0x90000000`: `CTRL` (reset, chip select), `CMD`, `DATA`, `ID` |
| 8 buttons | GPIO inputs 3 .. 10, read 1 while pressed (the gateware inverts the pulled-up pins) |
| speaker | PWM channel 0 |
| LCD backlight | PWM channel 1 |
| the module's 3 LEDs | GPIO outputs 0 .. 2, as before |

The bridge blocks the bus for one 8080 write cycle per word written to `CMD` or `DATA` (about 4 clock cycles), so a pixel write is one store instruction and nothing to poll. Its `ID` register reads `0x594F4245` ("YOBE"): the firmware checks it at start and refuses to run on the plain bitstream. The register map is at the top of `rtl/lcd_8080_xbus.vhd`.

### Simulation

GHDL on Linux (WSL on Windows). The bridge test takes a second, the boot test about three minutes:

```sh
./sim/run.sh
```

Bridge test only:

```sh
./sim/run.sh quick
```

CI runs both, and builds the examples.

## The firmware

Prerequisites: Alire, and `alr toolchain --select gnat_riscv64_elf` done once.

```sh
cd sw/examples
alr build
```

Produces `sw/examples/bin/lcd_fill`, `gamepad_echo` and `beep`. To run one: reset the board (DIO 0 to GND, or power-cycle) so the bootloader is waiting, then within 8 seconds:

Linux:

```sh
bash upload/upload.sh sw/examples/bin/lcd_fill
```

Windows:

```bat
.\upload\upload.bat sw\examples\bin\lcd_fill
```

Until the carrier exists, the examples still run on a bare Mercury 2 with the yobemag bitstream: the console lines appear and the LED blinks, there is just nothing on the other pins.

### What the crate gives you

| Package | What it is |
| --- | --- |
| `Yobemag` | `Initialize` (board, bitstream check, backlight, buttons, LCD), `Set_Backlight`, `Beep`, `Tone_On`, `Tone_Off`; renames `LCD` and `Pad` |
| `ST7796` | the panel: `Initialize`, `Set_Window`, `Write_Pixels`, `Fill_Rect`, `Fill_Screen`, `Put_Pixel`, RGB565 colors |
| `LCD_Bridge` | the register interface of the gateware bridge; `ST7796` is built on it |
| `Gamepad` | `Button`, `Pressed`, `State`; no debouncing |
| `PWM_Out` | the SoC's PWM, enough for a tone and a brightness; to be replaced by the neorv32 crate's driver when one exists |
| `Yobemag_GPIO` | which GPIO number and PWM channel is which carrier line |

## First light checklist

The first time the carrier and the panel meet, in this order:

1. `lcd_fill` prints `yobemag ready` on the console. If it prints `yobemag bitstream not found`, the plain bitstream is loaded. If the console shows a trap, same cause.
2. The backlight comes on. If not, the backlight transistor circuit (see `hw/carrier/README.md`).
3. The screen cycles red, green, blue, white. If it stays blank, change `Param_Shift` in `sw/yobemag/src/lcd/st7796.adb` (command parameters may belong on the high byte of the bus on your module). If colors are negatives, flip `Inverted` there. If red and blue are swapped or the picture is mirrored, `MADCTL_Value`.
4. `gamepad_echo` prints each button as it is pressed and released.
5. `beep` plays a scale. A square wave through a bare piezo is quiet; see the speaker note in `hw/carrier/README.md`.

## What is yours

In the order it will probably happen:

- the carrier board (`hw/carrier/README.md` has the plan and the constraints)
- a frame buffer and a way to push it to the panel fast enough for a game. 320x480 at 16 bits is 300 KB, more than the SoC's 64 KB DMEM: tiles, a smaller viewport, or a line buffer. Measure the 8080 write rate first (one store per pixel; the bridge's `WR_LOW` / `WR_HIGH` generics are the knob)
- when the CPU is the bottleneck, a DMA fill or blit engine next to the bridge, as a second XBUS slave (the bridge decodes one 16-byte window; a second slave gets its own)
- debounced, edge-detected input (`Gamepad` only reads levels)
- sound beyond a square wave (the PWM is already there; a second channel or a sample player)
- a game

Keep the seams: `LCD_Bridge` knows only the bridge, `ST7796` knows only the panel, the game knows neither.

## License

MIT. The board submodule is BSD-3-Clause, matching NEORV32.
