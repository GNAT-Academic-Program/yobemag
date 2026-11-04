--  ST7796: the 3.5" 320x480 IPS panel on the carrier (ST7796S controller,
--  16-bit 8080 bus), driven through LCD_Bridge.
--
--  What is here is the minimum to get a first picture: reset, the init
--  sequence, a window, and filling it with one color. Everything a game
--  needs on top (a frame buffer, blitting, text) is the team's.
--
--  Pixels are RGB565: 5 bits red, 6 bits green, 5 bits blue, one 16-bit
--  word per pixel, written with one 8080 cycle each.
--
--  First thing to check on real hardware, in this order:
--    1. the panel shows anything at all after Fill_Screen (if not, see
--       Param_Shift in the body: command parameters may belong on the
--       high byte of the bus on your module);
--    2. colors are right (if red and blue are swapped, flip the BGR bit of
--       MADCTL; if the image is inverted, change Inverted in the body);
--    3. orientation (the other MADCTL bits).

with Interfaces;

package ST7796 is

   Width  : constant := 320;
   Height : constant := 480;

   subtype X_Coord is Natural range 0 .. Width - 1;
   subtype Y_Coord is Natural range 0 .. Height - 1;

   subtype Color is Interfaces.Unsigned_16;

   function RGB (R, G, B : Natural) return Color
     with Pre => R < 256 and G < 256 and B < 256;
   --  Packs 8-bit components into RGB565.

   Black : constant Color := 16#0000#;
   White : constant Color := 16#FFFF#;
   Red   : constant Color := 16#F800#;
   Green : constant Color := 16#07E0#;
   Blue  : constant Color := 16#001F#;

   procedure Initialize;
   --  Hardware reset, then the init sequence, then display on. Takes about
   --  300 ms, most of it the delays the controller requires after reset
   --  and sleep-out.

   procedure Set_Window (X0 : X_Coord; Y0 : Y_Coord; X1 : X_Coord; Y1 : Y_Coord)
     with Pre => X0 <= X1 and Y0 <= Y1;
   --  Selects the rectangle the next pixel writes fill, left to right,
   --  top to bottom, and starts a memory write.

   procedure Write_Pixels (C : Color; Count : Positive);
   --  Writes Count pixels of one color into the current window.

   procedure Fill_Rect (X0 : X_Coord; Y0 : Y_Coord; X1 : X_Coord; Y1 : Y_Coord; C : Color)
     with Pre => X0 <= X1 and Y0 <= Y1;

   procedure Fill_Screen (C : Color);

   procedure Put_Pixel (X : X_Coord; Y : Y_Coord; C : Color);
   --  One pixel. Costs a window set per pixel: fine for a few, not for a frame.

end ST7796;
