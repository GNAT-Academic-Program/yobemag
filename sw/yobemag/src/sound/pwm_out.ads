--  PWM_Out: the SoC's PWM peripheral, for the speaker and the backlight.
--
--  neorv32_ghal has no PWM driver yet (that is the runtime team's work);
--  this is the small amount of it yobemag needs, written against the SVD
--  registers. When neorv32_ghal gains a PWM driver, this package should go
--  and the callers move to it.
--
--  The peripheral has one clock prescaler for all channels. It is set to
--  clock / 8 here: at 50 MHz, tones from 96 Hz up, and a 24 kHz backlight
--  PWM, which is above hearing.

package PWM_Out is

   subtype Channel is Natural range 0 .. 31;

   subtype Percent is Natural range 0 .. 100;

   procedure Initialize;
   --  Sets the prescaler and leaves every channel off.

   procedure Set_Duty (Ch : Channel; Period_Ticks : Positive; High_Ticks : Natural)
     with Pre => Period_Ticks <= 65536 and High_Ticks <= Period_Ticks;
   --  Period_Ticks ticks of the prescaled clock per period, High_Ticks of
   --  them high. The channel is enabled.

   procedure Set_Level (Ch : Channel; Level : Percent);
   --  A fixed 256-tick period with Level percent high: brightness, not pitch.

   procedure Set_Tone (Ch : Channel; Hz : Positive)
     with Pre => Hz >= 96;
   --  A square wave at Hz, 50 percent duty.

   procedure Off (Ch : Channel);
   --  Disables the channel; its pin goes low.

end PWM_Out;
