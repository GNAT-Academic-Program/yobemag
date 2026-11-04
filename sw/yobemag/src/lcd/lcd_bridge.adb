with System;

package body LCD_Bridge is

   use Interfaces;

   --  Register map of lcd_8080_xbus, word offsets from Base.
   type Registers is record
      CTRL : Unsigned_32;   --  bit 0: reset asserted, bit 1: chip selected
      CMD  : Unsigned_32;   --  write only
      DATA : Unsigned_32;   --  write only
      ID   : Unsigned_32;   --  read only
   end record
     with Volatile;

   for Registers use record
      CTRL at 16#0# range 0 .. 31;
      CMD  at 16#4# range 0 .. 31;
      DATA at 16#8# range 0 .. 31;
      ID   at 16#C# range 0 .. 31;
   end record;

   Regs : Registers
     with Import, Address => System'To_Address (Base);

   --  Software copy of CTRL, so Set_Reset does not disturb chip select and
   --  vice versa without a bus read each time.
   Ctrl_Shadow : Unsigned_32 := 0;

   Reset_Bit  : constant Unsigned_32 := 1;
   Select_Bit : constant Unsigned_32 := 2;

   function ID return Unsigned_32 is (Regs.ID);

   procedure Set_Reset (Asserted : Boolean) is
   begin
      if Asserted then
         Ctrl_Shadow := Ctrl_Shadow or Reset_Bit;
      else
         Ctrl_Shadow := Ctrl_Shadow and not Reset_Bit;
      end if;
      Regs.CTRL := Ctrl_Shadow;
   end Set_Reset;

   procedure Set_Chip_Select (Selected : Boolean) is
   begin
      if Selected then
         Ctrl_Shadow := Ctrl_Shadow or Select_Bit;
      else
         Ctrl_Shadow := Ctrl_Shadow and not Select_Bit;
      end if;
      Regs.CTRL := Ctrl_Shadow;
   end Set_Chip_Select;

   procedure Write_Command (Cmd : Unsigned_8) is
   begin
      Regs.CMD := Unsigned_32 (Cmd);
   end Write_Command;

   procedure Write_Data (Data : Unsigned_16) is
   begin
      Regs.DATA := Unsigned_32 (Data);
   end Write_Data;

end LCD_Bridge;
