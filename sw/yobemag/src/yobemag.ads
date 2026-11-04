--  Yobemag: the carrier, as one package an application withs next to Board
--  (the Mercury 2 module, from the mercury2 crate).
--
--     with Board;     --  console, the module's LEDs
--     with Yobemag;   --  LCD, gamepad, speaker, backlight
--
--  Initialize does everything in the right order and stops with a message
--  when the loaded bitstream is not yobemag's.

with ST7796;
with Gamepad;
with PWM_Out;

package Yobemag is

   package LCD renames ST7796;
   package Pad renames Gamepad;

   procedure Initialize;
   --  1. Board.Initialize (console, LEDs, NEORV32 version check)
   --  2. checks the LCD bridge ID: on a mismatch prints a message and
   --     stops there, blinking the module's LEDs, like a version mismatch
   --  3. PWM on, backlight to Backlight_Default
   --  4. gamepad inputs configured
   --  5. LCD reset and init sequence (about 300 ms), screen black

   Backlight_Default : constant PWM_Out.Percent := 80;

   procedure Set_Backlight (Level : PWM_Out.Percent);

   procedure Beep (Hz : Positive; Seconds : Duration);
   --  Blocking tone on the speaker.

   procedure Tone_On (Hz : Positive);
   procedure Tone_Off;

end Yobemag;
