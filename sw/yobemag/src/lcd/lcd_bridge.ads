--  LCD_Bridge: the register interface of lcd_8080_xbus (rtl/lcd_8080_xbus.vhd),
--  the gateware block that turns a bus write into one 16-bit 8080 write cycle.
--  This is the lowest software layer of the display: no knowledge of the
--  panel, only of the bridge. ST7796 sits on top of it.
--
--  Every Write_Command / Write_Data blocks the CPU for the duration of one
--  8080 cycle (a few clock cycles) and returns when the panel has latched
--  the word. There is nothing to wait for afterwards.

with Interfaces;

package LCD_Bridge is

   Base : constant := 16#9000_0000#;

   Expected_ID : constant Interfaces.Unsigned_32 := 16#594F_4245#;  --  "YOBE"

   function ID return Interfaces.Unsigned_32;
   --  Reads the bridge's ID register. Equal to Expected_ID when the loaded
   --  bitstream is yobemag's. On the plain neorv32_mercury2 bitstream this
   --  address is not implemented and the read traps with a bus error,
   --  which ends in Last_Chance_Handler: the console then shows a trap,
   --  not a value. Either way the program does not run on with a wrong
   --  bitstream.

   procedure Set_Reset (Asserted : Boolean);
   --  Drives the panel's reset line. True holds the panel in reset.

   procedure Set_Chip_Select (Selected : Boolean);
   --  Drives the panel's chip select. The panel ignores the bus until selected.

   procedure Write_Command (Cmd : Interfaces.Unsigned_8);
   --  One 8080 write with DC = 0. The command byte goes on DB (7 downto 0).

   procedure Write_Data (Data : Interfaces.Unsigned_16);
   --  One 8080 write with DC = 1. For pixel data this is one RGB565 pixel.

end LCD_Bridge;
