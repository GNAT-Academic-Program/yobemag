with Gpio;
with Gpio_Types;
with MT;
with Yobemag_GPIO;

package body Gamepad is

   use type MT.Bit;

   Pins : constant array (Button) of Gpio.Pin :=
     (Up    => Yobemag_GPIO.Btn_Up,
      Down  => Yobemag_GPIO.Btn_Down,
      Left  => Yobemag_GPIO.Btn_Left,
      Right => Yobemag_GPIO.Btn_Right,
      A     => Yobemag_GPIO.Btn_A,
      B     => Yobemag_GPIO.Btn_B,
      Start => Yobemag_GPIO.Btn_Start,
      Sel   => Yobemag_GPIO.Btn_Select);

   procedure Initialize is
      Cfg : constant Gpio_Types.Gpio_Config :=
        (Mode => Gpio_Types.Input, Pull => Gpio_Types.None);
      --  Pull is None on purpose: the pull-ups are in the FPGA constraints
      --  (carrier.xdc), not in the SoC. Asking the SoC for one raises.
   begin
      for Btn in Button loop
         Gpio.Configure (Pins (Btn), Cfg);
      end loop;
   end Initialize;

   function Pressed (Btn : Button) return Boolean is
     (Gpio.Read (Pins (Btn)) = 1);
   --  The gateware inverts the pins: 1 means pressed.

   function State return Button_State is
      S : Button_State;
   begin
      for Btn in Button loop
         S (Btn) := Pressed (Btn);
      end loop;
      return S;
   end State;

end Gamepad;
