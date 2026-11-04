with NEORV32;
with NEORV32.PWM;
with NEORV32_System;

package body PWM_Out is

   use NEORV32;
   use NEORV32.PWM;

   --  Prescaler select 2 = clock / 8 (neorv32_package: clk_div8_c).
   Prescaler_Select : constant UInt32 := 2;
   Prescaler        : constant := 8;

   function Mask (Ch : Channel) return UInt32 is
     (Shift_Left (UInt32'(1), Ch));

   procedure Initialize is
   begin
      PWM_Periph.ENABLE   := 0;
      PWM_Periph.POLARITY := 0;     --  high while counter < CMP
      PWM_Periph.MODE     := 0;     --  fast PWM: count 0 .. TOP, wrap
      PWM_Periph.CLKPRSC  := Prescaler_Select;
   end Initialize;

   procedure Set_Duty (Ch : Channel; Period_Ticks : Positive; High_Ticks : Natural) is
   begin
      --  The counter runs 0 .. TOP inclusive: TOP = period - 1. The output
      --  is high while counter < CMP, so CMP = High_Ticks gives High_Ticks
      --  high ticks out of Period_Ticks.
      PWM_Periph.CHANNEL (Ch).TOPCMP :=
        (TOP => UInt16 (Period_Ticks - 1), CMP => UInt16 (High_Ticks));
      PWM_Periph.ENABLE := PWM_Periph.ENABLE or Mask (Ch);
   end Set_Duty;

   procedure Set_Level (Ch : Channel; Level : Percent) is
   begin
      Set_Duty (Ch, 256, (256 * Level) / 100);
   end Set_Level;

   procedure Set_Tone (Ch : Channel; Hz : Positive) is
      Period : constant Positive :=
        Positive'Max (2, NEORV32_System.Clock_Hz / Prescaler / Hz);
   begin
      Set_Duty (Ch, Positive'Min (Period, 65536), Positive'Min (Period, 65536) / 2);
   end Set_Tone;

   procedure Off (Ch : Channel) is
   begin
      PWM_Periph.ENABLE := PWM_Periph.ENABLE and not Mask (Ch);
   end Off;

end PWM_Out;
