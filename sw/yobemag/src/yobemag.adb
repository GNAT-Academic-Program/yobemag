with Board;
with Gpio;
with Debug;
with LCD_Bridge;
with Yobemag_GPIO;
with Interfaces;

package body Yobemag is

   use type Interfaces.Unsigned_32;

   procedure Halt_On_Wrong_Bitstream (Seen : Interfaces.Unsigned_32) is
   begin
      Debug.Put_Line ("yobemag bitstream not found");
      Debug.Put_Line ("  LCD bridge ID read  0x" & Debug.Hex (Natural (Seen and 16#7FFF_FFFF#)));
      Debug.Put_Line ("  expected            0x" & Debug.Hex (Natural (LCD_Bridge.Expected_ID and 16#7FFF_FFFF#)));
      Debug.Put_Line ("Load yobemag_mercury2_<variant>.bit, not the plain neorv32_mercury2 one.");
      loop
         Gpio.Toggle (Board.Led_Blue);
         Gpio.Toggle (Board.Led_Green);
         Gpio.Toggle (Board.Led_Orange);
         delay 0.1;
      end loop;
   end Halt_On_Wrong_Bitstream;

   procedure Initialize is
      Seen : Interfaces.Unsigned_32;
   begin
      Board.Initialize;

      --  On the plain bitstream this read traps (bus error) before it
      --  returns: the console shows a trap from Last_Chance_Handler, which
      --  is also a clear enough answer.
      Seen := LCD_Bridge.ID;
      if Seen /= LCD_Bridge.Expected_ID then
         Halt_On_Wrong_Bitstream (Seen);
      end if;

      PWM_Out.Initialize;
      Set_Backlight (Backlight_Default);

      Gamepad.Initialize;

      ST7796.Initialize;
      ST7796.Fill_Screen (ST7796.Black);

      Debug.Put_Line ("yobemag ready");
   end Initialize;

   procedure Set_Backlight (Level : PWM_Out.Percent) is
   begin
      PWM_Out.Set_Level (Yobemag_GPIO.Backlight_Channel, Level);
   end Set_Backlight;

   procedure Tone_On (Hz : Positive) is
   begin
      PWM_Out.Set_Tone (Yobemag_GPIO.Speaker_Channel, Hz);
   end Tone_On;

   procedure Tone_Off is
   begin
      PWM_Out.Off (Yobemag_GPIO.Speaker_Channel);
   end Tone_Off;

   procedure Beep (Hz : Positive; Seconds : Duration) is
   begin
      Tone_On (Hz);
      delay Seconds;
      Tone_Off;
   end Beep;

end Yobemag;
