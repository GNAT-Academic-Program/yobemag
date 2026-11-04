# yobemag carrier board

The carrier is a PCB the Mercury 2 module plugs into (its 64-pin DIP footprint), carrying the display, the buttons and the speaker. The KiCad project goes in this folder. Nothing is drawn yet; this file is the pin plan and the constraints the layout has to respect.

## What goes on it

| Part | Connection to the module |
| --- | --- |
| 3.5" 320x480 ST7796 IPS module, "IPS MCU 16Bit No TP" variant (16-bit 8080, 2.54 mm header) | IO 0 .. IO 21 |
| 8 tactile buttons: Up, Down, Left, Right, A, B, Start, Select | IO 22 .. IO 29, each to GND when pressed |
| speaker | IO 30, through a transistor or a small amplifier |
| power: 5 V in, 3.3 V for the display logic | from the module or its own regulator |

The exact FPGA pin for each IO number is in `vivado/mercury2/carrier.xdc`. That file is the single source of truth for the pin plan; the schematic must match it.

## Big constraints, in plain words

1. **All 31 carrier signals go through the module's level shifters** (the 40 "IO" pins are the 5 V tolerant ones). These are not plain FPGA pins. Before the layout, read the level shifter section of the Mercury 2 reference manual for the part used, its drive strength and its speed. The two consequences we already know: do not put strong external pull-ups on the buttons (the FPGA's internal pull-ups are enabled in the XDC and are enough), and keep the LCD bus short.
2. **An FPGA pin cannot drive a speaker.** Even through the level shifter the current is a few mA. The speaker needs a transistor (a single NPN or a small MOSFET with a flyback diode is enough for a piezo or a small dynamic speaker) or a class-D amplifier module. The PWM is a square wave; a simple RC low-pass before the amplifier softens it.
3. **The LCD backlight draws more than a logic pin gives.** The module's backlight LEDs take tens of mA. The `lcd_bl_o` PWM must drive a transistor that switches the backlight supply, not the LEDs directly.
4. **The display runs on 3.3 V logic.** Check the module's own regulator and the IM (interface mode) pins: the "16Bit" variant is already strapped for the 16-bit 8080 bus, but confirm on the actual module before soldering.
5. **DIP pin numbers are not IO numbers.** The XDC lists FPGA pins and the IO index from the LiteX platform file. The carrier's footprint needs the DIP pin number for each IO, which is only in the Mercury 2 reference manual. Build that table first, check it twice.

## Free pins

IO 31 .. IO 39 and DIO 1 .. DIO 9 are unused. DIO 0 is the module's reset: a button to GND on it is a nice addition, it restarts the bootloader.
