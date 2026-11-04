with LCD_Bridge;

package body ST7796 is

   use Interfaces;

   --  Command parameters are 8-bit values. On a 16-bit bus the controller
   --  reads them from one byte of the bus; which one depends on how the
   --  module wires its interface mode pins. 0 puts the parameter on
   --  DB (7 downto 0), 8 on DB (15 downto 8). Change this one constant if
   --  the panel stays blank.
   Param_Shift : constant := 0;

   --  Most IPS modules with this controller need display inversion on to
   --  show colors right. If the picture is a negative, flip this.
   Inverted : constant Boolean := True;

   --  MADCTL: memory access control. Bit 3 is BGR order, bits 7 .. 5 are
   --  row/column swap and mirror. 16#48# is portrait, BGR, on the common
   --  3.5" modules. Tune when the picture is mirrored or colors are swapped.
   MADCTL_Value : constant Unsigned_8 := 16#48#;

   --  ST7796S commands used here.
   SWRESET : constant Unsigned_8 := 16#01#;
   SLPOUT  : constant Unsigned_8 := 16#11#;
   INVOFF  : constant Unsigned_8 := 16#20#;
   INVON   : constant Unsigned_8 := 16#21#;
   DISPON  : constant Unsigned_8 := 16#29#;
   CASET   : constant Unsigned_8 := 16#2A#;
   RASET   : constant Unsigned_8 := 16#2B#;
   RAMWR   : constant Unsigned_8 := 16#2C#;
   MADCTL  : constant Unsigned_8 := 16#36#;
   COLMOD  : constant Unsigned_8 := 16#3A#;

   procedure Cmd (C : Unsigned_8) renames LCD_Bridge.Write_Command;

   procedure Param (P : Unsigned_8) is
   begin
      LCD_Bridge.Write_Data (Shift_Left (Unsigned_16 (P), Param_Shift));
   end Param;

   procedure Param_16 (V : Unsigned_16) is
   begin
      Param (Unsigned_8 (Shift_Right (V, 8)));
      Param (Unsigned_8 (V and 16#FF#));
   end Param_16;

   function RGB (R, G, B : Natural) return Color is
     (Shift_Left (Unsigned_16 (R / 8), 11)
      or Shift_Left (Unsigned_16 (G / 4), 5)
      or Unsigned_16 (B / 8));

   procedure Initialize is
   begin
      --  Hardware reset: the controller wants reset low for at least 10 us
      --  and 120 ms before it accepts commands after release.
      LCD_Bridge.Set_Chip_Select (True);
      LCD_Bridge.Set_Reset (True);
      delay 0.010;
      LCD_Bridge.Set_Reset (False);
      delay 0.120;

      Cmd (SWRESET);
      delay 0.120;

      Cmd (SLPOUT);
      delay 0.120;

      Cmd (COLMOD);
      Param (16#55#);          --  16 bits per pixel, RGB565

      Cmd (MADCTL);
      Param (MADCTL_Value);

      Cmd (if Inverted then INVON else INVOFF);

      Cmd (DISPON);
      delay 0.020;
   end Initialize;

   procedure Set_Window (X0 : X_Coord; Y0 : Y_Coord; X1 : X_Coord; Y1 : Y_Coord) is
   begin
      Cmd (CASET);
      Param_16 (Unsigned_16 (X0));
      Param_16 (Unsigned_16 (X1));
      Cmd (RASET);
      Param_16 (Unsigned_16 (Y0));
      Param_16 (Unsigned_16 (Y1));
      Cmd (RAMWR);
   end Set_Window;

   procedure Write_Pixels (C : Color; Count : Positive) is
   begin
      for I in 1 .. Count loop
         LCD_Bridge.Write_Data (C);
      end loop;
   end Write_Pixels;

   procedure Fill_Rect (X0 : X_Coord; Y0 : Y_Coord; X1 : X_Coord; Y1 : Y_Coord; C : Color) is
   begin
      Set_Window (X0, Y0, X1, Y1);
      Write_Pixels (C, (X1 - X0 + 1) * (Y1 - Y0 + 1));
   end Fill_Rect;

   procedure Fill_Screen (C : Color) is
   begin
      Fill_Rect (0, 0, Width - 1, Height - 1, C);
   end Fill_Screen;

   procedure Put_Pixel (X : X_Coord; Y : Y_Coord; C : Color) is
   begin
      Set_Window (X, Y, X, Y);
      LCD_Bridge.Write_Data (C);
   end Put_Pixel;

end ST7796;
